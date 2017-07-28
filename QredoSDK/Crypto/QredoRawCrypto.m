#import <CommonCrypto/CommonCrypto.h>
#import "sodium.h"
#import "rsapss.h"

#import "MasterConfig.h"
#import "QredoLoggerPrivate.h"
#import "QredoRawCrypto.h"
#import "QredoED25519VerifyKey.h"
#import "QredoED25519SigningKey.h"

// TODO: pragma mark
// TODO: clean up old commentary
// TODO: reformat long lines
// TODO: look at keychain wrapper
// TODO: use warning assertions more often

@implementation QredoRawCrypto

SecPadding secPaddingFromQredoPadding(QredoPadding);
SecPadding secPaddingFromQredoPaddingForPlainData(QredoPadding,size_t,NSData*);

/*
 OAEP padding adds minimum 2+(2*hash_size) bytes padding.
 Default OAEP uses SHA1, which is 20byte hash output.
 Therefore minimum padding is 42 bytes. Could be longer if
 we later specify a different OAEP MGF1 digest algorithm
 */

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
    
    NSAssert(input, @"Expected input data.");
    NSAssert((op == kCCEncrypt) || (op == kCCDecrypt), @"Expected encryption or decryption operations.");
    NSAssert(key, @"Expected key.");
    NSAssert(key.length == kCCKeySizeAES256, @"Expected key to be %d bytes.", kCCKeySizeAES256);
    NSAssert(iv && iv.length == kCCBlockSizeAES256, @"Expected IV to be %d bytes.", kCCBlockSizeAES256);
    
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus createStatus = CCCryptorCreateWithMode(
                                                           op,
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
    
    NSAssert(createStatus == kCCSuccess, @"CCCCryptorCreateWithMode failed with status %d.", createStatus);
    
    NSMutableData *cipherData = [NSMutableData dataWithLength:input.length + kCCBlockSizeAES256];
    size_t outLength;
    CCCryptorStatus updateStatus = CCCryptorUpdate(
                                                   cryptor,
                                                   input.bytes,
                                                   input.length,
                                                   cipherData.mutableBytes,
                                                   cipherData.length,
                                                   &outLength);
    
    NSAssert(updateStatus == kCCSuccess, @"CCCryptorUpdate failed with status %d.", updateStatus);
    
    cipherData.length = outLength;
    CCCryptorStatus finalStatus = CCCryptorFinal(
                                                 cryptor,
                                                 cipherData.mutableBytes,
                                                 cipherData.length,
                                                 &outLength);
    
    NSAssert(finalStatus == kCCSuccess, @"CCCryptorFinal failed with status %d.", finalStatus);
    
    return cipherData;
    
}

+(BOOL)constantEquals:(NSData *)lhs rhs:(NSData *)rhs {
    
    uint8_t *leftHashBytes  = (uint8_t *)lhs.bytes;
    uint8_t *rightHashBytes = (uint8_t *)rhs.bytes;
    
    unsigned long difference = lhs.length ^ rhs.length;
    
    for (unsigned long i = 0; i < lhs.length && i < rhs.length; i++) {
        difference |= leftHashBytes[i] ^ rightHashBytes[i];
    }
    
    return difference == 0;
    
}

+(QredoKeyPair *)ed25519Derive:(NSData *)seed {
    
    NSAssert(seed, @"Expected seed.");
    NSAssert(seed.length == crypto_sign_SEEDBYTES,
             @"Expected seed of length %ud.", crypto_sign_SEEDBYTES);
    
    NSMutableData *pk = [NSMutableData dataWithLength:crypto_sign_PUBLICKEYBYTES];
    NSMutableData *sk = [NSMutableData dataWithLength:crypto_sign_SECRETKEYBYTES];
    
    int result = crypto_sign_ed25519_seed_keypair(pk.mutableBytes, sk.mutableBytes, seed.bytes);
    NSAssert(result == 0, @"Could not generate Ed25519 key pair from seed.");
    
    QredoED25519VerifyKey *qpk  =
    [[QredoED25519VerifyKey alloc] initWithKeyData:pk];
    QredoED25519SigningKey *qsk =
    [[QredoED25519SigningKey alloc] initWithSeed:seed keyData:sk verifyKey:qpk];
    QredoKeyPair *kp =
    [[QredoKeyPair alloc] initWithPublicKey:qpk privateKey:qsk];
    
    NSAssert(kp, @"Expected key pair to be generated.");
    NSAssert([kp.publicKey isMemberOfClass:QredoED25519VerifyKey.class],
             @"Expected Ed25519 public key in generated key pair.");
    NSAssert([kp.privateKey isMemberOfClass:QredoED25519SigningKey.class],
             @"Expected Ed25519 private key in generated key pair.");
    
    return kp;
    
}

