#import <Foundation/Foundation.h>
#import "QredoDateTime.h"
#import "QredoQUID.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoMarshallable.h"
#import "QredoServiceInvoker.h"

#define QLFAnonymousToken1024 NSData
#define QLFAuthCode NSData
#define QLFAuthenticationCode NSData
#define QLFAuthenticationKey256 NSData
#define QLFConversationSequenceValue NSData
#define QLFEncryptionKey256 NSData
#define QLFFetchSize int32_t
#define QLFNonce NSData
#define QLFConversationId QredoQUID
#define QLFConversationMessageId QredoQUID
#define QLFConversationQueueId QredoQUID
#define QLFRendezvousDurationSeconds NSSet
#define QLFRendezvousHashedTag QredoQUID
#define QLFRendezvousNumOfResponses int64_t
#define QLFRendezvousOwnershipPublicKey NSData
#define QLFRendezvousSequenceValue int64_t
#define QLFRequesterPublicKey NSData
#define QLFResponderPublicKey NSData
#define QLFTimestamp int64_t
#define QLFTransCap NSData
#define QLFVaultId QredoQUID
#define QLFVaultItemId QredoQUID
#define QLFVaultOwnershipPrivateKey NSData
#define QLFVaultSequenceId QredoQUID
#define QLFVaultSequenceValue int64_t

@interface QLFCachedVaultItem : NSObject<QredoMarshallable>

@property (readonly) NSData *encryptedItem;
@property (readonly) QLFAuthCode *authCode;

