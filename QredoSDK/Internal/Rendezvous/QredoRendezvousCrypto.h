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


- (QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                                  authenticationKey:(NSData *)authenticationKey
                                                 responderPublicKey:(NSData *)responderPublicKey;


- (QLFKeyPairLF *)newAccessControlKeyPairWithId:(NSString*)keyId;
- (QLFKeyPairLF *)newRequesterKeyPair;
- (QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair;

- (SecKeyRef)accessControlPublicKeyWithTag:(NSString*)tag;
- (SecKeyRef)accessControlPrivateKeyWithTag:(NSString*)tag;

- (NSData *)signChallenge:(NSData*)challenge
                  hashtag:(QLFRendezvousHashedTag*)hashtag
                    nonce:(QLFNonce*)nonce
               privateKey:(QredoPrivateKey*)privateKey;

- (NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                   encryptionKey:(NSData *)encryptionKey;

- (QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                               encryptionKey:(NSData *)encryptionKey
                                                       error:(NSError **)error;

- (BOOL)validateResponseRegistered:(QLFRendezvousResponseRegistered *)response
                 authenticationKey:(NSData *)authenticationKey
                               tag:(NSString *)tag
                         hashedTag:(QLFRendezvousHashedTag *)hashedTag
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