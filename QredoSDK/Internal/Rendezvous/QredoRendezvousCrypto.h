#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoKeyPair.h"
#import "QredoTypes.h"

@protocol QredoRendezvousHelper;

@interface QredoRendezvousCrypto : NSObject

+ (QredoRendezvousCrypto *)instance;

- (QredoAuthenticationCode *)authenticationCodeWithRendezvousHelper:(id<QredoRendezvousHelper>)rendezvousHelper
                                                          hashedTag:(QredoRendezvousHashedTag *)hashedTag
                                                   conversationType:(NSString *)conversationType
                                                    durationSeconds:(NSSet *)durationSeconds
                                                   maxResponseCount:(NSSet *)maxResponseCount
                                                           transCap:(NSSet *)transCap
                                                 requesterPublicKey:(QredoRequesterPublicKey *)requesterPublicKey
                                             accessControlPublicKey:(QredoAccessControlPublicKey *)accessControlPublicKey
                                                  authenticationKey:(QredoAuthenticationCode *)authenticationKey;

- (QredoRendezvousHashedTag *)hashedTag:(NSString *)tag;
- (QredoRendezvousHashedTag *)hashedTagWithAuthKey:(QredoAuthenticationCode *)authKey;
- (QredoAuthenticationCode *)authKey:(NSString *)tag;
- (QredoKeyPairLF *)newAccessControlKeyPairWithId:(NSString*)keyId;
- (QredoKeyPairLF *)newRequesterKeyPair;
- (QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair;

- (SecKeyRef)accessControlPublicKeyWithTag:(NSString*)tag;
- (SecKeyRef)accessControlPrivateKeyWithTag:(NSString*)tag;

- (NSData *)signChallenge:(NSData*)challenge hashtag:(QredoRendezvousHashedTag*)hashtag nonce:(QredoNonce*)nonce privateKey:(QredoPrivateKey*)privateKey;
- (BOOL)validateCreationInfo:(QredoRendezvousCreationInfo *)creationInfo tag:(NSString *)tag;

- (id<QredoRendezvousHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType tag:(NSString *)tag;

@end