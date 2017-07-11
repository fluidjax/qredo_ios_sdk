/* HEADER GOES HERE */
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"

#import "QredoRendezvousCrypto.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoLoggerPrivate.h"
#import "rsapss.h"

#import "NSData+ParseHex.h"
#import "NSData+Conversion.h"

#import <openssl/bn.h>
#import <openssl/rand.h>
#import <Security/SecRandom.h>

#import "MasterConfig.h"

@implementation QredoCrypto





#define PBKDF2_MIN_SALT_LENGTH       8 //RFC recommends minimum of 8 bytes salt

/*
 OAEP padding adds minimum 2+(2*hash_size) bytes padding.
 Default OAEP uses SHA1, which is 20byte hash output.
 Therefore minimum padding is 42 bytes. Could be longer if
 we later specify a different OAEP MGF1 digest algorithm
 */





+(NSData *)encryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv {
    GUARD(data,@"Input argument is nil.");
    GUARD(key,@"Key argument is nil");
    GUARDF(key.length == kCCKeySizeAES256,@"Key must be %d bytes.", kCCKeySizeAES256);
    GUARDF((iv && iv.length == kCCBlockSizeAES128), @"IV must be %d bytes.", kCCBlockSizeAES128);
    
    CCCryptorRef cryptor = NULL;
    NSMutableData *cipherData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    NSMutableData *ivMutable =  [iv mutableCopy];

    CCCryptorStatus  create = CCCryptorCreateWithMode(kCCEncrypt,
                                                      kCCModeCTR,
                                                      kCCAlgorithmAES,
                                                      ccPKCS7Padding,
                                                      ivMutable.bytes,
                                                      key.bytes,
                                                      key.length,
                                                      NULL,
                                                      0,
                                                      0,
                                                      kCCModeOptionCTR_BE,
                                                      &cryptor);
    
    AESGUARD((create == kCCSuccess), @"AES Encrypt failed (1) CCCryptorCreateWithMode");
    
    size_t outLength;
    CCCryptorStatus  update = CCCryptorUpdate(cryptor,
                                              data.bytes,
                                              data.length,
                                              cipherData.mutableBytes,
                                              cipherData.length,
                                              &outLength);
    
    AESGUARD((update == kCCSuccess), @"AES Encrypt failed (2) CCCryptorUpdate");
    
    cipherData.length = outLength;
    CCCryptorStatus final = CCCryptorFinal(cryptor,
                                           cipherData.mutableBytes,
                                           cipherData.length,
                                           &outLength);
    
    AESGUARD((final == kCCSuccess), @"AES Encrypt failed (3) CCCryptorFinal");
    
    CCCryptorRelease(cryptor );
    return cipherData;
}


+(NSData *)decryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv {
    GUARD(data,@"Input argument is nil.");
    GUARD(key,@"Key argument is nil");
    GUARDF(key.length == kCCKeySizeAES256,@"Key must be %d bytes.", kCCKeySizeAES256);
    GUARDF((iv && iv.length == kCCBlockSizeAES128), @"IV must be %d bytes.", kCCBlockSizeAES128);

    CCCryptorRef cryptor = NULL;
    NSMutableData *ivMutable =  [iv mutableCopy];
    
    CCCryptorStatus createDecrypt = CCCryptorCreateWithMode(kCCDecrypt,
                                                            kCCModeCTR,
                                                            kCCAlgorithmAES,
                                                            ccPKCS7Padding,
                                                            ivMutable.bytes,
                                                            key.bytes,
                                                            key.length,
                                                            NULL,
                                                            0,
                                                            0,
                                                            kCCModeOptionCTR_BE,
                                                            &cryptor);
    AESGUARD((createDecrypt == kCCSuccess), @"AES Decrypt failed (1) CCCryptorCreateWithMode");
    
    NSMutableData *cipherDataDecrypt = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    size_t outLengthDecrypt;
    CCCryptorStatus updateDecrypt = CCCryptorUpdate(cryptor,
                                                    data.bytes,
                                                    data.length,
                                                    cipherDataDecrypt.mutableBytes,
                                                    cipherDataDecrypt.length,
                                                    &outLengthDecrypt);
    AESGUARD((updateDecrypt == kCCSuccess), @"AES Decrypt failed (2) CCCryptorUpdate");

    cipherDataDecrypt.length = outLengthDecrypt;
    CCCryptorStatus final = CCCryptorFinal(cryptor,
                                           cipherDataDecrypt.mutableBytes,
                                           cipherDataDecrypt.length,
                                           &outLengthDecrypt);
    
    AESGUARD((final == kCCSuccess), @"AES Decrypt failed (3) CCCryptorFinal");
    CCCryptorRelease(cryptor);
    return cipherDataDecrypt;
}


