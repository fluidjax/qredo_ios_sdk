#import <CommonCrypto/CommonCrypto.h>
#import "sodium.h"
#import "CryptoImplV1.h"
#import "QredoCrypto.h"
#import "QredoEllipticCurvePoint.h"
#import "MasterConfig.h"

@implementation CryptoImplV1

#define HMAC_SIZE_IN_BYTES              CC_SHA256_DIGEST_LENGTH
#define BULK_KEY_SIZE_IN_BYTES          kCCKeySizeAES256
#define PBKDF2_ITERATION_COUNT          10000
#define PBKDF2_DERIVED_KEY_LENGTH_BYTES 32
#define PASSWORD_ENCODING_FOR_PBKDF2    NSUTF8StringEncoding

-(instancetype)init {
    self = [super init];
    int result = sodium_init();
    NSAssert(result >= 0, @"Could not initialize libsodium.");
    return self;
}


+(instancetype)sharedInstance {
    static CryptoImplV1 *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        instance = [[self alloc] init];
    });
    return instance;
}


//This method will encrypt the data with a random IV using AES and prepend the IV onto the result
-(NSData *)encryptWithKey:(NSData *)secretKey data:(NSData *)data {
    //Generate a random IV of the correct length for AES
    NSData *iv = [QredoCrypto secureRandom:kCCBlockSizeAES128];
    
    return [self encryptWithKey:secretKey data:data iv:iv];
}


-(NSData *)encryptWithKey:(NSData *)secretKey data:(NSData *)data iv:(NSData *)iv {
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

    NSData *encryptedData = [QredoCrypto aes256CtrEncrypt:data key:secretKey iv:iv];

    NSMutableData *ivAndEncryptedData = nil;
    
    if (encryptedData != nil){
        //Prepend the IV onto the start of the encrypted data, so the receiver knows the random IV
        ivAndEncryptedData = [NSMutableData dataWithData:iv];
        [ivAndEncryptedData appendData:encryptedData];
    }
    
    return ivAndEncryptedData;
}


//This method will decrypt the data using AES and an IV which should be present at start of encrypted data
-(NSData *)decryptWithKey:(NSData *)secretKey data:(NSData *)data {
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
    
    //Data should be IV plus encrypted data
    //However CTR allows 0 length data blocks, so minimum size is IV (1 block length)
    if (data.length < kCCBlockSizeAES128){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is too short. Must be at least 1 blocks long (%d bytes) for IV and encrypted data.", kCCBlockSizeAES128]
                                     userInfo:nil];
    }
    
    NSUInteger ivLength = kCCBlockSizeAES128;
    
    //Extract the IV from the start of the data
    NSRange ivRange = NSMakeRange(0,ivLength);
    NSData *iv = [data subdataWithRange:ivRange];
    
    //Extract the encrypted data (strip off IV)
    NSRange encryptedDataRange = NSMakeRange(ivLength,data.length - ivLength);
    NSData *dataToDecrypt = [data subdataWithRange:encryptedDataRange];
    
    NSData *decryptedData = [QredoCrypto aes256CtrDecrypt:dataToDecrypt key:secretKey iv:iv];
    
    return decryptedData;
}


-(NSData *)getAuthCodeWithKey:(NSData *)authKey data:(NSData *)data {
    //Any validation checks are performed by variant with length argument
    return [self getAuthCodeWithKey:authKey data:data length:data.length];
}


-(NSData *)getAuthCodeWithKey:(NSData *)authKey data:(NSData *)data length:(NSUInteger)length {
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
    
    NSData *authCode = [QredoCrypto generateHmacSha256ForData:data length:length key:authKey];
    
    return authCode;
}


-(NSData *)getAuthCodeZero {
    static NSData *zeroData = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,^{
        zeroData = [[NSMutableData dataWithLength:HMAC_SIZE_IN_BYTES] copy];
    });
    return zeroData;
}


