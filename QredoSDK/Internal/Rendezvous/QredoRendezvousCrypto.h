/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoTypes.h"
#import "QredoRendezvousHelper.h"
#import "QredoKeyRef.h"
#import "QredoPublicKey.h"
#import "QredoPrivateKey.h"

@protocol QredoRendezvousHelper;

@interface QredoRendezvousCrypto :NSObject

+(QredoRendezvousCrypto *)instance;

-(QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                     authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                   encryptedResponderData:(NSData *)encryptedResponderData;


-(QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                              authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                                responderPublicKey:(QredoPublicKey *)responderPublicKey;


-(QLFKeyPairLF *)newECAccessControlKeyPairWithSeed:(NSData *)seed;

-(QLFKeyPairLF *)newRequesterKeyPair;
//-(QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair;

-(NSData *)signChallenge:(NSData *)challenge
                 hashtag:(QLFRendezvousHashedTag *)hashtag
                   nonce:(QLFNonce *)nonce
              privateKey:(QredoPrivateKey *)privateKey;

-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef;

-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef
                             iv:(NSData *)iv;

-(QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                           encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef
                                                      error:(NSError **)error;

-(BOOL)validateEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
                 authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                  tag:(NSString *)tag
                            hashedTag:(QLFRendezvousHashedTag *)hashedTag
                                error:(NSError **)error;

-(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)fullTag
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error;

-(QredoKeyRef *)masterKeyWithTag:(NSString *)tag appId:(NSString *)appId;

-(QLFRendezvousHashedTag *)hashedTagWithMasterKey:(QredoKeyRef *)masterKey;
-(QredoKeyRef *)encryptionKeyWithMasterKey:(QredoKeyRef *)masterKey;
-(QredoKeyRef *)authenticationKeyWithMasterKey:(QredoKeyRef *)masterKey;

+(NSData *)transformPrivateKeyToData:(SecKeyRef)key;

@end
