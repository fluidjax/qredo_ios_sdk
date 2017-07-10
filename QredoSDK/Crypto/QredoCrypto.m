/* HEADER GOES HERE */
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"

#import "QredoRendezvousCrypto.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoLoggerPrivate.h"
#import "rsapss.h"
//#import "QredoCertificateUtils.h"

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
#define RSA_OAEP_MIN_PADDING_LENGTH  42
#define RSA_PKCS1_MIN_PADDING_LENGTH 11

#define GUARD(condition, msg) \
    if (!(condition)) { \
        @throw [NSException exceptionWithName:NSInvalidArgumentException \
                            reason:[NSString stringWithFormat:(msg)] \
                            userInfo:nil]; \
    }

#define GUARDF(condition, fmt, ...) \
    if (!(condition)) { \
        @throw [NSException exceptionWithName:NSInvalidArgumentException \
                            reason:[NSString stringWithFormat:(fmt), __VA_ARGS__] \
                            userInfo:nil]; \
    }

+(NSData *)decryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv {
    return [self aes:data withOperation:kCCDecrypt with256bitAesKey:key iv:iv];
}


+(NSData *)encryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv {
    return [self aes:data withOperation:kCCEncrypt with256bitAesKey:key iv:iv];
}

+(NSData *)aes:(NSData *)input withOperation:(CCOperation)operation with256bitAesKey:(NSData *)key iv:(NSData *)iv {
    
    GUARD(input,
          @"Input argument is nil.");
    
    GUARD(key,
          @"Key argument is nil");
    
    GUARDF(key.length == kCCKeySizeAES256,
           @"Key must be %d bytes.", kCCKeySizeAES256);
    
    GUARDF((iv && iv.length == kCCBlockSizeAES128), //note block size is same for all key lengths - ie.128bit
           @"IV must be %d bytes.", kCCBlockSizeAES128);
    
    NSMutableData *output = [NSMutableData dataWithLength:(input.length + kCCBlockSizeAES128)];
    size_t outputLength;
    CCCryptorStatus result = CCCrypt(operation,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     key.bytes,
                                     key.length,
                                     iv.bytes,
                                     input.bytes,
                                     input.length,
                                     output.mutableBytes,
                                     output.length,
                                     &outputLength);
    
    if (result == kCCSuccess) {
        return [output subdataWithRange:NSMakeRange(0, outputLength)];
    } else {
        return nil;
    }
    
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

+(NSData *)hkdfExpandSha256WithKey:(NSData *)prk info:(NSData *)info outputLength:(NSUInteger)outputLength {
    
    GUARD(prk, @"PRK must be specified.");
    GUARD(outputLength, @"Output length must be specified.");
    
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


+(SecKeyRef)importPkcs1KeyData:(NSData *)keyData keyLengthBits:(NSUInteger)keyLengthBits keyIdentifier:(NSString *)keyIdentifier isPrivate:(BOOL)isPrivate {
    //Note, this method will happily import public key data marked as private, but our getRsaSecKeyReferenceForIdentifier method will return null SecKeyRef (and no error).
    
    CFTypeRef keyClass = kSecAttrKeyClassPublic;
    
    if (isPrivate){
        keyClass = kSecAttrKeyClassPrivate;
    }
    
    NSData *tag = [keyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    /* Attributes which are valid for kSecClassKey:
     
     kSecClassKey item attributes:
     kSecAttrAccessible
     kSecAttrAccessControl
     kSecAttrAccessGroup
     kSecAttrKeyClass
     kSecAttrLabel
     kSecAttrApplicationLabel
     kSecAttrIsPermanent - Note: appears to be ignored on SecItemAdd, can only Add permanent keys
     kSecAttrApplicationTag
     kSecAttrKeyType
     kSecAttrKeySizeInBits
     kSecAttrEffectiveKeySize
     kSecAttrCanEncrypt
     kSecAttrCanDecrypt
     kSecAttrCanDerive
     kSecAttrCanSign
     kSecAttrCanVerify
     kSecAttrCanWrap
     kSecAttrCanUnwrap
     
     */
    
    //Note: SecItemAdd() does not validate the key size argument.
    
    //TODO: DH - need to verify these settings, especially the canEncrypt/canDecrypt/canSign options - should these be configurable per key?  Configured based on public/private setting?  For now, allowing encrypt/decrypt/sign/verify
    NSMutableDictionary *keyAttributes = [[NSMutableDictionary alloc] init];
    keyAttributes[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    keyAttributes[(__bridge id)kSecAttrKeyType] = (__bridge id)kSecAttrKeyTypeRSA;
    keyAttributes[(__bridge id)kSecAttrApplicationTag] = tag;
    keyAttributes[(__bridge id)kSecAttrKeyClass] = (__bridge id)keyClass;
    keyAttributes[(__bridge id)kSecValueData] = keyData;
    keyAttributes[(__bridge id)kSecAttrKeySizeInBits] = [NSNumber numberWithInteger:keyLengthBits];
    keyAttributes[(__bridge id)kSecAttrEffectiveKeySize] = [NSNumber numberWithInteger:keyLengthBits];
    keyAttributes[(__bridge id)kSecAttrCanDerive] = (__bridge id)kCFBooleanFalse;
    keyAttributes[(__bridge id)kSecAttrCanEncrypt] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanDecrypt] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanVerify] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanSign] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanWrap] = (__bridge id)kCFBooleanFalse;
    keyAttributes[(__bridge id)kSecAttrCanUnwrap] = (__bridge id)kCFBooleanFalse;
    keyAttributes[(__bridge id)kSecReturnRef] = (__bridge id)kCFBooleanTrue;
    
    SecKeyRef secKeyRef = nil;
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keyAttributes,(CFTypeRef *)&secKeyRef);
    
    if (status != errSecSuccess){
        @throw [NSException exceptionWithName:@"QredoCryptoImportPublicKeyFailed"
                                       reason:[NSString stringWithFormat:@"Error code: %d",(int)status]
                                     userInfo:nil];
    } else if (!secKeyRef){
        @throw [NSException exceptionWithName:@"QredoCryptoImportPublicKeyInvalidFormat"
                                       reason:@"No imported key ref returned. Check key format is PKCS#1 ASN.1 DER."
                                     userInfo:nil];
    } else {
        return (SecKeyRef)secKeyRef;
    }
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


