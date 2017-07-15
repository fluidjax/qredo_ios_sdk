#import <CommonCrypto/CommonCrypto.h>
#import "rsapss.h"

#import "MasterConfig.h"
#import "QredoLoggerPrivate.h"
#import "QredoCrypto.h"


@implementation QredoCrypto


SecPadding secPaddingFromQredoPadding(QredoPadding);
SecPadding secPaddingFromQredoPaddingForPlainData(QredoPadding,size_t,NSData*);

#define PBKDF2_MIN_SALT_LENGTH       8 //RFC recommends minimum of 8 bytes salt

/*
 OAEP padding adds minimum 2+(2*hash_size) bytes padding.
 Default OAEP uses SHA1, which is 20byte hash output.
 Therefore minimum padding is 42 bytes. Could be longer if
 we later specify a different OAEP MGF1 digest algorithm
 */


#define AESGUARD(condition, msg) \
    if (!(condition)) { \
        if (cryptor) \
            CCCryptorRelease(cryptor); \
        @throw [NSException exceptionWithName:NSGenericException \
                            reason:[NSString stringWithFormat:(msg)] \
                            userInfo:nil]; \
    }

/*****************************************************************************
 * new work
 ****************************************************************************/

#define NEW_CRYPTO_CODE FALSE



+(NSData *)aes256CtrEncrypt:(NSData *)plaintext key:(NSData *)key iv:(NSData *)iv {
    return [self aes256Ctr:plaintext operation:kCCEncrypt key:key iv:iv];
}

+(NSData *)aes256CtrDecrypt:(NSData *)ciphertext key:(NSData *)key iv:(NSData *)iv {
    return [self aes256Ctr:ciphertext operation:kCCDecrypt key:key iv:iv];
}

+(NSData *)aes256Ctr:(NSData *)input operation:(CCOperation)op key:(NSData *)key iv:(NSData *)iv {

    GUARD(input, @"Input must be specified.");
    GUARD((op == kCCEncrypt) || (op == kCCDecrypt), @"Operation must be encryption or decryption.");
    GUARD(key, @"Key must be specified");
    GUARDF(key.length == kCCKeySizeAES256, @"Key must be %d bytes.", kCCKeySizeAES256);
    GUARDF(iv && iv.length == kCCBlockSizeAES128, @"IV must be %d bytes.", kCCBlockSizeAES128);

    CCCryptorRef cryptor = NULL;
    CCCryptorStatus createStatus = CCCryptorCreateWithMode(op,
            kCCModeCTR,
            kCCAlgorithmAES,
            ccPKCS7Padding,
            iv.bytes,
            key.bytes,
            key.length,
            NULL,
            0,
            0,
            kCCModeOptionCTR_BE,
            &cryptor);

    AESGUARD((createStatus == kCCSuccess), @"AES operation failed (1) CCCryptorCreateWithMode");

    NSMutableData *cipherData = [NSMutableData dataWithLength:input.length + kCCBlockSizeAES128];
    size_t outLength;
    CCCryptorStatus updateStatus = CCCryptorUpdate(cryptor,
            input.bytes,
            input.length,
            cipherData.mutableBytes,
            cipherData.length,
            &outLength);

    AESGUARD((updateStatus == kCCSuccess), @"AES operation failed (2) CCCryptorUpdate");

    cipherData.length = outLength;
    CCCryptorStatus finalStatus = CCCryptorFinal(cryptor,
            cipherData.mutableBytes,
            cipherData.length,
            &outLength);

    AESGUARD((finalStatus == kCCSuccess), @"AES operation failed (3) CCCryptorFinal");

    return cipherData;

}

#if NEW_CRYPTO_CODE

+(BOOL)constantEquals:(NSData *)lhs rhs:(NSData *)rhs {

    uint8_t *leftHashBytes  = (uint8_t *)lhs.bytes;
    uint8_t *rightHashBytes = (uint8_t *)rhs.bytes;

    unsigned long difference = lhs.length ^ rhs.length;

    for (unsigned long i = 0; i < lhs.length && i < rhs.length; i++){
        difference |= leftHashBytes[i] ^ rightHashBytes[i];
    }

    return difference == 0;

}

+(QredoKeyPair *)ed25519Derive:(NSData *)seed {

    NSMutableData *pk = [NSMutableData dataWithLength:ED25519_VERIFY_KEY_LENGTH];
    NSMutableData *sk = [NSMutableData dataWithLength:ED25519_SIGNING_KEY_LENGTH];

    crypto_sign_ed25519_seed_keypair(pk.mutableBytes, sk.mutableBytes, seed.bytes);

    QredoED25519VerifyKey *qpk  = [[QredoED25519VerifyKey new]  initWithKeyData:pk];
    QredoED25519SigningKey *qsk = [[QredoED25519SigningKey new] initWithSeed:seed keyData:sk verifyKey:qpk];

    return [[QredoKeyPair new] initWithPublicKey:qpk privateKey:qsk];

}

+(NSData *)ed25519Sha512Sign:(NSData *)payload keyPair:(QredoKeyPair *)keyPair {

    NSMutableData *signature = [NSMutableData dataWithLength:ED25519_SIGNATURE_LENGTH]

    crypto_sign_ed25519_detached(signature.mutableBytes, NULL, payload.bytes, payload.length, keyPair.privateKey.convertKeyToNSData.bytes);
    return signature;

}

