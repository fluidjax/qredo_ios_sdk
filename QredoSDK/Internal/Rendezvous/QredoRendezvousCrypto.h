#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoKeyPair.h"

@interface QredoRendezvousCrypto : NSObject

+ (QredoRendezvousCrypto *)instance;

- (QredoAuthenticationCode *)authenticationCodeWithHashedTag:(QredoRendezvousHashedTag *)hashedTag
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

@end