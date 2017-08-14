#import <CommonCrypto/CommonCrypto.h>
#import "sodium.h"

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


/*****************************************************************************
 * new work
 ****************************************************************************/

#define NEW_CRYPTO_CODE FALSE

+(NSData*)randomNonceAndZeroCounter{
    //Specifically for AES CTR
    //generate a 128bit IV (64bit random nonce + 64bit counter starting at 0)
    //This is required because Apple's implementation rolls over at 64bit boundary, where other implementations rollover at 128bit.
    NSMutableData *iv = [[QredoRawCrypto secureRandom:(kCCBlockSizeAES256/2)] mutableCopy];
    [iv increaseLengthBy:(kCCBlockSizeAES256/2)];
    return [iv copy];
}



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
                                                           ccNoPadding,
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
    [[QredoED25519VerifyKey alloc] initWithData:pk];
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
                                 keyPair.privateKey.bytes.bytes);
    
    return signature;
    
}

+(BOOL)ed25519Sha512Verify:(NSData *)payload signature:(NSData *)signature keyPair:(QredoKeyPair *)keyPair {
    return crypto_sign_ed25519_verify_detached(
                                               signature.bytes,
                                               payload.bytes,
                                               payload.length,
                                               keyPair.publicKey.bytes.bytes) == 0;
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


+(NSData *)sha512:(NSData *)data {
    NSAssert(data, @"Expected data.");
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(data.bytes, (unsigned int)data.length, hash.mutableBytes);
    NSAssert(hash.length == CC_SHA512_DIGEST_LENGTH,
             @"Expected output hash of length %d", CC_SHA512_DIGEST_LENGTH);
    return [hash copy];
}



@end