-(BOOL)verifyAuthCodeWithKey:(NSData *)authKey data:(NSData *)data {
    //This method expects the MAC to be appended onto the end of the data. Therefore
    //data argument must be provided, and at least MAC length.
    
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    if (data.length < HMAC_SIZE_IN_BYTES){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data length (%lu) is invalid. Must be at least %d bytes.",(unsigned long)data.length,HMAC_SIZE_IN_BYTES]
                                     userInfo:nil];
    }
    
    //Split up the data and MAC and then pass to other verify method for verification
    
    NSRange macRange = NSMakeRange(data.length - HMAC_SIZE_IN_BYTES,HMAC_SIZE_IN_BYTES);
    NSData *mac = [data subdataWithRange:macRange];
    
    NSRange dataRange = NSMakeRange(0,data.length - HMAC_SIZE_IN_BYTES);
    NSData *dataToMac = [data subdataWithRange:dataRange];
    
    BOOL macCorrect = [self verifyAuthCodeWithKey:authKey data:dataToMac mac:mac];
    
    return macCorrect;
}


-(BOOL)verifyAuthCodeWithKey:(NSData *)authKey data:(NSData *)data mac:(NSData *)mac {
    //Perfectly valid to have empty key and empty data, but must not be nil. MAC must be present + valid
    
    if (!mac){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Mac argument is nil"]
                                     userInfo:nil];
    }
    
    if (mac.length != HMAC_SIZE_IN_BYTES){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Mac length (%lu) is invalid. Must be %d bytes.",(unsigned long)mac.length,HMAC_SIZE_IN_BYTES]
                                     userInfo:nil];
    }
    
    //Generate the HMAC and compare to provided value (using constant time comparison function)
    NSData *generatedHmac = [QredoCrypto generateHmacSha256ForData:data length:data.length key:authKey];
    
    BOOL macCorrect = [QredoCrypto constantEquals:generatedHmac rhs:mac];
    
    return macCorrect;
}


-(NSData *)getRandomKey {
    NSData *randomKey = [QredoCrypto secureRandom:BULK_KEY_SIZE_IN_BYTES];
    
    return randomKey;
}

-(NSData *)getPasswordBasedKeyWithSalt:(NSData *)salt password:(NSString *)password {
    NSData *passwordData = [password dataUsingEncoding:PASSWORD_ENCODING_FOR_PBKDF2];
    
    NSData *key = [QredoCrypto pbkdf2Sha256:passwordData salt:salt outputLen:PBKDF2_DERIVED_KEY_LENGTH_BYTES iterations:PBKDF2_ITERATION_COUNT];
    
    return key;
}


-(NSData *)getDiffieHellmanMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                       yourPublicKey:(QredoDhPublicKey *)yourPublicKey {
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
    return dh.data;
}


-(NSData *)getDiffieHellmanSecretWithSalt:(NSData *)salt myPrivateKey:(QredoDhPrivateKey *)myPrivateKey yourPublicKey:(QredoDhPublicKey *)yourPublicKey {
    NSData *ikm = [self getDiffieHellmanMasterKeyWithMyPrivateKey:myPrivateKey yourPublicKey:yourPublicKey];
    
    //HKDF using SHA-256
    NSData *prk = [QredoCrypto hkdfSha256Extract:ikm salt:salt];
    NSData *okm = [QredoCrypto hkdfSha256Expand:prk info:nil outputLength:CC_SHA256_DIGEST_LENGTH];
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

-(QredoKeyPair *)qredoED25519KeyPairWithSeed:(NSData *)seed {
    return [QredoCrypto ed25519Derive:seed];
}

-(NSData *)qredoED25519SignMessage:(NSData *)message withKey:(QredoED25519SigningKey *)sk error:(NSError **)error {
    // This code is a temporary stepping stone towards fixing this layer correctly.
    QredoKeyPair *keyPair = [QredoCrypto ed25519DeriveFromSecretKey:sk.serialize];
    return [QredoCrypto ed25519Sha512Sign:message keyPair:keyPair];
}

@end