+(QredoKeyPair *)ed25519DeriveFromSecretKey:(NSData *)secretKey {
    // This method is only used to support a stepping stone, and will soon vanish.
    NSAssert(secretKey, @"Expected secret key.");
    NSAssert(secretKey.length == crypto_sign_SECRETKEYBYTES,
             @"Expected secret key to be of length %ud.", crypto_sign_SECRETKEYBYTES);
    
    NSMutableData *seed = [NSMutableData dataWithLength:crypto_sign_SEEDBYTES];
    
    int result = crypto_sign_ed25519_sk_to_seed(seed.mutableBytes, secretKey.bytes);
    NSAssert(result == 0, @"Could not turn secret key into seed.");
    
    return [self ed25519Derive:seed];
}

+(NSData *)ed25519Sha512Sign:(NSData *)payload keyPair:(QredoKeyPair *)keyPair {
    
    NSMutableData *signature = [NSMutableData dataWithLength:crypto_sign_BYTES];
    
    crypto_sign_ed25519_detached(
                                 signature.mutableBytes,
                                 NULL,
                                 payload.bytes,
                                 payload.length,
                                 keyPair.privateKey.serialize.bytes);
    
    return signature;
    
}

+(BOOL)ed25519Sha512Verify:(NSData *)payload signature:(NSData *)signature keyPair:(QredoKeyPair *)keyPair {
    return crypto_sign_ed25519_verify_detached(
                                               signature.bytes,
                                               payload.bytes,
                                               payload.length,
                                               keyPair.publicKey.serialize.bytes) == 0;
}

+(NSData *)hkdfSha256Extract:(NSData *)ikm salt:(NSData *)salt {
    
    // Please read https://tools.ietf.org/html/rfc5869 to understand HKDF.
    
    NSAssert(ikm,  @"IKM must be specified.");
    NSAssert(ikm.length > 0, @"IKM must be non-empty.");
    NSAssert(salt, @"Salt must be specified.");
    NSAssert(salt.length > 0, @"Salt must be non-empty.");
    
    NSMutableData *prk = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, salt.bytes, salt.length, ikm.bytes, ikm.length, prk.mutableBytes);
    
    NSAssert(prk.length == CC_SHA256_DIGEST_LENGTH, @"Expected PRK to be SHA256 length.");
    
    return [prk copy];
    
}

+(NSData *)hkdfSha256Expand:(NSData *)prk info:(NSData *)info outputLength:(NSUInteger)outputLength {
    
    // Please read https://tools.ietf.org/html/rfc5869 to understand HKDF.
    
    NSAssert(prk, @"PRK must be specified.");
    NSAssert(prk.length > 0, @"PRK must be non-empty.");
    NSAssert(info, @"Info must be specified.");
    NSAssert(outputLength > 0, @"Output length must be greater than zero.");
    
    uint8_t hashLen = CC_SHA256_DIGEST_LENGTH;
    
    NSUInteger N = ceil((double)outputLength / (double)hashLen);
    uint8_t *T   = alloca(N * hashLen);
    NSAssert(T, @"Could not allocate expansion vector.");
    
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
    
    NSData *okm = [NSData dataWithBytes:T length:outputLength];
    NSAssert(okm.length > 0, @"Expected OKM of non-zero length.");
    NSAssert(okm.length == outputLength, @"Expected OKM to match requested output length.");
    
    return okm;
    
}

+ (NSData *)hmacSha256:(NSData *)data key:(NSData *)key outputLen:(NSUInteger)outputLen {
    
    NSAssert(data,
             @"Expected data.");
    NSAssert(key, @"Expected key.");
    NSAssert(key.length > 0, @"Expected non-zero length key.");
    
    //The MAC size is the same size as the underlying hash function output
    NSMutableData *mac = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,
           key.bytes,
           key.length,
           data.bytes,
           outputLen,
           mac.mutableBytes);
    
    NSAssert(mac.length == CC_SHA256_DIGEST_LENGTH,
             @"Expected hash output of length %d.", CC_SHA256_DIGEST_LENGTH);
    
    return [mac copy];
    
}

+(NSData *)pbkdf2Sha256:(NSData *)ikm
                   salt:(NSData *)salt
           outputLength:(NSUInteger)outputLength
             iterations:(NSUInteger)iterations {
    
    const int PBKDF2_RFC_MIN_SALT_LENGTH = 8;
    
    NSAssert(ikm,
             @"Expected IKM.");
    NSAssert(ikm.length > 0,
             @"Expected IKM of non-zero length.");
    NSAssert(salt,
             @"Expected salt.");
    NSAssert(salt.length >= PBKDF2_RFC_MIN_SALT_LENGTH,
             @"Expected salt of minimum length %d, as recommended by RFC 2898 "
             @"Sec. 4.1.",
             PBKDF2_RFC_MIN_SALT_LENGTH);
    NSAssert(outputLength > 0,
             @"Expected output length greater than zero.");
    NSAssert(iterations > 0,
             @"Expected iteration count greater than 0.");
    NSAssert(iterations < UINT_MAX,
             @"Expected iteration count less than %d.", UINT_MAX);
    
    NSMutableData *derivation = [NSMutableData dataWithLength:outputLength];
    
    int result = CCKeyDerivationPBKDF(
                                      kCCPBKDF2,
                                      ikm.bytes,
                                      ikm.length,
                                      salt.bytes,
                                      salt.length,
                                      kCCPRFHmacAlgSHA256,
                                      (unsigned int)iterations,
                                      derivation.mutableBytes,
                                      derivation.length);
    
    NSAssert(result == kCCSuccess,
             @"CCKeyDerivationPBKDF: failure %d.", result);
    NSAssert(derivation.length == outputLength,
             @"Expected derivation of specified output length %lu.",
             (unsigned long)outputLength);
    
    return derivation;
    
}