+(NSData *)hkdfExtractSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm {

    GUARD(ikm, @"IKM must be specified.")
    
    // HKDF-Extract gets a pseudo random key (PRK) from the initial key material (IKM)
    // PRK = HMAC-Hash(salt, IKM)
    NSMutableData *prk = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    
    // HKDF-Extract
    CCHmac(kCCHmacAlgSHA256, salt.bytes, salt.length, ikm.bytes, ikm.length, prk.mutableBytes);
    
    return prk;
}


+(NSData *)hkdfExpandSha256WithKey:(NSData *)key info:(NSData *)info outputLength:(NSUInteger)outputLength {
    //based on the required output Length calucate the number of iterations required
    int iterations = (int)ceil((double)outputLength / (double)CC_SHA256_DIGEST_LENGTH);
    NSData *mixin = [NSData data];
    
    NSMutableData *results = [NSMutableData data];
    
    
    for (int i = 0; i < iterations; i++){
        CCHmacContext ctx;
        CCHmacInit(&ctx,kCCHmacAlgSHA256,[key bytes],[key length]);
        CCHmacUpdate(&ctx,[mixin bytes],[mixin length]);
        
        if (info != nil){
            CCHmacUpdate(&ctx,[info bytes],[info length]);
        }
        
        unsigned char c = i + 1;
        CCHmacUpdate(&ctx,&c,1);
        unsigned char T[CC_SHA256_DIGEST_LENGTH];
        CCHmacFinal(&ctx,T);
        NSData *stepResult = [NSData dataWithBytes:T length:CC_SHA256_DIGEST_LENGTH];
        [results appendData:stepResult];
        mixin = [stepResult copy];
    }
    //from the result only return the required length, discarding anything above
    return [[NSData dataWithData:results] subdataWithRange:NSMakeRange(0,outputLength)];
}