//TODO: DH - create unit test for this? (check also if any other SecKeyRef methods added are tested)
+(SecCertificateRef)getCertificateRefFromIdentityRef:(SecIdentityRef)identityRef {
    
    GUARD(identityRef,
          @"Identity ref argument is nil");
    
    SecCertificateRef certificateRef = nil;
    
    OSStatus status = SecIdentityCopyCertificate(identityRef,&certificateRef);
    
    if (status != errSecSuccess){
        QredoLogError(@"SecIdentityCopyCertificate returned error: %@",[QredoLogger stringFromOSStatus:status]);
        certificateRef = nil;
    }
    
    return certificateRef;
}


+(SecKeyRef)getPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef {
    
    GUARD(identityRef,
          @"Identity ref argument is nil");
    
    SecKeyRef privateKeyRef = nil;
    
    OSStatus status = SecIdentityCopyPrivateKey(identityRef,&privateKeyRef);
    
    if (status != errSecSuccess){
        QredoLogError(@"SecIdentityCopyPrivateKey returned error: %@",[QredoLogger stringFromOSStatus:status]);
        identityRef = nil;
    }
    
    return privateKeyRef;
}


+(SecKeyRef)getPublicKeyRefFromIdentityRef:(SecIdentityRef)identityRef {

    GUARD(identityRef,
          @"Identity ref argument is nil");
    
    /*
     Unfortunately, iOS does not provide a way to get the public key directly from a SecCertificateRef.
     Instead, you have to create a SecTrustRef from the certificate, evaluate the trust and get it from there.
     This is fine when you're importing a PKCS#12 blob as you get a SecTrustRef as part of that.  However, if the
     SecIdentityRef was stored in the Keychain, then you do not get a SecTrustRef.  Additionally, you may not know
     which root/anchor certificate is required to successfully evaluate the trust, although that doesn't necessarily
     cause a problem, as a failed evaluation doesn't prevent returning the public key.
     */
    
    SecKeyRef publicKeyRef = nil;
    SecCertificateRef publicCertificateRef = nil;
    
    OSStatus status = SecIdentityCopyCertificate(identityRef,&publicCertificateRef);
    
    if (status != errSecSuccess){
        QredoLogError(@"SecIdentityCopyCertificate returned error: %@",[QredoLogger stringFromOSStatus:status]);
    }
    
    //Now need to create and evaluate a SecTrustRef
    NSArray *certificates = @[(__bridge id)publicCertificateRef];
    
    SecTrustRef trustRef = nil;
    SecPolicyRef policyRef = SecPolicyCreateBasicX509();
    
    status = SecTrustCreateWithCertificates((__bridge CFArrayRef)certificates,policyRef,&trustRef);
    
    if (status != noErr){
        QredoLogError(@"Creating trust failed: %@",[QredoLogger stringFromOSStatus:status]);
    } else {
        //Now evaluate the trust we've created with this public certificate, required before obtaining the public key.
        //If fetched from keychain, we do not know which root/anchor certificate is needed. If the root/anchor was
        //stored in the keychain, it could be searched from there - however, unsuccessful trust evaulation does
        //not prevent extraction of the public key, so no anchors are configured here.
        
        SecTrustResultType trustResult;
        OSStatus status = SecTrustEvaluate(trustRef,&trustResult);
        
        if (status != noErr){
            QredoLogError(@"Trust evaluation returned error: %@",[QredoLogger stringFromOSStatus:status]);
        } else {
            //Trust evaluation completed (not interested in trust result)
            publicKeyRef = [self getPublicKeyRefFromEvaluatedTrustRef:trustRef];
        }
    }
    
    if (policyRef){
        CFRelease(policyRef);
    }
    
    if (trustRef){
        CFRelease(trustRef);
    }
    
    return publicKeyRef;
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


+(NSData *)rsaEncryptPlainTextData:(NSData *)plainTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef {
    
    GUARD(plainTextData,
          @"Plain text data argument is nil.");
    
    GUARD(keyRef,
          @"Key ref argument is nil");
    
    //Length of data to encrypt varies depending on the padding option and key length
    size_t keyLength = SecKeyGetBlockSize(keyRef);
    
    //If the SecKeyRef is invalid (e.g. has been released), then SecKeyGetBlockSize appears to return 0 length
    GUARD(keyLength != 0,
          @"Invalid SecKeyRef. Key block size is 0 bytes.");
    
    SecPadding secPaddingType = secPaddingFromQredoPaddingForPlainData(padding,keyLength,plainTextData);
    
    //Get a buffer of correct size for the specified key
    size_t outputDataLength = keyLength;
    NSMutableData *outputData = [NSMutableData dataWithLength:outputDataLength];
    
    OSStatus result = SecKeyEncrypt(keyRef, //key
                                    secPaddingType, //padding
                                    plainTextData.bytes, //plainText
                                    plainTextData.length, //plainTextLen
                                    outputData.mutableBytes, //cipherText
                                    &outputDataLength); //ciptherTextLen
    
    if (result != errSecSuccess){
        //Something went wrong, so return nil;
        QredoLogError(@"SecKeyEncrypt returned error: %@.",[QredoLogger stringFromOSStatus:result]);
        outputData = nil;
    }
    
    return outputData;
}


SecPadding secPaddingFromQredoPadding(QredoPadding padding) {
    SecPadding secPaddingType;
    
    switch (padding){
        case QredoPaddingNone:
            secPaddingType = kSecPaddingNone;
            break;
            
        case QredoPaddingOaep:
            secPaddingType = kSecPaddingOAEP;
            break;
            
        case QredoPaddingPkcs1:
            secPaddingType = kSecPaddingPKCS1;
            break;
            
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Invalid padding argument value (%u).",padding]
                                         userInfo:nil];
            break;
    }
    return secPaddingType;
}