+(BOOL)ed25519Sha512Verify:(NSData *)payload signature:(NSData *)signature keyPair:(QredoKeyPair *)keyPair {
    return crypto_sign_ed25519_verify_detached(signature.bytes, payload.bytes, payload.length, keyPair.publicKey.convertKeyToNSData.bytes) == 0;
}

+(NSData *)hkdfSha256:(NSData *)ikm salt:(NSData *)salt info:(NSData *)info outputLength:(NSUInteger)outputLength {
    NSData *prk = [QredoCrypto hkdfExtractSha256WithSalt:salt initialKeyMaterial:ikm];
    NSData *okm = [QredoCrypto hkdfExpandSha256WithKey:prk info:info outputLength:outputLength];
    return okm;
}

+(NSData *)pbkdf2Sha256:(NSData *)ikm salt:(NSData *)salt outputLength:(NSUInteger)outputLength iterations:(NSUInteger)iterations {

    NSAssert(ikm, @"PBKDF2-SHA256 IKM == nil.");
    NSAssert(ikm.length > 0, @"PBKDF2-SHA256 IKM length == 0.");
    NSAssert(outputLength > 0, @"PBKDF2-SHA256 output length == 0.");
    NSAssert(iterations > 0, @"PBKDF2-SHA256 iterations == 0");

    NSMutableData *derivedKey = [NSMutableData dataWithLength:outputLength];

    int result = CCKeyDerivationPBKDF(kCCPBKDF2,
            ikm.bytes,
            ikm.length,
            salt.bytes,
            salt.length,
            kCCPRFHmacAlgSHA256,
            iterations,
            derivedKey.mutableBytes,
            derivedKey.length);

    NSAssert(result == kCCSuccess, @"CCKeyDerivationPBKDF: failure %d.", result);

    return derivedKey;

}

+(QredoKeyPair *)rsaGenerate {
    return nil;
}

+(NSData *)rsaPssSha256Sign:(NSData *)payload keyPair:(QredoKeyPair *)keyPair {
    return nil;
}

+(BOOL)rsaPassSha256Verify:(NSData *)payload signature:(NSData *)signature keyPair:(QredoKeyPair *)keyPair {
    return nil;
}

+(NSData *)secureRandom:(NSUInteger)size {
    return nil;
}

+(NSData *)sha256:(NSData *)payload salt:(NSData *)salt {
    return nil;
}

#endif

/*****************************************************************************
 * old work
 ****************************************************************************/

+(NSData *)decryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv {
     return [self aes256CtrDecrypt:data key:key iv:iv];
}


+(NSData *)encryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv {
     return [self aes256CtrEncrypt:data key:key iv:iv];
}

+(NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info outputLength:(NSUInteger)outputLength {
    
    GUARD(ikm, @"IKM must be specified.");
    GUARD(outputLength > 0, @"Output length must be greater than zero.");

    // Please read https://tools.ietf.org/html/rfc5869 to understand HKDF.
    
    NSData *realSalt = salt ? salt : [NSData new];
    NSData *realInfo = info ? info : [NSData new];
        
    NSData *prk = [QredoCrypto hkdfSha256ExtractWithSalt:realSalt initialKeyMaterial:ikm];
    NSData *okm = [QredoCrypto hkdfSha256ExpandWithKey:prk info:realInfo outputLength:outputLength];
    
    return okm;
    
}

+(NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info {
    return [self hkdfSha256WithSalt:salt initialKeyMaterial:ikm info:info outputLength:CC_SHA256_DIGEST_LENGTH];
}

+(NSData *)hkdfSha256ExtractWithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm {

    GUARD(ikm, @"IKM must be specified.")
    
    NSMutableData *prk = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, salt.bytes, salt.length, ikm.bytes, ikm.length, prk.mutableBytes);
    
    return prk;
    
}

+(NSData *)hkdfSha256ExpandWithKey:(NSData *)prk info:(NSData *)info outputLength:(NSUInteger)outputLength {
    
    uint8_t hashLen = CC_SHA256_DIGEST_LENGTH;
    
    NSUInteger N = ceil((double)outputLength / (double)hashLen);
    uint8_t *T   = alloca(N * hashLen);
    
    uint8_t *Tlast = NULL;
    uint8_t *Tnext = T;
    for (uint8_t ctr = 1; ctr <= N; ctr++) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, kCCHmacAlgSHA256, prk.bytes, prk.length);
        CCHmacUpdate(&ctx, Tlast, Tlast ? hashLen : 0); // T[n-1] or empty for T[0]
        CCHmacUpdate(&ctx, info.bytes, info.length);    // optional info
        CCHmacUpdate(&ctx, &ctr, 1);                    // counter octet
        CCHmacFinal(&ctx, Tnext);                       // write to T[n]
        Tlast  = Tnext;
        Tnext += hashLen;
    }
    
    return [NSData dataWithBytes:T length:outputLength];
    
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
    GUARD(data, @"Data must be specified.");
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (unsigned int)data.length, hash.mutableBytes);
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

    uint8_t *leftHashBytes  = (uint8_t *)left.bytes;
    uint8_t *rightHashBytes = (uint8_t *)right.bytes;

    unsigned long difference = left.length ^ right.length;

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