+(NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info {
    //Convenience wrapper to provide 256bit output keys
    return [self hkdfSha256WithSalt:salt initialKeyMaterial:ikm info:info outputLength:CC_SHA256_DIGEST_LENGTH];
}


+(NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info outputLength:(NSUInteger)outputLength {
    //Taken from https://tools.ietf.org/html/rfc5869
    // Additional resources https://github.com/FredericJacobs/HKDFKit
    
    //stage 1: From input material generates a psuedo random key
    //         This redistributes unevenly distributed entropy in the source material
    NSData *prk = [QredoCrypto hkdfExtractSha256WithSalt:salt initialKeyMaterial:ikm];
    
    //Stage 2: Exapnds  the key into several additional random keys, concatenates them into a longer key,
    // returns    longerKey.sub(0,requiredKeylength)
    NSData *okm = [QredoCrypto hkdfExpandSha256WithKey:prk info:info outputLength:outputLength];
    
    
    return okm;
}

+(NSData *)pbkdf2Sha256WithSalt:(NSData *)salt passwordData:(NSData *)passwordData requiredKeyLengthBytes:(NSUInteger)requiredKeyLengthBytes iterations:(NSUInteger)iterations {
    
    GUARD(salt,
          @"Salt argument must be specified.");
    
    GUARDF(salt.length >= PBKDF2_MIN_SALT_LENGTH,
           @"Salt length must be at least minimum RFC-recommended value (%d bytes).",
           PBKDF2_MIN_SALT_LENGTH);
    
    GUARD(passwordData,
          @"Password argument must be specified.");
    
    GUARDF(iterations < UINT_MAX,
           @"Iterations value must be lower than max allowed value (%lu).", (unsigned long)iterations);
    
    GUARD(iterations > 0,
          @"Iterations value cannot be zero.");
    
    GUARD(requiredKeyLengthBytes > 0,
          @"Required key length must be a positive integer.");
    
    NSMutableData *derivedKey = [NSMutableData dataWithLength:requiredKeyLengthBytes];
    
    int result = CCKeyDerivationPBKDF(kCCPBKDF2,
                                      passwordData.bytes,
                                      passwordData.length,
                                      salt.bytes,
                                      salt.length,
                                      kCCPRFHmacAlgSHA256,
                                      (uint)iterations,
                                      derivedKey.mutableBytes,
                                      derivedKey.length);
    
    if (result == kCCSuccess){
        return derivedKey;
    } else {
        return nil;
    }
    
}


+(NSData *)generateHmacSha256ForData:(NSData *)data length:(NSUInteger)length key:(NSData *)key {
    
    GUARD(data,
          @"Data argument must be specified.");
    
    GUARDF(length <= data.length,
           @"Length argument (%lu) exceeds data length (%lu)",
           (unsigned long)length, (unsigned long)data.length);
    
    GUARD(key,
          @"Key argument must be specified.");
    
    //Key can be 0 length (it will be zero padded to hash length)
    
    //The MAC size is the same size as the underlying hash function output
    NSMutableData *mac = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,key.bytes,key.length,data.bytes,length,mac.mutableBytes);
    
    return mac;
    
}


+(NSData *)sha256:(NSData *)data {
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(data.bytes,(CC_LONG)data.length,hash.mutableBytes);
    
    return hash;
}


+(NSData *)secureRandomWithSize:(NSUInteger)size {
    size_t randomSize  = size;
    uint8_t *randomBytes = alloca(randomSize);
    int result = SecRandomCopyBytes(kSecRandomDefault,randomSize,randomBytes);
    
    if (result != 0){
        @throw [NSException exceptionWithName:@"QredoSecureRandomGenerationException"
                                       reason:[NSString stringWithFormat:@"Failed to generate a secure random byte array of size %lu (result: %d)..",(unsigned long)size,result]
                                     userInfo:nil];
    }
    
    return [NSData dataWithBytes:randomBytes length:randomSize];
}


+(BOOL)equalsConstantTime:(NSData *)left right:(NSData *)right {
    //This is intended to take a constant amount of time to verify.
    //Combination of example from https://crackstation.net/hashing-security.htm
    //and Qredo's Android CryptoUtil
    
    //TODO: DH - look at replacing with libsodium sodium_memcmp which is constant-time?
    
    //Get the hash of each to ensure always comparing same length data
    NSData *leftHash = [QredoCrypto sha256:left];
    NSData *rightHash = [QredoCrypto sha256:right];
    
    uint8_t *leftHashBytes = (uint8_t *)leftHash.bytes;
    uint8_t *rightHashBytes = (uint8_t *)rightHash.bytes;
    
    //Now use a comparison which always processes each element in constant time
    unsigned long difference = leftHash.length ^ rightHash.length;
    
    for (unsigned long i = 0; i < left.length && i < right.length; i++){
        difference |= leftHashBytes[i] ^ rightHashBytes[i];
    }
    
    return difference == 0;
}





+(QredoSecKeyRefPair *)generateRsaKeyPairOfLength:(NSInteger)lengthBits publicKeyIdentifier:(NSString *)publicKeyIdentifier privateKeyIdentifier:(NSString *)privateKeyIdentifier persistInAppleKeychain:(BOOL)persistKeys {
    /*
     NOTE: Keys which are not persisted in the keychain can only be used via the methods which take a SecKeyRef.
     You cannot find them with SecItemCopyMatching etc as they're not in the keychain, so you cannot get access to
     the generated key data itself, just the ref to the key.
     */
    
    QredoSecKeyRefPair *keyRefPair = nil;
    
    GUARD(lengthBits > 0,
          @"Required key length must be a positive integer.");
    
    GUARD(publicKeyIdentifier,
          @"Public key identifier argument is nil");
    
    GUARD(![publicKeyIdentifier isEqualToString:@""],
          @"Public key identifier must not be empty string.");
    
    GUARD(privateKeyIdentifier,
          @"Private key identifier argument is nil.");
    
    GUARD(![privateKeyIdentifier isEqualToString:@""],
        @"Private key identifier must not be empty string.");
    
    GUARD(![publicKeyIdentifier isEqualToString:privateKeyIdentifier],
          @"Public and Private key identifiers must be different.");
    
    OSStatus status = noErr;
    
    //Allocate dictionaries used for attributes in the SecKeyGeneratePair function
    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
    
    //NSData of the string attributes, used for finding keys easier
    NSData *publicTag = [publicKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    NSData *privateTag = [privateKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    SecKeyRef publicKeyRef = NULL;
    SecKeyRef privateKeyRef = NULL;
    
    //Set key-type and key-size
    keyPairAttr[(__bridge id)kSecAttrKeyType] = (__bridge id)kSecAttrKeyTypeRSA;
    keyPairAttr[(__bridge id)kSecAttrKeySizeInBits] = [NSNumber numberWithInteger:lengthBits];
    
    //Specifies whether private/public key is stored permanently (i.e. in keychain)
    privateKeyAttr[(__bridge id)kSecAttrIsPermanent] = [NSNumber numberWithBool:persistKeys];
    publicKeyAttr[(__bridge id)kSecAttrIsPermanent] = [NSNumber numberWithBool:persistKeys];
    
    //Set the identifier name for private/public key
    privateKeyAttr[(__bridge id)kSecAttrApplicationTag] = privateTag;
    publicKeyAttr[(__bridge id)kSecAttrApplicationTag] = publicTag;
    
    //Sets the private/public key attributes just built up
    keyPairAttr[(__bridge id)kSecPrivateKeyAttrs] = privateKeyAttr;
    keyPairAttr[(__bridge id)kSecPublicKeyAttrs] = publicKeyAttr;
    
    //Generate the keypair
    status = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr,&publicKeyRef,&privateKeyRef);
    
    if (status != errSecSuccess){
        QredoLogError(@"Failed to generate %ld bit keypair. Public key ID: '%@', Private key ID: '%@'. Status: %@",(long)lengthBits,publicKeyIdentifier,privateKeyIdentifier,[QredoLogger stringFromOSStatus:status]);
    } else {
        //This class will CFRelease the SecKeyRef on dealloc
        keyRefPair = [[QredoSecKeyRefPair alloc] initWithPublicKeyRef:publicKeyRef privateKeyRef:privateKeyRef];
    }
    
    return keyRefPair;
}




//TODO: DH - Add unit tests for getPublicKeyRefFromEvaluatedTrustRef
+(SecKeyRef)getPublicKeyRefFromEvaluatedTrustRef:(SecTrustRef)trustRef {

    GUARD(trustRef,
          @"Trust ref argument is nil");
    
    SecKeyRef publicKeyRef = SecTrustCopyPublicKey(trustRef);
    
    if (!publicKeyRef){
        QredoLogError(@"SecTrustCopyPublicKey returned nil ref.");
    }
    
    return publicKeyRef;
}


+(SecKeyRef)getRsaSecKeyReferenceForIdentifier:(NSString *)keyIdentifier {
    
    GUARD(keyIdentifier,
          @"Key identifier argument is nil");
    
    NSMutableDictionary *queryKey = [[NSMutableDictionary alloc] init];
    
    NSData *tag = [keyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    //Set the key query dictionary.
    queryKey[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    queryKey[(__bridge id)kSecAttrApplicationTag] = tag;
    queryKey[(__bridge id)kSecAttrKeyType] = (__bridge id)kSecAttrKeyTypeRSA;
    queryKey[(__bridge id)kSecReturnRef] = (__bridge id)kCFBooleanTrue;
    
    //Get the key reference.
    SecKeyRef secKeyRef;
    
    OSStatus status = fixedSecItemCopyMatching((__bridge CFDictionaryRef)queryKey,(CFTypeRef *)&secKeyRef);
    
    if (status != errSecSuccess){
        if (status == errSecItemNotFound){
            @throw [NSException exceptionWithName:@"QredoKeyIdentifierNotFound"
                                           reason:[NSString stringWithFormat:@"fixedSecItemCopyMatching reported key with identifier '%@' could not be found.",keyIdentifier]
                                         userInfo:nil];
        } else {
            @throw [NSException exceptionWithName:@"QredoKeyIdentifierFailure"
                                           reason:[NSString stringWithFormat:@"fixedSecItemCopyMatching returned error: %@.",[QredoLogger stringFromOSStatus:status]]
                                         userInfo:nil];
        }
    } else if (secKeyRef == nil){
        @throw [NSException exceptionWithName:@"QredoKeyIdentifierNotReturned"
                                       reason:@"Key ref came back nil despite success."
                                     userInfo:nil];
    }
    
    return secKeyRef;
}


+(NSData *)getKeyDataForIdentifier:(NSString *)keyIdentifier {
    
    GUARD(keyIdentifier,
          @"Key identifier argument is nil");
    
    CFTypeRef keyDataRef;
    NSData *keyData = nil;
    NSMutableDictionary *queryKey = [[NSMutableDictionary alloc] init];
    
    NSData *tag = [keyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    //Set the public key query dictionary.
    queryKey[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    queryKey[(__bridge id)kSecAttrApplicationTag] = tag;
    queryKey[(__bridge id)kSecAttrKeyType] = (__bridge id)kSecAttrKeyTypeRSA;
    queryKey[(__bridge id)kSecReturnData] = @YES;
    
    //Get the key data bits.
    OSStatus result = fixedSecItemCopyMatching((__bridge CFDictionaryRef)queryKey,(CFTypeRef *)&keyDataRef);
    
    if (result != errSecSuccess){
        if (result == errSecItemNotFound){
            @throw [NSException exceptionWithName:@"QredoKeyIdentifierNotFound"
                                           reason:[NSString stringWithFormat:@"fixedSecItemCopyMatching reported key with identifier '%@' could not be found.",keyIdentifier]
                                         userInfo:nil];
        } else {
            @throw [NSException exceptionWithName:@"QredoKeyIdentifierFailure"
                                           reason:[NSString stringWithFormat:@"fixedSecItemCopyMatching returned error: %@.",[QredoLogger stringFromOSStatus:result]]
                                         userInfo:nil];
        }
    }
    
    keyData = (__bridge_transfer NSData *)keyDataRef;
    return keyData;
}





+(NSData *)rsaPssSignMessage:(NSData *)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef {
    
    GUARD(message,
          @"Message argument is nil");
    
    GUARD(keyRef,
          @"Key ref argument is nil");
    
    NSData *hash = [self sha256:message];
    
    size_t keyLength = SecKeyGetBlockSize(keyRef);
    
    
    GUARD(keyLength != 0,
          @"Invalid SecKeyRef. Key block size is 0 bytes.");
    
    //Get a buffer of correct size for the specified key
    size_t pssDataLength = keyLength;
    NSMutableData *pssData = [NSMutableData dataWithLength:pssDataLength];
    NSMutableData *outputData = [NSMutableData dataWithLength:pssDataLength];
    
    
    //NSData *dat = [QredoRendezvousCrypto transformPrivateKeyToData:keyRef ];
    int pss_result = rsa_pss_sha256_encode(hash.bytes,hash.length,saltLength,keyLength * 8 - 1,
                                           pssData.mutableBytes,pssData.length);
    
    GUARDF(pss_result >= 0,
           @"Failed to encode with PSS. Error code: %d",
           pss_result);
    
    size_t outputDataLength = outputData.length;
    OSStatus result = SecKeyRawSign(keyRef,
                                    kSecPaddingNone,
                                    pssData.bytes,pssData.length,
                                    outputData.mutableBytes,&outputDataLength);
    
    if (result != errSecSuccess){
        //Something went wrong, so return nil;
        QredoLogError(@"SecKeyRawSign returned error: %@.",[QredoLogger stringFromOSStatus:result]);
        outputData = nil;
        
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Failed to sign the data" userInfo:nil];
    }
    
    return outputData;
}







OSStatus fixedSecItemCopyMatching(CFDictionaryRef query,CFTypeRef *result) {
    /*
     Have found that in certain circumstances, possibly concurrency related, that SecItemCopyMatching() will return
     an error code (-50: "One or more parameters passed to a function where not valid"). Retying the operation with
     exactly the same parameters appears to then succeed.  Unclear whether this is a Simulator issue, or whether
     it is a concurrency issue, not sure - however this method attempts to automatically retry if -50 is encountered.
     */
    
    //Get the key reference.
    OSStatus status = SecItemCopyMatching(query,result);
    
    if (status != errSecSuccess){
        QredoLogVerbose(@"SecItemCopyMatching returned error: %@. Query dictionary: %@",
                        [QredoLogger stringFromOSStatus:status],
                        query);
        
        if (status == errSecParam){
            //Specical case - retry
            status = SecItemCopyMatching(query,result);
            
            if (status != errSecSuccess){
                if (status == errSecParam){
                    //Retry failed
                    QredoLogError(@"Retry SecItemCopyMatching unsuccessful, same error returned: %@. Query dictionary: %@",
                                  [QredoLogger stringFromOSStatus:status],
                                  query);
                } else {
                    //Retry fixed -50/errSecParam issue, but a different error occurred
                    QredoLogError(@"Retrying SecItemCopyMatching returned different error: %@. Query dictionary: %@",
                                  [QredoLogger stringFromOSStatus:status],
                                  query);
                }
            } else {
                QredoLogError(@"Retrying SecItemCopyMatching resulted in success. Query dictionary: %@",query);
            }
        }
    }
    
    return status;
}


@end