+(NSData *)rsaDecryptCipherTextData:(NSData *)cipherTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef {
    /*
     
     NOTE: When decrypting data, if the original plaintext had leading zeroes, these will be lost when
     decrypting.  The various PKCS#1.5/OAEP/PSS padding schemes include steps to restore the leading
     zeroes and so these work fine, e.g.
     "Convert the message representative m to an encoded message EM of length k-1 octets: EM = I2OSP (m, k-1)"
     
     However, if the caller is using QredoPaddingNone/kSecPaddingNone then the caller is responsible
     for restoring any leading zeroes, e.g.
     Create a buffer of keyLength and copy in the decryptedData to index 'keyLength - decryptedData.Length'
     
     */
    
    GUARD(cipherTextData,
          @"Cipher text data argument is nil");
    
    GUARD(keyRef,
          @"Key ref argument is nil");
    
    //Length of data to decrypt must equal key length
    size_t keyLength = SecKeyGetBlockSize(keyRef);
    
    GUARD(keyLength != 0,
          @"Invalid SecKeyRef. Key block size is 0 bytes.");
    
    GUARDF(cipherTextData.length == keyLength,
           @"Invalid data length (%lu). Input data must equal key length (%lu).",
           (unsigned long)cipherTextData.length, (unsigned long)keyLength);
    
    SecPadding secPaddingType;
    secPaddingType = secPaddingFromQredoPadding(padding);
    
    //Get a buffer of correct size for the specified key
    size_t outputDataLength = keyLength;
    NSMutableData *buffer = [NSMutableData dataWithLength:outputDataLength];
    
    OSStatus result = SecKeyDecrypt(keyRef, //key
                                    secPaddingType, //padding
                                    cipherTextData.bytes, //cipherText
                                    cipherTextData.length, //ciptherTextLen
                                    buffer.mutableBytes, //plainText
                                    &outputDataLength); //plainTextLen
    
    NSData *outputData = nil;
    
    if (result == errSecSuccess){
        //If padded, the output buffer may be larger than the decrypted data, so only return the correct portion
        NSRange outputRange = NSMakeRange(0,outputDataLength);
        outputData = [buffer subdataWithRange:outputRange];
    } else {
        QredoLogError(@"SecKeyDecrypt returned error: %@.",[QredoLogger stringFromOSStatus:result]);
    }
    
    return outputData;
}


