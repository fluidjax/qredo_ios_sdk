#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoKeyPair.h"
#import "QredoTypes.h"
#import "QredoRendezvousHelper.h"

@protocol QredoRendezvousHelper;

@interface QredoRendezvousCrypto : NSObject

+ (QredoRendezvousCrypto *)instance;

- (QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                            conversationType:(NSString *)conversationType
                                             durationSeconds:(NSSet *)durationSeconds
                                            maxResponseCount:(NSSet *)maxResponseCount
                                                    transCap:(NSSet *)transCap
                                          requesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey
                                      accessControlPublicKey:(QLFAccessControlPublicKey *)accessControlPublicKey
                                           authenticationKey:(QLFAuthenticationCode *)authenticationKey
                                            rendezvousHelper:(id<QredoRendezvousHelper>)rendezvousHelper;

- (QLFRendezvousHashedTag *)hashedTag:(NSString *)tag;
- (QLFRendezvousHashedTag *)hashedTagWithAuthKey:(QLFAuthenticationCode *)authKey;
- (QLFAuthenticationCode *)authKey:(NSString *)tag;
- (QLFKeyPairLF *)newAccessControlKeyPairWithId:(NSString*)keyId;
- (QLFKeyPairLF *)newRequesterKeyPair;
- (QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair;

- (SecKeyRef)accessControlPublicKeyWithTag:(NSString*)tag;
- (SecKeyRef)accessControlPrivateKeyWithTag:(NSString*)tag;

- (NSData *)signChallenge:(NSData*)challenge
                  hashtag:(QLFRendezvousHashedTag*)hashtag
                    nonce:(QLFNonce*)nonce
               privateKey:(QredoPrivateKey*)privateKey;

- (BOOL)validateCreationInfo:(QLFRendezvousCreationInfo *)creationInfo
                         tag:(NSString *)tag
             trustedRootRefs:(NSArray *)trustedRootRefs
                       error:(NSError **)error;

- (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                         trustedRootRefs:trustedRootRefs
                                                          signingHandler:(signDataBlock)signingHandler
                                                                   error:(NSError **)error;

@end