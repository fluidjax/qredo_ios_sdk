/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoKeyPair.h"
#import "QredoTypes.h"
#import "QredoRendezvousHelper.h"
#import "QredoBulkEncKey.h"

@protocol QredoRendezvousHelper;

@interface QredoRendezvousCrypto :NSObject

+(QredoRendezvousCrypto *)instance;

-(QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                        authenticationKey:(QredoKey *)authenticationKey
                                   encryptedResponderData:(NSData *)encryptedResponderData;


-(QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                                 authenticationKey:(QredoKey *)authenticationKey
                                                responderPublicKey:(QredoPublicKey *)responderPublicKey;


-(QLFKeyPairLF *)newECAccessControlKeyPairWithSeed:(NSData *)seed;

-(QLFKeyPairLF *)newRequesterKeyPair;
-(QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair;

-(NSData *)signChallenge:(NSData *)challenge
                 hashtag:(QLFRendezvousHashedTag *)hashtag
                   nonce:(QLFNonce *)nonce
              privateKey:(QredoPrivateKey *)privateKey;

-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKey:(QredoKey *)encryptionKey;

-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKey:(QredoKey *)encryptionKey
                             iv:(NSData *)iv;

-(QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                              encryptionKey:(QredoKey *)encryptionKey
                                                      error:(NSError **)error;

-(BOOL)validateEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
                    authenticationKey:(QredoKey *)authenticationKey
                                  tag:(NSString *)tag
                            hashedTag:(QLFRendezvousHashedTag *)hashedTag
                                error:(NSError **)error;

-(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)fullTag
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error;

-(QredoKey *)masterKeyWithTag:(NSString *)tag appId:(NSString *)appId;
-(QLFRendezvousHashedTag *)hashedTagWithMasterKey:(QredoKey *)masterKey;
-(QredoBulkEncKey *)encryptionKeyWithMasterKey:(QredoKey *)masterKey;
-(QredoKey *)authenticationKeyWithMasterKey:(QredoKey *)masterKey;
+(NSData *)transformPrivateKeyToData:(SecKeyRef)key;

@end