SecPadding secPaddingFromQredoPaddingForPlainData(QredoPadding padding,size_t keyLength,NSData *plainTextData) {
    SecPadding secPaddingType;
    
    switch (padding){
        case QredoPaddingNone:
            
            //When no padding is selected, the plain text length must be same as key length
            GUARDF(plainTextData.length == keyLength,
                   @"Invalid data length (%lu) when no padding is requested. Input data must equal key length (%lu).",
                   (unsigned long)plainTextData.length,(unsigned long)keyLength);
            
            secPaddingType = kSecPaddingNone;
            break;
            
        case QredoPaddingOaep:
            
            //OAEP adds at least 2+(2*hash_size) bytes of padding, and total length cannot exceed key length.
            //Default OAEP MGF1 digest algorithm is SHA1 (20 byte output), so min 42 bytes padding. However
            //if a different algorithm is specified, then min padding will change.
            GUARDF(plainTextData.length + RSA_OAEP_MIN_PADDING_LENGTH <= keyLength,
                   @"Invalid data length (%lu) for provided key length (%lu) and OAEP padding. Default OAEP uses SHA1 so adds minimum 42 bytes "
                   @"padding. Maximum data to encrypt is (key_size - min_padding_size).",
                   (unsigned long)plainTextData.length, (unsigned long)keyLength);
            
            secPaddingType = kSecPaddingOAEP;
            break;
            
        case QredoPaddingPkcs1:
            
            //PKCS#1 v1.5 adds at least 11 bytes of padding, and total length cannot exceed key length.
            GUARDF(plainTextData.length + RSA_PKCS1_MIN_PADDING_LENGTH <= keyLength,
                   @"Invalid data length (%lu) for provided key length (%lu) and PKCS#1 v1.5 padding. PKCS#1 v1.5 adds minimum 11 bytes padding. "
                   @"Maximum data to encrypt is (key_size - min_padding_size).",
                   (unsigned long)plainTextData.length, (unsigned long)keyLength);
            
            secPaddingType = kSecPaddingPKCS1;
            break;
            
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Invalid padding argument value (%u).",padding]
                                         userInfo:nil];
            break;
    }
    return secPaddingType;
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


