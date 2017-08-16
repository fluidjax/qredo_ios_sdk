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
#import "QredoBulkEncKey.h"

#import "QredoKeyRef.h"
#import "QredoKeyRefPair.h"

#import "UICKeyChainStore.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoImpl.h"
#import "QredoRawCrypto.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"

@interface QredoCryptoKeychain()
@property (strong) UICKeyChainStore *keychainWrapper;
@property (strong) QredoCryptoImplV1 *cryptoImplementation;

@end

@implementation QredoCryptoKeychain



#pragma Public


-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext{
    QredoBulkEncKey *secretKey = [[QredoBulkEncKey alloc] initWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation encryptBulk:secretKey plaintext:plaintext];
}

-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext{
    QredoBulkEncKey *secretKey = [[QredoBulkEncKey alloc] initWithData:[self retrieveWithRef:secretKeyRef]];
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

-(QredoKeyRef *)deriveKeyRef:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info{
    //derive_fast HKDF
    NSData *ikm = [self retrieveWithRef:keyRef];
    
    NSAssert(ikm,@"DeriveKey key should not be nil");
    NSAssert(salt,@"Salt should not be nil");
    QredoKey *derivedKey = [self.cryptoImplementation deriveFast:ikm salt:salt info:info];
    return [self createKeyRef:derivedKey];
}

-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt{
    //derive_slow PBKDF
    QredoKey *derivedKey = [self.cryptoImplementation deriveSlow:password  salt:salt iterations:10000];
    return [self createKeyRef:derivedKey];
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


-(QredoQUID*)keyRefToQUID:(QredoKeyRef*)keyRef{
   NSData *keyData = [self retrieveWithRef:keyRef];
   return [[QredoQUID alloc] initWithQUIDData:keyData];
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



-(QredoKeyRef*)createKeyRef:(QredoKey*)key{
    QredoQUID *quid = [[QredoQUID alloc] init];
    QredoKeyRef *keyRef = [[QredoKeyRef alloc] initWithData:[quid data]];
    [self.keychainWrapper setData:[key bytes] forKey:[keyRef hexadecimalString]];
    return keyRef;
   
}

//-(QredoKeyRef*)makeKeyRef{
//    QredoQUID *quid = [[QredoQUID alloc] init];
//    return [[QredoKeyRef alloc] initWithData:[quid data]];
//}
//
//-(void)store:(QredoKey *)data withRef:(QredoKeyRef *)ref{
//    [self.keychainWrapper setData:[data bytes] forKey:[ref hexadecimalString]];
//}



-(NSData*)retrieveWithRef:(QredoKeyRef*)ref{
    return [self.keychainWrapper dataForKey:[ref hexadecimalString]];
}



-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToKeyRef:(QredoKeyRef*)keyRef2{
    NSData *key1 = [self retrieveWithRef:keyRef1];
    NSData *key2 = [self retrieveWithRef:keyRef2];
    return [key1 isEqual:key2];
}


-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToData:(NSData*)data{
    NSData *key1 = [self retrieveWithRef:keyRef1];
    return [key1 isEqual:data];
}


@end
