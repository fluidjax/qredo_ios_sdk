/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoKeyPair.h"
#import "QredoTypes.h"
#import "QredoRendezvousHelper.h"

@protocol QredoRendezvousHelper;

@interface QredoRendezvousCrypto :NSObject

+(QredoRendezvousCrypto *)instance;

-(QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                        authenticationKey:(NSData *)authenticationKey
                                   encryptedResponderData:(NSData *)encryptedResponderData;


-(QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                                 authenticationKey:(NSData *)authenticationKey
                                                responderPublicKey:(NSData *)responderPublicKey;


-(QLFKeyPairLF *)newECAccessControlKeyPairWithSeed:(NSData *)seed;

-(QLFKeyPairLF *)newRequesterKeyPair;
-(QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair;

-(NSData *)signChallenge:(NSData *)challenge
                 hashtag:(QLFRendezvousHashedTag *)hashtag
                   nonce:(QLFNonce *)nonce
              privateKey:(QredoPrivateKey *)privateKey;

-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKey:(NSData *)encryptionKey;

-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKey:(NSData *)encryptionKey
                             iv:(NSData *)iv;

-(QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                              encryptionKey:(NSData *)encryptionKey
                                                      error:(NSError **)error;

-(BOOL)validateEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
                    authenticationKey:(NSData *)authenticationKey
                                  tag:(NSString *)tag
                            hashedTag:(QLFRendezvousHashedTag *)hashedTag
                      trustedRootPems:(NSArray *)trustedRootPems
                              crlPems:(NSArray *)crlPems
                                error:(NSError **)error;

-(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)fullTag
                                                        trustedRootPems:(NSArray *)trustedRootPems
                                                                crlPems:(NSArray *)crlPems
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error;

-(NSData *)masterKeyWithTag:(NSString *)tag appId:(NSString *)appId;
-(QLFRendezvousHashedTag *)hashedTagWithMasterKey:(NSData *)masterKey;
-(NSData *)encryptionKeyWithMasterKey:(NSData *)masterKey;
-(NSData *)authenticationKeyWithMasterKey:(NSData *)masterKey;
+(NSData *)transformPrivateKeyToData:(SecKeyRef)key;

@end
