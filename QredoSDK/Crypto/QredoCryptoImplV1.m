#import <CommonCrypto/CommonCrypto.h>
#import "sodium.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoRaw.h"
#import "QredoEllipticCurvePoint.h"
#import "MasterConfig.h"

@implementation QredoCryptoImplV1





-(instancetype)init {
    self = [super init];
    int result = sodium_init();
    NSAssert(result >= 0, @"Could not initialize libsodium.");
    return self;
}


+(instancetype)sharedInstance {
    static QredoCryptoImplV1 *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        instance = [[self alloc] init];
    });
    return instance;
}


//This method will encrypt the data with a random IV using AES and prepend the IV onto the result
-(NSData *)encryptBulk:(QredoBulkEncKey *)secretKey plaintext:(NSData *)plaintext{
    //Generate a random IV of the correct length for AES
    NSData *iv = [QredoCryptoRaw randomNonceAndZeroCounter];
    return [self encryptBulk:secretKey plaintext:plaintext iv:iv];
}


-(NSData *)encryptBulk:(QredoBulkEncKey *)secretKey plaintext:(NSData *)data iv:(NSData *)iv {
    if (!iv){
        iv = [QredoCryptoRaw randomNonceAndZeroCounter];
    }
    if (!secretKey){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"SecretKey argument is nil"]
                                     userInfo:nil];
    }
    
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    NSData *encryptedData = [QredoCryptoRaw aes256CtrEncrypt:data key:secretKey.bytes  iv:iv];
    NSMutableData *ivAndEncryptedData = nil;
    
    if (encryptedData != nil){
        //Prepend the IV onto the start of the encrypted data, so the receiver knows the random IV
        ivAndEncryptedData = [NSMutableData dataWithData:iv];
        [ivAndEncryptedData appendData:encryptedData];
    }
    return ivAndEncryptedData;
}




//This method will decrypt the data using AES and an IV which should be present at start of encrypted data
-(NSData *)decryptBulk:(QredoBulkEncKey *)secretKey  ciphertext:(NSData *)ciphertext{
    if (!secretKey){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"SecretKey argument is nil"]
                                     userInfo:nil];
    }
    
    if (!ciphertext){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    //Data should be IV plus encrypted data
    //However CTR allows 0 length data blocks, so minimum size is IV (1 block length)
    if (ciphertext.length < kCCBlockSizeAES256){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is too short. Must be at least 1 blocks long (%d bytes) for IV and encrypted data.", kCCBlockSizeAES256]
                                     userInfo:nil];
    }
    
    NSUInteger ivLength = kCCBlockSizeAES256;
    
    //Extract the IV from the start of the data
    NSRange ivRange = NSMakeRange(0,ivLength);
    NSData *iv = [ciphertext subdataWithRange:ivRange];
    
    //Extract the encrypted data (strip off IV)
    NSRange encryptedDataRange = NSMakeRange(ivLength,ciphertext.length - ivLength);
    NSData *dataToDecrypt = [ciphertext subdataWithRange:encryptedDataRange];
    
    NSData *decryptedData = [QredoCryptoRaw aes256CtrDecrypt:dataToDecrypt key:secretKey.bytes iv:iv];
    return decryptedData;
}


-(NSData *)getAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data {
    //Any validation checks are performed by variant with length argument
    return [self getAuthCodeWithKey:authKey data:data length:data.length];
}


-(NSData *)getAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data length:(NSUInteger)length {
    //Perfectly valid to have empty key and empty data, but must not be nil and length must must be valid
    
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    if (length > data.length){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Length argument (%lu) exceeds data length (%lu)",(unsigned long)length,(unsigned long)data.length]
                                     userInfo:nil];
    }
    
    if (!authKey){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Auth key argument is nil"]
                                     userInfo:nil];
    }
    
    NSData *authCode = [QredoCryptoRaw hmacSha256:data key:authKey.bytes outputLen:length];
    
    return authCode;
}


-(NSData *)getAuthCodeZero {
    static NSData *zeroData = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,^{
        zeroData = [[NSMutableData dataWithLength:HMAC_SIZE] copy];
    });
    return zeroData;
}


-(BOOL)verifyAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data {
    //This method expects the MAC to be appended onto the end of the data. Therefore
    //data argument must be provided, and at least MAC length.
    
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    if (data.length < HMAC_SIZE){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data length (%lu) is invalid. Must be at least %d bytes.",(unsigned long)data.length,HMAC_SIZE]
                                     userInfo:nil];
    }
    
    //Split up the data and MAC and then pass to other verify method for verification
    
    NSRange macRange = NSMakeRange(data.length - HMAC_SIZE,HMAC_SIZE);
    NSData *mac = [data subdataWithRange:macRange];
    
    NSRange dataRange = NSMakeRange(0,data.length - HMAC_SIZE);
    NSData *dataToMac = [data subdataWithRange:dataRange];
    
    BOOL macCorrect = [self verifyAuthCodeWithKey:authKey data:dataToMac mac:mac];
    
    return macCorrect;
}


-(BOOL)verifyAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data mac:(NSData *)mac {
    //Perfectly valid to have empty key and empty data, but must not be nil. MAC must be present + valid
    
    if (!mac){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Mac argument is nil"]
                                     userInfo:nil];
    }
    
    if (mac.length != HMAC_SIZE){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Mac length (%lu) is invalid. Must be %d bytes.",(unsigned long)mac.length,HMAC_SIZE]
                                     userInfo:nil];
    }
    
    //Generate the HMAC and compare to provided value (using constant time comparison function)
    NSData *generatedHmac = [QredoCryptoRaw hmacSha256:data key:authKey.bytes outputLen:data.length];
    
    BOOL macCorrect = [QredoCryptoRaw constantEquals:generatedHmac rhs:mac];
    
    return macCorrect;
}