+ (QLFCachedVaultItem *)cachedVaultItemWithEncryptedItem:(NSData *)encryptedItem authCode:(QLFAuthCode *)authCode;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithEncryptedItem:(NSData *)encryptedItem authCode:(QLFAuthCode *)authCode;
- (NSComparisonResult)compare:(QLFCachedVaultItem *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCachedVaultItem:(QLFCachedVaultItem *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationAckResult : NSObject<QredoMarshallable>



+ (QLFConversationAckResult *)conversationAckResult;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFConversationAckResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationAckResult:(QLFConversationAckResult *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationPublishResult : NSObject<QredoMarshallable>

@property (readonly) QLFConversationSequenceValue *sequenceValue;

+ (QLFConversationPublishResult *)conversationPublishResultWithSequenceValue:(QLFConversationSequenceValue *)sequenceValue;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSequenceValue:(QLFConversationSequenceValue *)sequenceValue;
- (NSComparisonResult)compare:(QLFConversationPublishResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationPublishResult:(QLFConversationPublishResult *)other;
- (NSUInteger)hash;

@end


@interface QLFCtrl : NSObject<QredoMarshallable>



+ (QLFCtrl *)qRV;

+ (QLFCtrl *)qRT;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifQRV:(void (^)())ifQRVBlock ifQRT:(void (^)())ifQRTBlock;
- (NSComparisonResult)compare:(QLFCtrl *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCtrl:(QLFCtrl *)other;
- (NSUInteger)hash;

@end


@interface QLFQRV : QLFCtrl



+ (QLFCtrl *)qRV;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFQRV *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToQRV:(QLFQRV *)other;
- (NSUInteger)hash;

@end


@interface QLFQRT : QLFCtrl



+ (QLFCtrl *)qRT;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFQRT *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToQRT:(QLFQRT *)other;
- (NSUInteger)hash;

@end


@interface QLFEncryptedConversationItem : NSObject<QredoMarshallable>

@property (readonly) NSData *encryptedMessage;
@property (readonly) QLFAuthCode *authCode;

+ (QLFEncryptedConversationItem *)encryptedConversationItemWithEncryptedMessage:(NSData *)encryptedMessage authCode:(QLFAuthCode *)authCode;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithEncryptedMessage:(NSData *)encryptedMessage authCode:(QLFAuthCode *)authCode;
- (NSComparisonResult)compare:(QLFEncryptedConversationItem *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedConversationItem:(QLFEncryptedConversationItem *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationItemWithSequenceValue : NSObject<QredoMarshallable>

@property (readonly) QLFEncryptedConversationItem *item;
@property (readonly) QLFConversationSequenceValue *sequenceValue;

+ (QLFConversationItemWithSequenceValue *)conversationItemWithSequenceValueWithItem:(QLFEncryptedConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithItem:(QLFEncryptedConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue;
- (NSComparisonResult)compare:(QLFConversationItemWithSequenceValue *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationItemWithSequenceValue:(QLFConversationItemWithSequenceValue *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationQueryItemsResult : NSObject<QredoMarshallable>

@property (readonly) NSArray *items;
@property (readonly) QLFConversationSequenceValue *maxSequenceValue;
@property (readonly) BOOL current;

+ (QLFConversationQueryItemsResult *)conversationQueryItemsResultWithItems:(NSArray *)items maxSequenceValue:(QLFConversationSequenceValue *)maxSequenceValue current:(BOOL)current;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithItems:(NSArray *)items maxSequenceValue:(QLFConversationSequenceValue *)maxSequenceValue current:(BOOL)current;
- (NSComparisonResult)compare:(QLFConversationQueryItemsResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationQueryItemsResult:(QLFConversationQueryItemsResult *)other;
- (NSUInteger)hash;

@end


@interface QLFEncryptedRecoveryInfoType : NSObject<QredoMarshallable>

@property (readonly) int32_t credentialType;
@property (readonly) NSData *encryptedMasterKey;

+ (QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfoTypeWithCredentialType:(int32_t)credentialType encryptedMasterKey:(NSData *)encryptedMasterKey;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithCredentialType:(int32_t)credentialType encryptedMasterKey:(NSData *)encryptedMasterKey;
- (NSComparisonResult)compare:(QLFEncryptedRecoveryInfoType *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedRecoveryInfoType:(QLFEncryptedRecoveryInfoType *)other;
- (NSUInteger)hash;

@end


@interface QLFEncryptedKeychain : NSObject<QredoMarshallable>

@property (readonly) int32_t credentialType;
@property (readonly) NSData *encryptedKeyChain;
@property (readonly) QLFEncryptedRecoveryInfoType *encryptedRecoveryInfo;

+ (QLFEncryptedKeychain *)encryptedKeychainWithCredentialType:(int32_t)credentialType encryptedKeyChain:(NSData *)encryptedKeyChain encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithCredentialType:(int32_t)credentialType encryptedKeyChain:(NSData *)encryptedKeyChain encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo;
- (NSComparisonResult)compare:(QLFEncryptedKeychain *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedKeychain:(QLFEncryptedKeychain *)other;
- (NSUInteger)hash;

@end


@interface QLFKeyLF : NSObject<QredoMarshallable>

@property (readonly) NSData *bytes;

+ (QLFKeyLF *)keyLFWithBytes:(NSData *)bytes;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithBytes:(NSData *)bytes;
- (NSComparisonResult)compare:(QLFKeyLF *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToKeyLF:(QLFKeyLF *)other;
- (NSUInteger)hash;

@end


@interface QLFKeyPairLF : NSObject<QredoMarshallable>

@property (readonly) QLFKeyLF *pubKey;
@property (readonly) QLFKeyLF *privKey;

+ (QLFKeyPairLF *)keyPairLFWithPubKey:(QLFKeyLF *)pubKey privKey:(QLFKeyLF *)privKey;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithPubKey:(QLFKeyLF *)pubKey privKey:(QLFKeyLF *)privKey;
- (NSComparisonResult)compare:(QLFKeyPairLF *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToKeyPairLF:(QLFKeyPairLF *)other;
- (NSUInteger)hash;

@end


@interface QLFOperationType : NSObject<QredoMarshallable>



+ (QLFOperationType *)operationCreate;

+ (QLFOperationType *)operationGet;

+ (QLFOperationType *)operationList;

+ (QLFOperationType *)operationDelete;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifOperationCreate:(void (^)())ifOperationCreateBlock ifOperationGet:(void (^)())ifOperationGetBlock ifOperationList:(void (^)())ifOperationListBlock ifOperationDelete:(void (^)())ifOperationDeleteBlock;
- (NSComparisonResult)compare:(QLFOperationType *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToOperationType:(QLFOperationType *)other;
- (NSUInteger)hash;

@end


@interface QLFOperationCreate : QLFOperationType



+ (QLFOperationType *)operationCreate;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFOperationCreate *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToOperationCreate:(QLFOperationCreate *)other;
- (NSUInteger)hash;

@end


@interface QLFOperationGet : QLFOperationType



+ (QLFOperationType *)operationGet;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFOperationGet *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToOperationGet:(QLFOperationGet *)other;
- (NSUInteger)hash;

@end


@interface QLFOperationList : QLFOperationType



+ (QLFOperationType *)operationList;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFOperationList *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToOperationList:(QLFOperationList *)other;
- (NSUInteger)hash;

@end


@interface QLFOperationDelete : QLFOperationType



+ (QLFOperationType *)operationDelete;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFOperationDelete *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToOperationDelete:(QLFOperationDelete *)other;
- (NSUInteger)hash;

@end


@interface QLFRecoveryInfoType : NSObject<QredoMarshallable>

@property (readonly) int32_t credentialType;
@property (readonly) QLFEncryptionKey256 *masterKey;

+ (QLFRecoveryInfoType *)recoveryInfoTypeWithCredentialType:(int32_t)credentialType masterKey:(QLFEncryptionKey256 *)masterKey;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithCredentialType:(int32_t)credentialType masterKey:(QLFEncryptionKey256 *)masterKey;
- (NSComparisonResult)compare:(QLFRecoveryInfoType *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRecoveryInfoType:(QLFRecoveryInfoType *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAuthSignature : NSObject<QredoMarshallable>



+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEMWithSignature:(NSData *)signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEM_SELFSIGNEDWithSignature:(NSData *)signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthED25519WithSignature:(NSData *)signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA2048_PEMWithSignature:(NSData *)signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA4096_PEMWithSignature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousAuthX509_PEM:(void (^)(NSData *))ifRendezvousAuthX509_PEMBlock ifRendezvousAuthX509_PEM_SELFSIGNED:(void (^)(NSData *))ifRendezvousAuthX509_PEM_SELFSIGNEDBlock ifRendezvousAuthED25519:(void (^)(NSData *))ifRendezvousAuthED25519Block ifRendezvousAuthRSA2048_PEM:(void (^)(NSData *))ifRendezvousAuthRSA2048_PEMBlock ifRendezvousAuthRSA4096_PEM:(void (^)(NSData *))ifRendezvousAuthRSA4096_PEMBlock;
- (NSComparisonResult)compare:(QLFRendezvousAuthSignature *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAuthSignature:(QLFRendezvousAuthSignature *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAuthX509_PEM : QLFRendezvousAuthSignature

@property (readonly) NSData *signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEMWithSignature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSignature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFRendezvousAuthX509_PEM *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAuthX509_PEM:(QLFRendezvousAuthX509_PEM *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAuthX509_PEM_SELFSIGNED : QLFRendezvousAuthSignature

@property (readonly) NSData *signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEM_SELFSIGNEDWithSignature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSignature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFRendezvousAuthX509_PEM_SELFSIGNED *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAuthX509_PEM_SELFSIGNED:(QLFRendezvousAuthX509_PEM_SELFSIGNED *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAuthED25519 : QLFRendezvousAuthSignature

@property (readonly) NSData *signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthED25519WithSignature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSignature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFRendezvousAuthED25519 *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAuthED25519:(QLFRendezvousAuthED25519 *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAuthRSA2048_PEM : QLFRendezvousAuthSignature

@property (readonly) NSData *signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA2048_PEMWithSignature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSignature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFRendezvousAuthRSA2048_PEM *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAuthRSA2048_PEM:(QLFRendezvousAuthRSA2048_PEM *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAuthRSA4096_PEM : QLFRendezvousAuthSignature

@property (readonly) NSData *signature;

+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA4096_PEMWithSignature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSignature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFRendezvousAuthRSA4096_PEM *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAuthRSA4096_PEM:(QLFRendezvousAuthRSA4096_PEM *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAuthType : NSObject<QredoMarshallable>



+ (QLFRendezvousAuthType *)rendezvousAnonymous;

+ (QLFRendezvousAuthType *)rendezvousTrustedWithSignature:(QLFRendezvousAuthSignature *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousAnonymous:(void (^)())ifRendezvousAnonymousBlock ifRendezvousTrusted:(void (^)(QLFRendezvousAuthSignature *))ifRendezvousTrustedBlock;
- (NSComparisonResult)compare:(QLFRendezvousAuthType *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAuthType:(QLFRendezvousAuthType *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAnonymous : QLFRendezvousAuthType



+ (QLFRendezvousAuthType *)rendezvousAnonymous;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousAnonymous *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAnonymous:(QLFRendezvousAnonymous *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousTrusted : QLFRendezvousAuthType

@property (readonly) QLFRendezvousAuthSignature *signature;

+ (QLFRendezvousAuthType *)rendezvousTrustedWithSignature:(QLFRendezvousAuthSignature *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSignature:(QLFRendezvousAuthSignature *)signature;
- (NSComparisonResult)compare:(QLFRendezvousTrusted *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousTrusted:(QLFRendezvousTrusted *)other;
- (NSUInteger)hash;

@end


@interface QLFEncryptedResponderInfo : NSObject<QredoMarshallable>

@property (readonly) NSData *value;
@property (readonly) QLFAuthenticationCode *authenticationCode;
@property (readonly) QLFRendezvousAuthType *authenticationType;

+ (QLFEncryptedResponderInfo *)encryptedResponderInfoWithValue:(NSData *)value authenticationCode:(QLFAuthenticationCode *)authenticationCode authenticationType:(QLFRendezvousAuthType *)authenticationType;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithValue:(NSData *)value authenticationCode:(QLFAuthenticationCode *)authenticationCode authenticationType:(QLFRendezvousAuthType *)authenticationType;
- (NSComparisonResult)compare:(QLFEncryptedResponderInfo *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedResponderInfo:(QLFEncryptedResponderInfo *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousDeactivated : NSObject<QredoMarshallable>



+ (QLFRendezvousDeactivated *)rendezvousDeactivated;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousDeactivated *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousDeactivated:(QLFRendezvousDeactivated *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseCountLimit : NSObject<QredoMarshallable>



+ (QLFRendezvousResponseCountLimit *)rendezvousSingleResponse;

+ (QLFRendezvousResponseCountLimit *)rendezvousUnlimitedResponses;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousSingleResponse:(void (^)())ifRendezvousSingleResponseBlock ifRendezvousUnlimitedResponses:(void (^)())ifRendezvousUnlimitedResponsesBlock;
- (NSComparisonResult)compare:(QLFRendezvousResponseCountLimit *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseCountLimit:(QLFRendezvousResponseCountLimit *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousSingleResponse : QLFRendezvousResponseCountLimit



+ (QLFRendezvousResponseCountLimit *)rendezvousSingleResponse;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousSingleResponse *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousSingleResponse:(QLFRendezvousSingleResponse *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousUnlimitedResponses : QLFRendezvousResponseCountLimit



+ (QLFRendezvousResponseCountLimit *)rendezvousUnlimitedResponses;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousUnlimitedResponses *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousUnlimitedResponses:(QLFRendezvousUnlimitedResponses *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousCreationInfo : NSObject<QredoMarshallable>

@property (readonly) QLFRendezvousHashedTag *hashedTag;
@property (readonly) QLFRendezvousDurationSeconds *durationSeconds;
@property (readonly) QLFRendezvousResponseCountLimit *responseCountLimit;
@property (readonly) QLFRendezvousOwnershipPublicKey *ownershipPublicKey;
@property (readonly) QLFEncryptedResponderInfo *encryptedResponderInfo;

+ (QLFRendezvousCreationInfo *)rendezvousCreationInfoWithHashedTag:(QLFRendezvousHashedTag *)hashedTag durationSeconds:(QLFRendezvousDurationSeconds *)durationSeconds responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit ownershipPublicKey:(QLFRendezvousOwnershipPublicKey *)ownershipPublicKey encryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithHashedTag:(QLFRendezvousHashedTag *)hashedTag durationSeconds:(QLFRendezvousDurationSeconds *)durationSeconds responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit ownershipPublicKey:(QLFRendezvousOwnershipPublicKey *)ownershipPublicKey encryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo;
- (NSComparisonResult)compare:(QLFRendezvousCreationInfo *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousCreationInfo:(QLFRendezvousCreationInfo *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseRejectionReason : NSObject<QredoMarshallable>



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseMaxResponseCountReached;

+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseDurationElapsed;

+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseInvalid;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousResponseMaxResponseCountReached:(void (^)())ifRendezvousResponseMaxResponseCountReachedBlock ifRendezvousResponseDurationElapsed:(void (^)())ifRendezvousResponseDurationElapsedBlock ifRendezvousResponseInvalid:(void (^)())ifRendezvousResponseInvalidBlock;
- (NSComparisonResult)compare:(QLFRendezvousResponseRejectionReason *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseRejectionReason:(QLFRendezvousResponseRejectionReason *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseMaxResponseCountReached : QLFRendezvousResponseRejectionReason



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseMaxResponseCountReached;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousResponseMaxResponseCountReached *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseMaxResponseCountReached:(QLFRendezvousResponseMaxResponseCountReached *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseDurationElapsed : QLFRendezvousResponseRejectionReason



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseDurationElapsed;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousResponseDurationElapsed *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseDurationElapsed:(QLFRendezvousResponseDurationElapsed *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseInvalid : QLFRendezvousResponseRejectionReason



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseInvalid;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousResponseInvalid *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseInvalid:(QLFRendezvousResponseInvalid *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousRespondResult : NSObject<QredoMarshallable>



+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithInfo:(QLFEncryptedResponderInfo *)info;

+ (QLFRendezvousRespondResult *)rendezvousResponseUnknownTag;

+ (QLFRendezvousRespondResult *)rendezvousResponseRejectedWithReason:(QLFRendezvousResponseRejectionReason *)reason;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousResponseRegistered:(void (^)(QLFEncryptedResponderInfo *))ifRendezvousResponseRegisteredBlock ifRendezvousResponseUnknownTag:(void (^)())ifRendezvousResponseUnknownTagBlock ifRendezvousResponseRejected:(void (^)(QLFRendezvousResponseRejectionReason *))ifRendezvousResponseRejectedBlock;
- (NSComparisonResult)compare:(QLFRendezvousRespondResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousRespondResult:(QLFRendezvousRespondResult *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseRegistered : QLFRendezvousRespondResult

@property (readonly) QLFEncryptedResponderInfo *info;

+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithInfo:(QLFEncryptedResponderInfo *)info;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithInfo:(QLFEncryptedResponderInfo *)info;
- (NSComparisonResult)compare:(QLFRendezvousResponseRegistered *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseRegistered:(QLFRendezvousResponseRegistered *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseUnknownTag : QLFRendezvousRespondResult



+ (QLFRendezvousRespondResult *)rendezvousResponseUnknownTag;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousResponseUnknownTag *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseUnknownTag:(QLFRendezvousResponseUnknownTag *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseRejected : QLFRendezvousRespondResult

@property (readonly) QLFRendezvousResponseRejectionReason *reason;

+ (QLFRendezvousRespondResult *)rendezvousResponseRejectedWithReason:(QLFRendezvousResponseRejectionReason *)reason;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithReason:(QLFRendezvousResponseRejectionReason *)reason;
- (NSComparisonResult)compare:(QLFRendezvousResponseRejected *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseRejected:(QLFRendezvousResponseRejected *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponse : NSObject<QredoMarshallable>

@property (readonly) QLFRendezvousHashedTag *hashedTag;
@property (readonly) QLFResponderPublicKey *responderPublicKey;
@property (readonly) QLFAuthenticationCode *responderAuthenticationCode;

+ (QLFRendezvousResponse *)rendezvousResponseWithHashedTag:(QLFRendezvousHashedTag *)hashedTag responderPublicKey:(QLFResponderPublicKey *)responderPublicKey responderAuthenticationCode:(QLFAuthenticationCode *)responderAuthenticationCode;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithHashedTag:(QLFRendezvousHashedTag *)hashedTag responderPublicKey:(QLFResponderPublicKey *)responderPublicKey responderAuthenticationCode:(QLFAuthenticationCode *)responderAuthenticationCode;
- (NSComparisonResult)compare:(QLFRendezvousResponse *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponse:(QLFRendezvousResponse *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseWithSequenceValue : NSObject<QredoMarshallable>

@property (readonly) QLFRendezvousResponse *response;
@property (readonly) QLFRendezvousSequenceValue sequenceValue;

+ (QLFRendezvousResponseWithSequenceValue *)rendezvousResponseWithSequenceValueWithResponse:(QLFRendezvousResponse *)response sequenceValue:(QLFRendezvousSequenceValue)sequenceValue;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithResponse:(QLFRendezvousResponse *)response sequenceValue:(QLFRendezvousSequenceValue)sequenceValue;
- (NSComparisonResult)compare:(QLFRendezvousResponseWithSequenceValue *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponseWithSequenceValue:(QLFRendezvousResponseWithSequenceValue *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponsesResult : NSObject<QredoMarshallable>

@property (readonly) NSArray *responses;
@property (readonly) QLFRendezvousSequenceValue sequenceValue;

+ (QLFRendezvousResponsesResult *)rendezvousResponsesResultWithResponses:(NSArray *)responses sequenceValue:(QLFRendezvousSequenceValue)sequenceValue;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithResponses:(NSArray *)responses sequenceValue:(QLFRendezvousSequenceValue)sequenceValue;
- (NSComparisonResult)compare:(QLFRendezvousResponsesResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponsesResult:(QLFRendezvousResponsesResult *)other;
- (NSUInteger)hash;

@end


@interface QLFServiceAccess : NSObject<QredoMarshallable>

@property (readonly) QLFAnonymousToken1024 *token;
@property (readonly) QLFAnonymousToken1024 *signature;
@property (readonly) int32_t keyId;

+ (QLFServiceAccess *)serviceAccessWithToken:(QLFAnonymousToken1024 *)token signature:(QLFAnonymousToken1024 *)signature keyId:(int32_t)keyId;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithToken:(QLFAnonymousToken1024 *)token signature:(QLFAnonymousToken1024 *)signature keyId:(int32_t)keyId;
- (NSComparisonResult)compare:(QLFServiceAccess *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToServiceAccess:(QLFServiceAccess *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationDescriptor : NSObject<QredoMarshallable>

@property (readonly) NSString *rendezvousTag;
@property (readonly) BOOL rendezvousOwner;
@property (readonly) QLFConversationId *conversationId;
@property (readonly) NSString *conversationType;
@property (readonly) QLFRendezvousAuthType *authenticationType;
@property (readonly) QLFKeyPairLF *myKey;
@property (readonly) QLFKeyLF *yourPublicKey;

+ (QLFConversationDescriptor *)conversationDescriptorWithRendezvousTag:(NSString *)rendezvousTag rendezvousOwner:(BOOL)rendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithRendezvousTag:(NSString *)rendezvousTag rendezvousOwner:(BOOL)rendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey;
- (NSComparisonResult)compare:(QLFConversationDescriptor *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationDescriptor:(QLFConversationDescriptor *)other;
- (NSUInteger)hash;

@end


@interface QLFNotificationTarget : NSObject<QredoMarshallable>



+ (QLFNotificationTarget *)fcmRegistrationTokenWithToken:(NSString *)token;

+ (QLFNotificationTarget *)apnsDeviceTokenWithToken:(NSData *)token;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifFcmRegistrationToken:(void (^)(NSString *))ifFcmRegistrationTokenBlock ifApnsDeviceToken:(void (^)(NSData *))ifApnsDeviceTokenBlock;
- (NSComparisonResult)compare:(QLFNotificationTarget *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToNotificationTarget:(QLFNotificationTarget *)other;
- (NSUInteger)hash;

@end


@interface QLFFcmRegistrationToken : QLFNotificationTarget

@property (readonly) NSString *token;

+ (QLFNotificationTarget *)fcmRegistrationTokenWithToken:(NSString *)token;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithToken:(NSString *)token;
- (NSComparisonResult)compare:(QLFFcmRegistrationToken *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToFcmRegistrationToken:(QLFFcmRegistrationToken *)other;
- (NSUInteger)hash;

@end


@interface QLFApnsDeviceToken : QLFNotificationTarget

@property (readonly) NSData *token;

+ (QLFNotificationTarget *)apnsDeviceTokenWithToken:(NSData *)token;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithToken:(NSData *)token;
- (NSComparisonResult)compare:(QLFApnsDeviceToken *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToApnsDeviceToken:(QLFApnsDeviceToken *)other;
- (NSUInteger)hash;

@end


@interface QLFOwnershipSignature : NSObject<QredoMarshallable>

@property (readonly) QLFOperationType *op;
@property (readonly) QLFNonce *nonce;
@property (readonly) QLFTimestamp timestamp;
@property (readonly) NSData *signature;

+ (QLFOwnershipSignature *)ownershipSignatureWithOp:(QLFOperationType *)op nonce:(QLFNonce *)nonce timestamp:(QLFTimestamp)timestamp signature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithOp:(QLFOperationType *)op nonce:(QLFNonce *)nonce timestamp:(QLFTimestamp)timestamp signature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFOwnershipSignature *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToOwnershipSignature:(QLFOwnershipSignature *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponderInfo : NSObject<QredoMarshallable>

@property (readonly) QLFRequesterPublicKey *requesterPublicKey;
@property (readonly) NSString *conversationType;
@property (readonly) NSSet *transCap;

+ (QLFRendezvousResponderInfo *)rendezvousResponderInfoWithRequesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey conversationType:(NSString *)conversationType transCap:(NSSet *)transCap;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithRequesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey conversationType:(NSString *)conversationType transCap:(NSSet *)transCap;
- (NSComparisonResult)compare:(QLFRendezvousResponderInfo *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousResponderInfo:(QLFRendezvousResponderInfo *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousActivated : NSObject<QredoMarshallable>

@property (readonly) NSSet *expiresAt;

+ (QLFRendezvousActivated *)rendezvousActivatedWithExpiresAt:(NSSet *)expiresAt;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithExpiresAt:(NSSet *)expiresAt;
- (NSComparisonResult)compare:(QLFRendezvousActivated *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousActivated:(QLFRendezvousActivated *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousCreateResult : NSObject<QredoMarshallable>



+ (QLFRendezvousCreateResult *)rendezvousCreatedWithExpiresAt:(NSSet *)expiresAt;

+ (QLFRendezvousCreateResult *)rendezvousAlreadyExists;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousCreated:(void (^)(NSSet *))ifRendezvousCreatedBlock ifRendezvousAlreadyExists:(void (^)())ifRendezvousAlreadyExistsBlock;
- (NSComparisonResult)compare:(QLFRendezvousCreateResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousCreateResult:(QLFRendezvousCreateResult *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousCreated : QLFRendezvousCreateResult

@property (readonly) NSSet *expiresAt;

+ (QLFRendezvousCreateResult *)rendezvousCreatedWithExpiresAt:(NSSet *)expiresAt;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithExpiresAt:(NSSet *)expiresAt;
- (NSComparisonResult)compare:(QLFRendezvousCreated *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousCreated:(QLFRendezvousCreated *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousAlreadyExists : QLFRendezvousCreateResult



+ (QLFRendezvousCreateResult *)rendezvousAlreadyExists;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousAlreadyExists *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousAlreadyExists:(QLFRendezvousAlreadyExists *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousDescriptor : NSObject<QredoMarshallable>

@property (readonly) NSString *tag;
@property (readonly) QLFRendezvousHashedTag *hashedTag;
@property (readonly) NSString *conversationType;
@property (readonly) QLFRendezvousAuthType *authenticationType;
@property (readonly) NSSet *durationSeconds;
@property (readonly) NSSet *expiresAt;
@property (readonly) QLFRendezvousResponseCountLimit *responseCountLimit;
@property (readonly) QLFKeyPairLF *requesterKeyPair;
@property (readonly) QLFKeyPairLF *ownershipKeyPair;

+ (QLFRendezvousDescriptor *)rendezvousDescriptorWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds expiresAt:(NSSet *)expiresAt responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair ownershipKeyPair:(QLFKeyPairLF *)ownershipKeyPair;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds expiresAt:(NSSet *)expiresAt responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair ownershipKeyPair:(QLFKeyPairLF *)ownershipKeyPair;
- (NSComparisonResult)compare:(QLFRendezvousDescriptor *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousDescriptor:(QLFRendezvousDescriptor *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousInfo : NSObject<QredoMarshallable>

@property (readonly) QLFRendezvousNumOfResponses numOfResponses;
@property (readonly) QLFRendezvousResponseCountLimit *responseCountLimit;
@property (readonly) NSSet *expiresAt;
@property (readonly) NSSet *deactivatedAt;

+ (QLFRendezvousInfo *)rendezvousInfoWithNumOfResponses:(QLFRendezvousNumOfResponses)numOfResponses responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit expiresAt:(NSSet *)expiresAt deactivatedAt:(NSSet *)deactivatedAt;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithNumOfResponses:(QLFRendezvousNumOfResponses)numOfResponses responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit expiresAt:(NSSet *)expiresAt deactivatedAt:(NSSet *)deactivatedAt;
- (NSComparisonResult)compare:(QLFRendezvousInfo *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousInfo:(QLFRendezvousInfo *)other;
- (NSUInteger)hash;

@end


@interface QLFSV : NSObject<QredoMarshallable>



+ (QLFSV *)sBoolWithV:(BOOL)v;

+ (QLFSV *)sInt64WithV:(int64_t)v;

+ (QLFSV *)sDTWithV:(QredoUTCDateTime *)v;

+ (QLFSV *)sQUIDWithV:(QredoQUID *)v;

+ (QLFSV *)sStringWithV:(NSString *)v;

+ (QLFSV *)sBytesWithV:(NSData *)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifSBool:(void (^)(BOOL ))ifSBoolBlock ifSInt64:(void (^)(int64_t ))ifSInt64Block ifSDT:(void (^)(QredoUTCDateTime *))ifSDTBlock ifSQUID:(void (^)(QredoQUID *))ifSQUIDBlock ifSString:(void (^)(NSString *))ifSStringBlock ifSBytes:(void (^)(NSData *))ifSBytesBlock;
- (NSComparisonResult)compare:(QLFSV *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToSV:(QLFSV *)other;
- (NSUInteger)hash;

@end


@interface QLFSBool : QLFSV

@property (readonly) BOOL v;

+ (QLFSV *)sBoolWithV:(BOOL)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithV:(BOOL)v;
- (NSComparisonResult)compare:(QLFSBool *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToSBool:(QLFSBool *)other;
- (NSUInteger)hash;

@end


@interface QLFSInt64 : QLFSV

@property (readonly) int64_t v;

+ (QLFSV *)sInt64WithV:(int64_t)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithV:(int64_t)v;
- (NSComparisonResult)compare:(QLFSInt64 *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToSInt64:(QLFSInt64 *)other;
- (NSUInteger)hash;

@end


@interface QLFSDT : QLFSV

@property (readonly) QredoUTCDateTime *v;

+ (QLFSV *)sDTWithV:(QredoUTCDateTime *)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithV:(QredoUTCDateTime *)v;
- (NSComparisonResult)compare:(QLFSDT *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToSDT:(QLFSDT *)other;
- (NSUInteger)hash;

@end


@interface QLFSQUID : QLFSV

@property (readonly) QredoQUID *v;

+ (QLFSV *)sQUIDWithV:(QredoQUID *)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithV:(QredoQUID *)v;
- (NSComparisonResult)compare:(QLFSQUID *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToSQUID:(QLFSQUID *)other;
- (NSUInteger)hash;

@end


@interface QLFSString : QLFSV

@property (readonly) NSString *v;

+ (QLFSV *)sStringWithV:(NSString *)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithV:(NSString *)v;
- (NSComparisonResult)compare:(QLFSString *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToSString:(QLFSString *)other;
- (NSUInteger)hash;

@end


@interface QLFSBytes : QLFSV

@property (readonly) NSData *v;

+ (QLFSV *)sBytesWithV:(NSData *)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithV:(NSData *)v;
- (NSComparisonResult)compare:(QLFSBytes *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToSBytes:(QLFSBytes *)other;
- (NSUInteger)hash;

@end


@interface QLFIndexable : NSObject<QredoMarshallable>

@property (readonly) NSString *key;
@property (readonly) QLFSV *value;

+ (QLFIndexable *)indexableWithKey:(NSString *)key value:(QLFSV *)value;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithKey:(NSString *)key value:(QLFSV *)value;
- (NSComparisonResult)compare:(QLFIndexable *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToIndexable:(QLFIndexable *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationMessageMetadata : NSObject<QredoMarshallable>

@property (readonly) QLFConversationMessageId *id;
@property (readonly) NSSet *parentId;
@property (readonly) QLFConversationSequenceValue *sequence;
@property (readonly) BOOL sentByMe;
@property (readonly) QredoUTCDateTime *created;
@property (readonly) NSString *dataType;
@property (readonly) NSSet *values;

+ (QLFConversationMessageMetadata *)conversationMessageMetadataWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence sentByMe:(BOOL)sentByMe created:(QredoUTCDateTime *)created dataType:(NSString *)dataType values:(NSSet *)values;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence sentByMe:(BOOL)sentByMe created:(QredoUTCDateTime *)created dataType:(NSString *)dataType values:(NSSet *)values;
- (NSComparisonResult)compare:(QLFConversationMessageMetadata *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationMessageMetadata:(QLFConversationMessageMetadata *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationMessage : NSObject<QredoMarshallable>

@property (readonly) QLFConversationMessageMetadata *metadata;
@property (readonly) NSData *body;

+ (QLFConversationMessage *)conversationMessageWithMetadata:(QLFConversationMessageMetadata *)metadata body:(NSData *)body;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithMetadata:(QLFConversationMessageMetadata *)metadata body:(NSData *)body;
- (NSComparisonResult)compare:(QLFConversationMessage *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationMessage:(QLFConversationMessage *)other;
- (NSUInteger)hash;

@end


@interface QLFServiceAccessInfo : NSObject<QredoMarshallable>

@property (readonly) QLFServiceAccess *serviceAccess;
@property (readonly) int32_t expirySeconds;
@property (readonly) int32_t renegotiationSeconds;
@property (readonly) QredoUTCDateTime *issuanceDateTimeUTC;

+ (QLFServiceAccessInfo *)serviceAccessInfoWithServiceAccess:(QLFServiceAccess *)serviceAccess expirySeconds:(int32_t)expirySeconds renegotiationSeconds:(int32_t)renegotiationSeconds issuanceDateTimeUTC:(QredoUTCDateTime *)issuanceDateTimeUTC;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithServiceAccess:(QLFServiceAccess *)serviceAccess expirySeconds:(int32_t)expirySeconds renegotiationSeconds:(int32_t)renegotiationSeconds issuanceDateTimeUTC:(QredoUTCDateTime *)issuanceDateTimeUTC;
- (NSComparisonResult)compare:(QLFServiceAccessInfo *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToServiceAccessInfo:(QLFServiceAccessInfo *)other;
- (NSUInteger)hash;

@end


@interface QLFOperatorInfo : NSObject<QredoMarshallable>

@property (readonly) NSString *name;
@property (readonly) NSString *serviceUri;
@property (readonly) NSString *accountID;
@property (readonly) NSSet *currentServiceAccess;
@property (readonly) NSSet *nextServiceAccess;

+ (QLFOperatorInfo *)operatorInfoWithName:(NSString *)name serviceUri:(NSString *)serviceUri accountID:(NSString *)accountID currentServiceAccess:(NSSet *)currentServiceAccess nextServiceAccess:(NSSet *)nextServiceAccess;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithName:(NSString *)name serviceUri:(NSString *)serviceUri accountID:(NSString *)accountID currentServiceAccess:(NSSet *)currentServiceAccess nextServiceAccess:(NSSet *)nextServiceAccess;
- (NSComparisonResult)compare:(QLFOperatorInfo *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToOperatorInfo:(QLFOperatorInfo *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultItemMetadata : NSObject<QredoMarshallable>

@property (readonly) NSString *dataType;
@property (readonly) QredoUTCDateTime *created;
@property (readonly) NSSet *values;

+ (QLFVaultItemMetadata *)vaultItemMetadataWithDataType:(NSString *)dataType created:(QredoUTCDateTime *)created values:(NSSet *)values;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithDataType:(NSString *)dataType created:(QredoUTCDateTime *)created values:(NSSet *)values;
- (NSComparisonResult)compare:(QLFVaultItemMetadata *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItemMetadata:(QLFVaultItemMetadata *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultKeyPair : NSObject<QredoMarshallable>

@property (readonly) QLFEncryptionKey256 *encryptionKey;
@property (readonly) QLFAuthenticationKey256 *authenticationKey;

+ (QLFVaultKeyPair *)vaultKeyPairWithEncryptionKey:(QLFEncryptionKey256 *)encryptionKey authenticationKey:(QLFAuthenticationKey256 *)authenticationKey;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithEncryptionKey:(QLFEncryptionKey256 *)encryptionKey authenticationKey:(QLFAuthenticationKey256 *)authenticationKey;
- (NSComparisonResult)compare:(QLFVaultKeyPair *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultKeyPair:(QLFVaultKeyPair *)other;
- (NSUInteger)hash;

@end


@interface QLFAccessLevelVaultKeys : NSObject<QredoMarshallable>

@property (readonly) int32_t maxAccessLevel;
@property (readonly) NSArray *vaultKeys;

+ (QLFAccessLevelVaultKeys *)accessLevelVaultKeysWithMaxAccessLevel:(int32_t)maxAccessLevel vaultKeys:(NSArray *)vaultKeys;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithMaxAccessLevel:(int32_t)maxAccessLevel vaultKeys:(NSArray *)vaultKeys;
- (NSComparisonResult)compare:(QLFAccessLevelVaultKeys *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAccessLevelVaultKeys:(QLFAccessLevelVaultKeys *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultKeyStore : NSObject<QredoMarshallable>

@property (readonly) int32_t accessLevel;
@property (readonly) int32_t credentialType;
@property (readonly) NSData *encryptedVaultKeys;

+ (QLFVaultKeyStore *)vaultKeyStoreWithAccessLevel:(int32_t)accessLevel credentialType:(int32_t)credentialType encryptedVaultKeys:(NSData *)encryptedVaultKeys;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithAccessLevel:(int32_t)accessLevel credentialType:(int32_t)credentialType encryptedVaultKeys:(NSData *)encryptedVaultKeys;
- (NSComparisonResult)compare:(QLFVaultKeyStore *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultKeyStore:(QLFVaultKeyStore *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultInfoType : NSObject<QredoMarshallable>

@property (readonly) QLFVaultId *vaultID;
@property (readonly) QLFVaultOwnershipPrivateKey *ownershipPrivateKey;
@property (readonly) NSSet *keyStore;

+ (QLFVaultInfoType *)vaultInfoTypeWithVaultID:(QLFVaultId *)vaultID ownershipPrivateKey:(QLFVaultOwnershipPrivateKey *)ownershipPrivateKey keyStore:(NSSet *)keyStore;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithVaultID:(QLFVaultId *)vaultID ownershipPrivateKey:(QLFVaultOwnershipPrivateKey *)ownershipPrivateKey keyStore:(NSSet *)keyStore;
- (NSComparisonResult)compare:(QLFVaultInfoType *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultInfoType:(QLFVaultInfoType *)other;
- (NSUInteger)hash;

@end


@interface QLFKeychain : NSObject<QredoMarshallable>

@property (readonly) int32_t credentialType;
@property (readonly) QLFOperatorInfo *operatorInfo;
@property (readonly) QLFVaultInfoType *vaultInfo;
@property (readonly) QLFEncryptedRecoveryInfoType *encryptedRecoveryInfo;

+ (QLFKeychain *)keychainWithCredentialType:(int32_t)credentialType operatorInfo:(QLFOperatorInfo *)operatorInfo vaultInfo:(QLFVaultInfoType *)vaultInfo encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithCredentialType:(int32_t)credentialType operatorInfo:(QLFOperatorInfo *)operatorInfo vaultInfo:(QLFVaultInfoType *)vaultInfo encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo;
- (NSComparisonResult)compare:(QLFKeychain *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToKeychain:(QLFKeychain *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultItemRef : NSObject<QredoMarshallable>

@property (readonly) QLFVaultId *vaultId;
@property (readonly) QLFVaultSequenceId *sequenceId;
@property (readonly) QLFVaultSequenceValue sequenceValue;
@property (readonly) QLFVaultItemId *itemId;

+ (QLFVaultItemRef *)vaultItemRefWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId;
- (NSComparisonResult)compare:(QLFVaultItemRef *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItemRef:(QLFVaultItemRef *)other;
- (NSUInteger)hash;

@end


@interface QLFEncryptedVaultItemHeader : NSObject<QredoMarshallable>

@property (readonly) QLFVaultItemRef *ref;
@property (readonly) NSData *encryptedMetadata;
@property (readonly) QLFAuthCode *authCode;

+ (QLFEncryptedVaultItemHeader *)encryptedVaultItemHeaderWithRef:(QLFVaultItemRef *)ref encryptedMetadata:(NSData *)encryptedMetadata authCode:(QLFAuthCode *)authCode;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithRef:(QLFVaultItemRef *)ref encryptedMetadata:(NSData *)encryptedMetadata authCode:(QLFAuthCode *)authCode;
- (NSComparisonResult)compare:(QLFEncryptedVaultItemHeader *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)other;
- (NSUInteger)hash;

@end


@interface QLFEncryptedVaultItem : NSObject<QredoMarshallable>

@property (readonly) QLFEncryptedVaultItemHeader *header;
@property (readonly) NSData *encryptedBody;
@property (readonly) QLFAuthCode *authCode;

+ (QLFEncryptedVaultItem *)encryptedVaultItemWithHeader:(QLFEncryptedVaultItemHeader *)header encryptedBody:(NSData *)encryptedBody authCode:(QLFAuthCode *)authCode;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithHeader:(QLFEncryptedVaultItemHeader *)header encryptedBody:(NSData *)encryptedBody authCode:(QLFAuthCode *)authCode;
- (NSComparisonResult)compare:(QLFEncryptedVaultItem *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedVaultItem:(QLFEncryptedVaultItem *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultItem : NSObject<QredoMarshallable>

@property (readonly) QLFVaultItemRef *ref;
@property (readonly) QLFVaultItemMetadata *metadata;
@property (readonly) NSData *body;

+ (QLFVaultItem *)vaultItemWithRef:(QLFVaultItemRef *)ref metadata:(QLFVaultItemMetadata *)metadata body:(NSData *)body;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithRef:(QLFVaultItemRef *)ref metadata:(QLFVaultItemMetadata *)metadata body:(NSData *)body;
- (NSComparisonResult)compare:(QLFVaultItem *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItem:(QLFVaultItem *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultItemQueryResults : NSObject<QredoMarshallable>

@property (readonly) NSArray *results;
@property (readonly) BOOL current;
@property (readonly) NSSet *sequenceIds;

+ (QLFVaultItemQueryResults *)vaultItemQueryResultsWithResults:(NSArray *)results current:(BOOL)current sequenceIds:(NSSet *)sequenceIds;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithResults:(NSArray *)results current:(BOOL)current sequenceIds:(NSSet *)sequenceIds;
- (NSComparisonResult)compare:(QLFVaultItemQueryResults *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItemQueryResults:(QLFVaultItemQueryResults *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultSequenceState : NSObject<QredoMarshallable>

@property (readonly) QLFVaultSequenceId *sequenceId;
@property (readonly) QLFVaultSequenceValue sequenceValue;

+ (QLFVaultSequenceState *)vaultSequenceStateWithSequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue;
- (NSComparisonResult)compare:(QLFVaultSequenceState *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultSequenceState:(QLFVaultSequenceState *)other;
- (NSUInteger)hash;

@end


@interface QLFConversations : NSObject



+ (QLFConversations *)conversationsWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;
- (void)publishWithQueueId:(QLFConversationQueueId *)queueId item:(QLFEncryptedConversationItem *)item signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationPublishResult *result, NSError *error))completionHandler;
- (void)queryItemsWithQueueId:(QLFConversationQueueId *)queueId after:(NSSet *)after fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationQueryItemsResult *result, NSError *error))completionHandler;
- (void)acknowledgeReceiptWithQueueId:(QLFConversationQueueId *)queueId upTo:(QLFConversationSequenceValue *)upTo signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationAckResult *result, NSError *error))completionHandler;
- (void)subscribeWithQueueId:(QLFConversationQueueId *)queueId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationItemWithSequenceValue *result, NSError *error))completionHandler;
- (void)subscribeAfterWithQueueId:(QLFConversationQueueId *)queueId after:(NSSet *)after fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationItemWithSequenceValue *result, NSError *error))completionHandler;
- (void)subscribeWithPushWithQueueId:(QLFConversationQueueId *)queueId notificationId:(QLFNotificationTarget *)notificationId completionHandler:(void(^)(QLFConversationItemWithSequenceValue *result, NSError *error))completionHandler;

@end


@interface QLFPing : NSObject



+ (QLFPing *)pingWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;
- (void)pingWithCompletionHandler:(void(^)(BOOL result, NSError *error))completionHandler;

@end


@interface QLFRendezvous : NSObject



+ (QLFRendezvous *)rendezvousWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;
- (void)createWithCreationInfo:(QLFRendezvousCreationInfo *)creationInfo completionHandler:(void(^)(QLFRendezvousCreateResult *result, NSError *error))completionHandler;
- (void)activateWithHashedTag:(QLFRendezvousHashedTag *)hashedTag durationSeconds:(QLFRendezvousDurationSeconds *)durationSeconds signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousActivated *result, NSError *error))completionHandler;
- (void)getInfoWithHashedTag:(QLFRendezvousHashedTag *)hashedTag signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousInfo *result, NSError *error))completionHandler;
- (void)respondWithResponse:(QLFRendezvousResponse *)response completionHandler:(void(^)(QLFRendezvousRespondResult *result, NSError *error))completionHandler;
- (void)getResponsesWithHashedTag:(QLFRendezvousHashedTag *)hashedTag after:(QLFRendezvousSequenceValue)after signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousResponsesResult *result, NSError *error))completionHandler;
- (void)subscribeToResponsesWithHashedTag:(QLFRendezvousHashedTag *)hashedTag signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousResponseWithSequenceValue *result, NSError *error))completionHandler;
- (void)subscribeToResponsesAfterWithHashedTag:(QLFRendezvousHashedTag *)hashedTag after:(QLFRendezvousSequenceValue)after fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousResponseWithSequenceValue *result, NSError *error))completionHandler;
- (void)deactivateWithHashedTag:(QLFRendezvousHashedTag *)hashedTag signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousDeactivated *result, NSError *error))completionHandler;

@end


@interface QLFVault : NSObject



+ (QLFVault *)vaultWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;
- (void)putItemWithItem:(QLFEncryptedVaultItem *)item signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(BOOL result, NSError *error))completionHandler;
- (void)getItemWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(NSSet *)sequenceValue itemId:(QLFVaultItemId *)itemId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(NSSet *result, NSError *error))completionHandler;
- (void)getItemHeaderWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(NSSet *)sequenceValue itemId:(QLFVaultItemId *)itemId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(NSSet *result, NSError *error))completionHandler;
- (void)queryItemHeadersWithVaultId:(QLFVaultId *)vaultId sequenceStates:(NSSet *)sequenceStates signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFVaultItemQueryResults *result, NSError *error))completionHandler;
- (void)subscribeToItemHeadersWithVaultId:(QLFVaultId *)vaultId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFEncryptedVaultItemHeader *result, NSError *error))completionHandler;
- (void)subscribeToItemHeadersAfterWithVaultId:(QLFVaultId *)vaultId sequenceStates:(NSSet *)sequenceStates fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFEncryptedVaultItemHeader *result, NSError *error))completionHandler;

@end



