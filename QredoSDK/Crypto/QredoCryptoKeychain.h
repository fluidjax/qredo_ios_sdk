//
//  QredoCryptoKeychain.h
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//  Within General Qredo Code, only Key Refrences are passed, the actual mapping of Refs->KeyData takes place here
//

@class QredoKey;
@class QredoKeyRef;
@class QredoKeyPairRef;
@class QredoQUID;

#import <Foundation/Foundation.h>


@interface QredoCryptoKeychain : NSObject

+(instancetype)sharedQredoCryptoKeychain;
-(QredoKeyRef*)createKeyRef:(QredoKey*)key;
-(NSData*)retrieveWithRef:(QredoKeyRef *)ref;
//-(QredoKeyRef*)makeKeyRef;
//-(void)store:(QredoKey *)data withRef:(QredoKeyRef *)ref;



-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext;
-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext;
-(NSData *)authenticate:(QredoKeyRef *)secretKeyRef data:(NSData *)data;
-(BOOL)verify:(QredoKeyRef *)secretKeyRef data:(NSData *)data signature:(NSData *)signature;
-(QredoKeyRef *)deriveKeyRef:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info;
-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt;
-(QredoKeyPairRef *)derivePasswordKeyPair:(NSData *)password salt:(NSData *)salt;
-(QredoKeyPairRef *)ownershipKeyPairDerive:(NSData *)ikm;
-(NSData *)ownershipSign:(QredoKeyPairRef *)keyPairRef data:(NSData *)data;

-(QredoQUID*)keyRefToQUID:(QredoKeyRef*)keyRef;


-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToKeyRef:(QredoKeyRef*)keyRef2;
-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToData:(NSData*)data;


@end
