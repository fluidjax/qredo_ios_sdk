/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoUtils.h"
#import "sodium.h"


@interface QredoSecureChannel ()

@property (strong) NSMutableData *localPublicKeyData;
@property (strong) NSMutableData *localPrivateKeyData;
@property (strong) NSData *remotePublicKeyData;
@property (strong) NSData *encryptionKey;

@end


@implementation QredoSecureChannel


-(instancetype)init {
    self = [super init];
    
    if (self){
        _localPublicKeyData = nil;
        _localPrivateKeyData = nil;
    }
    
    return self;
}


-(NSString *)publicKey {
    if (self.localPublicKeyData)return [QredoUtils dataToHexString:[self.localPublicKeyData copy]];
    
    //generate public/prvate keypair keys and return public key
    self.localPublicKeyData = [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    self.localPrivateKeyData = [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    crypto_box_keypair(self.localPublicKeyData.mutableBytes,self.localPrivateKeyData.mutableBytes);
    return [QredoUtils dataToHexString:[self.localPublicKeyData copy]];
}


-(NSString *)remotePublicKey {
    //return the remote public key
    return [QredoUtils dataToHexString:self.remotePublicKeyData];
}


-(void)setRemotePublicKey:(NSString *)key {
    //set the remote public key
    self.remotePublicKeyData = [QredoUtils hexStringToData:key];
    self.encryptionKey = nil;
}


-(void)buildEncryptionKey {
    //build the AES symmetric encryption key from local Private & remote Public
    
    int SCALAR_MULT_RESULT_LENGTH = 32;
    NSMutableData *scalarMult = [[NSMutableData alloc] initWithLength:SCALAR_MULT_RESULT_LENGTH];
    
    crypto_scalarmult_curve25519(scalarMult.mutableBytes,self.localPrivateKeyData.bytes,self.remotePublicKeyData.bytes);
    NSMutableData *sKey = [[NSMutableData alloc] initWithLength:crypto_box_SECRETKEYBYTES];
    crypto_hash_sha256(sKey.mutableBytes,scalarMult.bytes,crypto_box_SECRETKEYBYTES);
    self.encryptionKey = [sKey copy];
}


-(NSString *)encryptString:(NSString *)message {
    //wrapper to encrypt a string
    
    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *result = [self encrypt:messageData];
    
    return [QredoUtils dataToHexString:result];
}


-(NSData *)encrypt:(NSData *)message {
    //build the AES encryption key if not already built
    if (!self.encryptionKey)[self buildEncryptionKey];
    
    //create a random nonce
    NSMutableData *nonce = [[NSMutableData alloc] initWithLength:crypto_secretbox_NONCEBYTES];
    randombytes(nonce.mutableBytes,crypto_secretbox_NONCEBYTES);
    
    
    NSMutableData *cipherText = [[NSMutableData alloc] initWithLength:crypto_secretbox_MACBYTES + message.length];
    
    //encrypt the message
    int result = crypto_box_easy(cipherText.mutableBytes,message.bytes,message.length,nonce.bytes,self.encryptionKey.bytes,self.encryptionKey.bytes);
    NSMutableData *noncePlusCipherText = [[NSMutableData alloc] init];
    [noncePlusCipherText appendData:nonce];
    [noncePlusCipherText appendData:cipherText];
    
    //append the nonce to the cipher text
    if (result == 0)return noncePlusCipherText;
    
    return nil;
}


-(NSString *)decryptString:(NSString *)cipherText {
    //Wrapper for the NSData decryption
    //Converts NSData into Hex strings
    
    NSData *cipherData = [QredoUtils hexStringToData:cipherText];
    NSData *result = [self decrypt:cipherData];
    
    return [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding];
}


-(NSData *)decrypt:(NSData *)cipherData {
    //build the AES  key if not already built
    if (!self.encryptionKey)[self buildEncryptionKey];
    
    //remove the nonce from the front of the cipherData
    NSData *nonce = [cipherData subdataWithRange:NSMakeRange(0,crypto_secretbox_NONCEBYTES)];
    NSData *cipherDataOnly = [cipherData subdataWithRange:NSMakeRange(crypto_secretbox_NONCEBYTES,cipherData.length - crypto_secretbox_NONCEBYTES)];
    
    //decrypt the cipher text (without the nonce), using the AES key & nonce
    NSMutableData *decryptedMessage = [[NSMutableData alloc] initWithLength:cipherDataOnly.length - crypto_secretbox_MACBYTES];
    int result = crypto_box_open_easy(decryptedMessage.mutableBytes,cipherDataOnly.bytes,cipherDataOnly.length,nonce.bytes,self.encryptionKey.bytes,self.encryptionKey.bytes);
    
    if (result == 0)return decryptedMessage;
    
    return nil;
}


@end