+(BOOL)rsaPssVerifySignature:(NSData *)signature forMessage:(NSData *)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef {
    
    
    GUARD(signature,
          @"Signature argument is nil.");
    
    GUARD(message,
          @"Message argument is nil.");
    
    GUARD(keyRef,
          @"Key ref argument is nil.");
    
    //Length of data to decrypt must equal key length
    size_t keyLength = SecKeyGetBlockSize(keyRef);
    
    GUARD(keyLength != 0,
          @"Invalid SecKeyRef. Key block size is 0 bytes.");
    
    GUARDF(signature.length == keyLength,
           @"Invalid data length (%lu). Signature must equal key length (%lu).",
           (unsigned long)signature.length, (unsigned long)keyLength);
    
    //Get a buffer of correct size for the specified key
    size_t outputDataLength = keyLength;
    NSMutableData *buffer = [NSMutableData dataWithLength:outputDataLength];
    
    OSStatus result = SecKeyDecrypt(keyRef, //key
                                    kSecPaddingNone, //padding
                                    signature.bytes, //cipherText
                                    signature.length, //ciptherTextLen
                                    buffer.mutableBytes, //plainText
                                    &outputDataLength); //plainTextLen
    
    if (result != errSecSuccess){
        QredoLogError(@"SecKeyDecrypt returned error: %@.",[QredoLogger stringFromOSStatus:result]);
        return NO;
    }
    
    //Restore any leading zeroes which were 'lost' in the decrypt by copying to array of keyLength, skipping the position of missing zeroes
    uint8_t *decryptedSignatureBytes = malloc(keyLength);
    size_t destinationIndex = keyLength - outputDataLength;
    memcpy(decryptedSignatureBytes + destinationIndex,buffer.bytes,outputDataLength);

    //This doesn't leak
    NSMutableData *decryptedSignature = [NSMutableData dataWithBytesNoCopy:decryptedSignatureBytes length:keyLength freeWhenDone:YES];

    
    NSData *hash = [self sha256:message];
    
    int pss_result = rsa_pss_sha256_verify(hash.bytes,hash.length,decryptedSignature.bytes,decryptedSignature.length,saltLength,keyLength * 8 - 1);
    
    if (pss_result < 0 && pss_result != QREDO_RSA_PSS_NOT_VERIFIED){
        QredoLogError(@"Failed to decode PSS data. Result %d",pss_result);
    }
    
    return pss_result == QREDO_RSA_PSS_VERIFIED;
}


+(BOOL)deleteAllKeysInAppleKeychain {
    BOOL success = YES;
    
    //Just specify that all items of kSecClassKey should be deleted
    NSDictionary *secKeysToDelete = @{ (__bridge id)kSecClass:(__bridge id)kSecClassKey };
    
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)secKeysToDelete);
    
    if (result != errSecSuccess){
        if (result == errSecItemNotFound){
            //This means that no keys were present to delete, this is not an error in this situation (bulk delete of all keys)
        } else {
            QredoLogError(@"SecItemDelete returned error: %@.",[QredoLogger stringFromOSStatus:result]);
            success = NO;
        }
    }
    
    return success;
}


+(BOOL)deleteKeyInAppleKeychainWithIdentifier:(NSString *)keyIdentifier {
    
    GUARD(keyIdentifier,
          @"Key identifier argument is nil");
    
    BOOL success = YES;
    
    NSData *tag = [keyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!tag)return NO;
    
    //Specify that all items of kSecClassKey which have this identifier tag should be deleted
    NSDictionary *secKeysToDelete = @{ (__bridge id)kSecClass:(__bridge id)kSecClassKey,
                                       (__bridge id)kSecAttrApplicationTag:tag };
    
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)secKeysToDelete);
    
    if (result != errSecSuccess){
        success = NO;
        
        if (result == errSecItemNotFound){
            //This means that the specified key was not found. This is an error as specifying a specific key
            QredoLogError(@"Could not find key with identifier '%@' to delete.",keyIdentifier);
        } else {
            QredoLogError(@"SecItemDelete returned error: %@.",[QredoLogger stringFromOSStatus:result]);
        }
    }
    
    return success;
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
