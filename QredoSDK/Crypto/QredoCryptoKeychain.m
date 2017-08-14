//
//  QredoCryptoKeychain.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import "QredoCryptoKeychain.h"
#import "QredoKey.h"
#import "Qredo.h"
#import "QredoAESKey.h"

#import "QredoKeyRef.h"
#import "QredoKeyRefPair.h"

#import "UICKeyChainStore.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoImpl.h"
#import "QredoRawCrypto.h"


@interface QredoCryptoKeychain()
@property (strong) UICKeyChainStore *keychainWrapper;
@property (strong) QredoCryptoImplV1 *cryptoImplementation;

@end

@implementation QredoCryptoKeychain



#pragma Public


-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext{
    QredoAESKey *secretKey = [[QredoAESKey alloc] initWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation encryptBulk:secretKey plaintext:plaintext];
}

-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext{
    QredoAESKey *secretKey = [[QredoAESKey alloc] initWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation decryptBulk:secretKey ciphertext:ciphertext];
}

-(NSData *)authenticate:(QredoKeyRef *)secretKeyRef data:(NSData *)data{
    QredoKey *secretKey = [[QredoKey alloc] initWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation getAuthCodeWithKey:secretKey data:data];
}

-(BOOL)verify:(QredoKeyRef *)secretKeyRef data:(NSData *)data signature:(NSData *)signature{
    QredoKey *secretKey = [[QredoKey alloc] initWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation verifyAuthCodeWithKey:secretKey data:data mac:signature];
    
}

-(QredoKeyRef *)deriveKey:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info{
    return nil;
}

-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt{
    return nil;
}

-(QredoKeyPairRef *)derivePasswordKeyPair:(NSData *)password salt:(NSData *)salt{
    return nil;
}

-(QredoKeyRefPair *)ownershipKeyPairDerive:(NSData *)ikm{
    //ed25519_sha512_derive
    QredoED25519SigningKey *signKey = [self.cryptoImplementation qredoED25519SigningKeyWithSeed:ikm];
    QredoKey *private = [[QredoKey alloc] initWithData:signKey.data];
    QredoKey *public  = [[QredoKey alloc] initWithData:signKey.verifyKey.data];
    
    QredoKeyRefPair *keyRefPair = [[QredoKeyRefPair alloc] initWithPublic:public private:private];
    return keyRefPair;
}


-(NSData *)ownershipSign:(QredoKeyPairRef *)keyPairRef data:(NSData *)data{
//   QredoED25519SigningKey *signingKey = [[QredoED25519SigningKey alloc] init];
//   NSData *sig = [self.cryptoImplementation qredoED25519SignMessage:data withKey:signingKey error:error];
    return nil;
            
    
    
    
}




#pragma Initialization

+(instancetype)sharedQredoCryptoKeychain{
    static id sharedQredoCryptoKeychainInstance = nil;
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        sharedQredoCryptoKeychainInstance = [[self alloc] init];
        
        
        
        
    });
    return sharedQredoCryptoKeychainInstance;
}


- (instancetype)init{
    self = [super init];
    if (self) {
        _keychainWrapper = [UICKeyChainStore keyChainStoreWithService:@"Qredo.Crypto"];
        _cryptoImplementation = [QredoCryptoImplV1 sharedInstance];
    }
    return self;
}





#pragma Keychain


-(QredoKeyRef*)makeKeyRef{
    QredoQUID *quid = [[QredoQUID alloc] init];
    return [[QredoKeyRef alloc] initWithData:[quid data]];
}

-(void)store:(QredoKey *)data withRef:(QredoKeyRef *)ref{
    [self.keychainWrapper setData:[data bytes] forKey:[ref hexadecimalString]];
}



-(NSData*)retrieveWithRef:(QredoKeyRef*)ref{
    return [self.keychainWrapper dataForKey:[ref hexadecimalString]];
}



@end
