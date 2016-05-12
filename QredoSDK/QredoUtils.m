//
//  QredoUtils.m
//  QredoSDK
//
//  Created by Christopher Morris on 10/05/2016.
//
//

#import "QredoUtils.h"
#import "ReadableKeys.h"
#import "sodium.h"


@implementation QredoUtils


+(NSString *)rfc1751Key2Eng:(NSData *)key{
    return [ReadableKeys rfc1751Key2Eng:key];
}

+(NSData *)rfc1751Eng2Key:(NSString *)english{
    return [ReadableKeys rfc1751Eng2Key:english];
}


+(NSData *)eng2Key:(NSString *)english{
    return [ReadableKeys eng2Key:english];
}

+(NSString *)key2Eng:(NSData *)key{
     return [ReadableKeys key2Eng:key];
}




+(NSData *)randomKey:(NSUInteger)size{
    size_t   randomSize  = size;
    uint8_t *randomBytes = alloca(randomSize);
    int result = SecRandomCopyBytes(kSecRandomDefault, randomSize, randomBytes);
    if (result != 0) {
        @throw [NSException exceptionWithName:@"QredoSecureRandomGenerationException"
                                       reason:[NSString stringWithFormat:@"Failed to generate a secure random byte array of size %lu (result: %d)..", (unsigned long)size, result]
                                     userInfo:nil];
    }
    NSData *ret = [NSData dataWithBytes:randomBytes length:randomSize];
    return ret;
    
}


+(NSString*)dataToHexString:(NSData*)data{
    if (!data)return nil;
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    for (int i=0; i<data.length; i++) {
        [sbuf appendFormat:@"%02X", (unsigned int)buf[i]];
    }
    return [sbuf copy];
}


+(NSData *)hexStringToData:(NSString *)hexString{
    // Taken from http://stackoverflow.com/questions/7317860/converting-hex-nsstring-to-nsdata
    NSString *command = [[hexString stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    
    if (command.length %2 != 0){
        NSLog(@"invalid hex string length");
        return nil;
    }
    
    NSMutableData *commandToSend = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [command length]/2; i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    
    return [NSData dataWithData:commandToSend];
}

+(NSData*)randomBytesOfLength:(NSUInteger)size{
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: size];
    for (unsigned int i = 0; i < size; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    }
    return mutableData;
}

@end








@interface QredoSecureChannel ()

@property (strong) NSMutableData *localPublicKeyData;
@property (strong) NSMutableData *localPrivateKeyData;
@property (strong) NSData *remotePublicKeyData;
@property (strong) NSData *encryptionKey;

@end


@implementation QredoSecureChannel


- (instancetype)init{
    self = [super init];
    if (self) {
        self.localPublicKeyData = nil;
        self.localPrivateKeyData = nil;
    }
    return self;
}


-(NSString*)publicKey{
    if (self.localPublicKeyData)return [self dataToHexString:[self.localPublicKeyData copy]];
    self.localPublicKeyData = [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    self.localPrivateKeyData= [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    crypto_box_keypair(self.localPublicKeyData.mutableBytes, self.localPrivateKeyData.mutableBytes);
    return [self dataToHexString:[self.localPublicKeyData copy]];
}


-(NSString*)remotePublicKey{
    return [self dataToHexString:self.remotePublicKeyData];
}


-(void)setRemotePublicKey:(NSString*)key{
    self.remotePublicKeyData = [QredoUtils hexStringToData:key];
    self.encryptionKey = nil;
    
}


-(void)buildEncryptionKey{
    int SCALAR_MULT_RESULT_LENGTH = 32;
    NSMutableData *scalarMult = [[NSMutableData alloc] initWithLength:SCALAR_MULT_RESULT_LENGTH];
    crypto_scalarmult_curve25519(scalarMult.mutableBytes, self.localPrivateKeyData.bytes, self.remotePublicKeyData.bytes);
    NSMutableData *sKey = [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    crypto_hash_sha256(sKey.mutableBytes, scalarMult.bytes, crypto_box_SECRETKEYBYTES);
    self.encryptionKey =[sKey copy];
}




-(NSString*)encryptString:(NSString*)message{
    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *result = [self encrypt:messageData];
    return [self dataToHexString:result];
}




-(NSData*)encrypt:(NSData*)message{
    if (!self.encryptionKey)[self buildEncryptionKey];
    NSMutableData *nonce = [[NSMutableData alloc] initWithLength:crypto_secretbox_NONCEBYTES];
    randombytes(nonce.mutableBytes, crypto_secretbox_NONCEBYTES);
    NSMutableData *cipherText = [[NSMutableData alloc] initWithLength:crypto_secretbox_MACBYTES+message.length];
    int result = crypto_box_easy(cipherText.mutableBytes, message.bytes, message.length, nonce.bytes, self.encryptionKey.bytes,self.encryptionKey.bytes);
    NSMutableData *noncePlusCipherText = [[NSMutableData alloc] init];
    [noncePlusCipherText appendData:nonce];
    [noncePlusCipherText appendData:cipherText];
    if (result==0)return noncePlusCipherText;
    return nil;
}


-(NSString*)decryptString:(NSString*)cipherText{
    //Wrapper for the NSData decryption
    //Converts NSData into Hex strings
    
    NSData *cipherData = [QredoUtils hexStringToData:cipherText];
    NSData *result = [self decrypt:cipherData];
    return [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding];
}


-(NSData*)decrypt:(NSData*)cipherData{
    if (!self.encryptionKey)[self buildEncryptionKey];
    NSData *nonce = [cipherData subdataWithRange:NSMakeRange(0, crypto_secretbox_NONCEBYTES)];
    NSData *cipherDataOnly = [cipherData subdataWithRange:NSMakeRange(crypto_secretbox_NONCEBYTES, cipherData.length-crypto_secretbox_NONCEBYTES)];
    NSMutableData *decryptedMessage = [[NSMutableData alloc] initWithLength:cipherDataOnly.length-crypto_secretbox_MACBYTES];
    int result = crypto_box_open_easy(decryptedMessage.mutableBytes, cipherDataOnly.bytes, cipherDataOnly.length, nonce.bytes, self.encryptionKey.bytes,self.encryptionKey.bytes);
    if (result==0)return decryptedMessage;
    return nil;
}



//General Utils

-(NSString*)dataToHexString:(NSData*)data{
    if (!data)return nil;
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    for (int i=0; i<data.length; i++) {
        [sbuf appendFormat:@"%02X", (unsigned int)buf[i]];
    }
    return [sbuf copy];
}

@end