#if NEW_CRYPTO_CODE

+(NSData *)rsaPssSha256Sign:(NSData *)payload keyPair:(QredoKeyPair *)keyPair {
    return nil;
}

+(BOOL)rsaPssSha256Verify:(NSData *)payload signature:(NSData *)signature keyPair:(QredoKeyPair *)keyPair {
    return nil;
}

#endif

+(NSData *)secureRandom:(NSUInteger)size {
    NSAssert(size > 0, @"Expected non-zero size.");
    
    uint8_t *bytes = alloca(size);
    int result = SecRandomCopyBytes(kSecRandomDefault, size, bytes);
    
    NSAssert(result == 0, @"Failed to generate %lu secure random bytes.", (unsigned long)size);
    
    return [NSData dataWithBytes:bytes length:size];
}

+(NSData *)sha256:(NSData *)data {
    NSAssert(data, @"Expected data.");
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (unsigned int)data.length, hash.mutableBytes);
    NSAssert(hash.length == CC_SHA256_DIGEST_LENGTH,
             @"Expected output hash of length %d", CC_SHA256_DIGEST_LENGTH);
    return [hash copy];
}

/*****************************************************************************
 * old work
 ****************************************************************************/

+(QredoSecKeyRefPair *)rsaGenerate:(NSInteger)keySize publicKeyIdentifier:(NSString *)publicKeyIdentifier privateKeyIdentifier:(NSString *)privateKeyIdentifier persistInAppleKeychain:(BOOL)persistKeys {
    
    /*
     NOTE: Keys which are not persisted in the keychain can only be used via the
     methods which take a SecKeyRef. You cannot find them with SecItemCopyMatch-
     ing etc. as they're not in the keychain, so you cannot get access to the
     generated key data itself, just the ref to the key.
     */
    const int RSA_RECOMMENDED_KEY_SIZE = 2048;
    
    NSAssert(keySize > 0,
             @"Expected key size greater than 0.");
    QredoAssertWarn(keySize < RSA_RECOMMENDED_KEY_SIZE,
                    @"Generating RSA key < %d bits, which is weaker than expected.",
                    RSA_RECOMMENDED_KEY_SIZE);
    NSAssert(publicKeyIdentifier,
             @"Expected public key identifier.");
    NSAssert(publicKeyIdentifier.length > 0,
             @"Expected non-empty public key identifier.");
    NSAssert(privateKeyIdentifier,
             @"Expected private key identifier.");
    NSAssert(privateKeyIdentifier.length > 0,
             @"Expected non-empty private key identifier.");
    NSAssert(![publicKeyIdentifier isEqualToString:privateKeyIdentifier],
             @"Expected different public and private key identifiers.");
    
    NSDictionary *keyPairAttributes = @{
                                        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                                        (id)kSecAttrKeySizeInBits: @(keySize),
                                        (id)kSecPrivateKeyAttrs: @{
                                                (id)kSecAttrIsPermanent: @(persistKeys),
                                                (id)kSecAttrApplicationTag: [privateKeyIdentifier
                                                                             dataUsingEncoding:NSUTF8StringEncoding]
                                                },
                                        (id)kSecPublicKeyAttrs: @{
                                                (id)kSecAttrIsPermanent: @(persistKeys),
                                                (id)kSecAttrApplicationTag: [publicKeyIdentifier
                                                                             dataUsingEncoding:NSUTF8StringEncoding]
                                                }
                                        };
    
    SecKeyRef publicKeyRef = NULL;
    SecKeyRef privateKeyRef = NULL;
    
    OSStatus status = SecKeyGeneratePair(
                                         (__bridge CFDictionaryRef)keyPairAttributes,
                                         &publicKeyRef,
                                         &privateKeyRef);
    
    NSAssert(status == errSecSuccess,
             @"Failed to generate %ld bit keypair. Public key ID: '%@', "
             "Private key ID: '%@'. Status: %@",
             (long)keySize,
             publicKeyIdentifier,
             privateKeyIdentifier,
             [QredoLogger stringFromOSStatus:status]);
    
    QredoSecKeyRefPair *keyRefPair = [[QredoSecKeyRefPair alloc]
                                      initWithPublicKeyRef:publicKeyRef
                                      privateKeyRef:privateKeyRef];
    
    return keyRefPair;
    
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
    OSStatus result = fixedSecItemCopyMatching((__bridge CFDictionaryRef)queryKey, &keyDataRef);
    
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
