#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoKeyPair.h"
#import "QredoTypes.h"
#import "QredoRendezvousHelper.h"

@protocol QredoRendezvousHelper;

@interface QredoRendezvousCrypto : NSObject

+ (QredoRendezvousCrypto *)instance;

- (QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                         authenticationKey:(NSData *)authenticationKey
                                    encryptedResponderData:(NSData *)encryptedResponderData;

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
                       error:(NSError **)error;

- (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                          signingHandler:(signDataBlock)signingHandler
                                                                   error:(NSError **)error;

- (NSData *)masterKeyWithTag:(NSString *)tag;
- (QLFRendezvousHashedTag *)hashedTagWithMasterKey:(NSData *)masterKey;
- (NSData *)encryptionKeyWithMasterKey:(NSData *)masterKey;
- (NSData *)authenticationKeyWithMasterKey:(NSData *)masterKey;


@end