-(QredoKey *)generateRandomKey {
    NSData *randomKey = [QredoCryptoRaw secureRandom:BULK_KEY_SIZE];
    return [[QredoKey alloc] initWithData:randomKey];
}

-(NSData *)generatePasswordBasedKeyWithSalt:(NSData *)salt password:(NSString *)password {
    NSData *passwordData = [password dataUsingEncoding:PASSWORD_ENCODING_FOR_PBKDF2];
    
    NSData *key = [QredoCryptoRaw pbkdf2Sha256:passwordData salt:salt outputLength:PBKDF2_DERIVED_KEY_SIZE iterations:PBKDF2_ITERATION_COUNT];
    
    return key;
}


-(QredoKey *)generateDiffieHellmanMasterKeyWithMyPrivateKey:(QredoKey *)myPrivateKey
                                         yourPublicKey:(QredoKey *)yourPublicKey {
    if (!myPrivateKey){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Private key argument is nil"]
                                     userInfo:nil];
    }
    
    if (!yourPublicKey){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Public key argument is nil"]
                                     userInfo:nil];
    }
    
    //Note: Salt is optional in HKDF
    
    /*
     * https://github.com/Qredo/design-docs/wiki/Rendezvous-Cryptography
     * Generate DH using EC255/19
     * HKDF using SHA-256
     * Resulting sequence will be 32 bytes (256 bits)
     */
    
    //Generated DH using EC255/19
    QredoEllipticCurvePoint *sk = [QredoEllipticCurvePoint pointWithData:yourPublicKey.data];
    QredoEllipticCurvePoint *dh = [sk multiplyWithPoint:[QredoEllipticCurvePoint pointWithData:myPrivateKey.data]];
    return [[QredoKey alloc]  initWithData:dh.data];
}


-(NSData *)generateDiffieHellmanSecretWithSalt:(NSData *)salt myPrivateKey:(QredoDhPrivateKey *)myPrivateKey yourPublicKey:(QredoDhPublicKey *)yourPublicKey {
    QredoKey *ikm = [self generateDiffieHellmanMasterKeyWithMyPrivateKey:myPrivateKey yourPublicKey:yourPublicKey];
    
    //HKDF using SHA-256
    NSData *prk = [QredoCryptoRaw hkdfSha256Extract:ikm.bytes salt:salt];
    NSData *okm = [QredoCryptoRaw hkdfSha256Expand:prk info:[[NSData alloc] init] outputLength:SHA256_DIGEST_SIZE];
    NSData *diffieHellmanSecretData = okm;
    
    return diffieHellmanSecretData;
}


-(QredoKeyPair *)generateDHKeyPair {
    //Generate a new key pair from curve 25519.
    NSMutableData *publicKeyData = [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    NSMutableData *privateKeyData = [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    crypto_box_keypair(publicKeyData.mutableBytes,privateKeyData.mutableBytes);
    QredoDhPublicKey *publicKey = [[QredoDhPublicKey alloc] initWithData:publicKeyData];
    QredoDhPrivateKey *privateKey = [[QredoDhPrivateKey alloc] initWithData:privateKeyData];
    QredoKeyPair *keyPair = [[QredoKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey];
    return keyPair;
}
    

-(QredoED25519SigningKey *)qredoED25519SigningKeyWithSeed:(NSData *)seed {
    NSAssert([seed length] == ED25519_SEED_SIZE,@"Malformed seed");
    NSMutableData *skData = [NSMutableData dataWithLength:ED25519_SIGNING_KEY_SIZE];
    NSMutableData *vkData = [NSMutableData dataWithLength:ED25519_VERIFY_KEY_SIZE];
    crypto_sign_ed25519_seed_keypair(vkData.mutableBytes,skData.mutableBytes,seed.bytes);
    QredoED25519VerifyKey *vk = [self qredoED25519VerifyKeyWithData:[vkData copy] error:nil];
    NSAssert(vk,@"Could not create verification key.");
    
    if (!vk){
        return nil;
    }
    return [[QredoED25519SigningKey alloc] initWithSignKeyData:skData verifyKey:vk];
}


-(QredoED25519VerifyKey *)qredoED25519VerifyKeyWithData:(NSData *)data error:(NSError **)error {
    NSAssert([data length] == ED25519_VERIFY_KEY_SIZE, @"Invalid ED25519 Verfiy key length");
    return [[QredoED25519VerifyKey alloc] initWithData:data];
}



-(NSData *)qredoED25519SignMessage:(NSData *)message withKey:(QredoED25519SigningKey *)sk error:(NSError **)error {
    GUARD(sk, @"Signing key is required for signing");
    NSAssert([message length]>=1,@"message is 0 bytes");
    NSMutableData *signature    = [NSMutableData dataWithLength:ED25519_SIGNATURE_SIZE];
    
    crypto_sign_ed25519_detached([signature mutableBytes],
                                 nil,
                                 message.bytes,
                                 [message length],
                                 sk.data.bytes);
    return [signature copy];
}



-(QredoKey *)deriveSlow:(NSData *)ikm salt:(NSData *)salt iterations:(int)iterations{
   NSData *key =  [QredoCryptoRaw pbkdf2Sha256:ikm salt:salt outputLength:32 iterations:iterations];
   return [[QredoKey alloc] initWithData:key];
}


-(QredoKey *)deriveFast:(NSData *)ikm salt:(NSData *)salt info:(NSData *)info outputLength:(int)length{
    NSData *prk = [QredoCryptoRaw hkdfSha256Extract:ikm
                                               salt:salt];
    NSData *key = [QredoCryptoRaw hkdfSha256Expand:prk
                                                        info:info
                                                outputLength:length];
   return [[QredoKey alloc] initWithData:key];
}











@end
