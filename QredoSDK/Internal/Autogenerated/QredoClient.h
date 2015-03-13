#import <Foundation/Foundation.h>
#import "QredoDateTime.h"
#import "QredoQUID.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoMarshallable.h"
#import "QredoServiceInvoker.h"

#define QLFAccessControlPublicKey NSData
#define QLFAccessControlSignature NSData
#define QLFAnonymousToken1024 NSData
#define QLFAuthenticationCode NSData
#define QLFAuthenticationKey256 NSData
#define QLFBlindedToken QLFAnonymousToken1024
#define QLFBlindingKey NSData
#define QLFConversationItem NSData
#define QLFConversationSequenceValue NSData
#define QLFEncryptionKey256 NSData
#define QLFFetchSize int32_t
#define QLFKeySlotNumber int32_t
#define QLFNonce NSData
#define QLFConversationId QredoQUID
#define QLFConversationMessageId QredoQUID
#define QLFConversationQueueId QredoQUID
#define QLFRendezvousHashedTag QredoQUID
#define QLFRendezvousSequenceValue int64_t
#define QLFRequesterPublicKey NSData
#define QLFResponderPublicKey NSData
#define QLFSignedBlindedToken QLFAnonymousToken1024
#define QLFAccountCredential NSString
#define QLFAccountId NSString
#define QLFIdentityCertificate NSString
#define QLFTransCap NSData
#define QLFVaultId QredoQUID
#define QLFVaultItemId QredoQUID
#define QLFVaultSequenceId QredoQUID
#define QLFVaultSequenceValue int64_t

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


@interface QLFConversationItemWithSequenceValue : NSObject<QredoMarshallable>

@property (readonly) QLFConversationItem *item;
@property (readonly) QLFConversationSequenceValue *sequenceValue;

+ (QLFConversationItemWithSequenceValue *)conversationItemWithSequenceValueWithItem:(QLFConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithItem:(QLFConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue;
- (NSComparisonResult)compare:(QLFConversationItemWithSequenceValue *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationItemWithSequenceValue:(QLFConversationItemWithSequenceValue *)other;
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


@interface QLFCredentialValidationResult : NSObject<QredoMarshallable>



+ (QLFCredentialValidationResult *)credentialValidity;

+ (QLFCredentialValidationResult *)certificateChainRevoked;

+ (QLFCredentialValidationResult *)credentialRevoked;

+ (QLFCredentialValidationResult *)credentialExpired;

+ (QLFCredentialValidationResult *)credentialNotValid;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifCredentialValidity:(void (^)())ifCredentialValidityBlock ifCertificateChainRevoked:(void (^)())ifCertificateChainRevokedBlock ifCredentialRevoked:(void (^)())ifCredentialRevokedBlock ifCredentialExpired:(void (^)())ifCredentialExpiredBlock ifCredentialNotValid:(void (^)())ifCredentialNotValidBlock;
- (NSComparisonResult)compare:(QLFCredentialValidationResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCredentialValidationResult:(QLFCredentialValidationResult *)other;
- (NSUInteger)hash;

@end


@interface QLFCredentialValidity : QLFCredentialValidationResult



+ (QLFCredentialValidationResult *)credentialValidity;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFCredentialValidity *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCredentialValidity:(QLFCredentialValidity *)other;
- (NSUInteger)hash;

@end


@interface QLFCertificateChainRevoked : QLFCredentialValidationResult



+ (QLFCredentialValidationResult *)certificateChainRevoked;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFCertificateChainRevoked *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCertificateChainRevoked:(QLFCertificateChainRevoked *)other;
- (NSUInteger)hash;

@end


@interface QLFCredentialRevoked : QLFCredentialValidationResult



+ (QLFCredentialValidationResult *)credentialRevoked;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFCredentialRevoked *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCredentialRevoked:(QLFCredentialRevoked *)other;
- (NSUInteger)hash;

@end


@interface QLFCredentialExpired : QLFCredentialValidationResult



+ (QLFCredentialValidationResult *)credentialExpired;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFCredentialExpired *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCredentialExpired:(QLFCredentialExpired *)other;
- (NSUInteger)hash;

@end


@interface QLFCredentialNotValid : QLFCredentialValidationResult



+ (QLFCredentialValidationResult *)credentialNotValid;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFCredentialNotValid *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCredentialNotValid:(QLFCredentialNotValid *)other;
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


@interface QLFKeySlot : NSObject<QredoMarshallable>

@property (readonly) QLFKeySlotNumber slotNumber;
@property (readonly) QLFBlindingKey *blindingKey;
@property (readonly) NSSet *nextBlindingKey;

+ (QLFKeySlot *)keySlotWithSlotNumber:(QLFKeySlotNumber)slotNumber blindingKey:(QLFBlindingKey *)blindingKey nextBlindingKey:(NSSet *)nextBlindingKey;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSlotNumber:(QLFKeySlotNumber)slotNumber blindingKey:(QLFBlindingKey *)blindingKey nextBlindingKey:(NSSet *)nextBlindingKey;
- (NSComparisonResult)compare:(QLFKeySlot *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToKeySlot:(QLFKeySlot *)other;
- (NSUInteger)hash;

@end


@interface QLFGetKeySlotsResponse : NSObject<QredoMarshallable>

@property (readonly) QLFKeySlotNumber currentKeySlotNumber;
@property (readonly) NSSet *keySlots;

+ (QLFGetKeySlotsResponse *)getKeySlotsResponseWithCurrentKeySlotNumber:(QLFKeySlotNumber)currentKeySlotNumber keySlots:(NSSet *)keySlots;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithCurrentKeySlotNumber:(QLFKeySlotNumber)currentKeySlotNumber keySlots:(NSSet *)keySlots;
- (NSComparisonResult)compare:(QLFGetKeySlotsResponse *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToGetKeySlotsResponse:(QLFGetKeySlotsResponse *)other;
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


@interface QLFRendezvousCreateResult : NSObject<QredoMarshallable>



+ (QLFRendezvousCreateResult *)rendezvousCreated;

+ (QLFRendezvousCreateResult *)rendezvousAlreadyExists;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousCreated:(void (^)())ifRendezvousCreatedBlock ifRendezvousAlreadyExists:(void (^)())ifRendezvousAlreadyExistsBlock;
- (NSComparisonResult)compare:(QLFRendezvousCreateResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousCreateResult:(QLFRendezvousCreateResult *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousCreated : QLFRendezvousCreateResult



+ (QLFRendezvousCreateResult *)rendezvousCreated;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
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


@interface QLFRendezvousDeleteResult : NSObject<QredoMarshallable>



+ (QLFRendezvousDeleteResult *)rendezvousDeleteSuccessful;

+ (QLFRendezvousDeleteResult *)rendezvousDeleteRejected;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousDeleteSuccessful:(void (^)())ifRendezvousDeleteSuccessfulBlock ifRendezvousDeleteRejected:(void (^)())ifRendezvousDeleteRejectedBlock;
- (NSComparisonResult)compare:(QLFRendezvousDeleteResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousDeleteResult:(QLFRendezvousDeleteResult *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousDeleteSuccessful : QLFRendezvousDeleteResult



+ (QLFRendezvousDeleteResult *)rendezvousDeleteSuccessful;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousDeleteSuccessful *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousDeleteSuccessful:(QLFRendezvousDeleteSuccessful *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousDeleteRejected : QLFRendezvousDeleteResult



+ (QLFRendezvousDeleteResult *)rendezvousDeleteRejected;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFRendezvousDeleteRejected *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousDeleteRejected:(QLFRendezvousDeleteRejected *)other;
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


@interface QLFGetAccessTokenResponse : NSObject<QredoMarshallable>



+ (QLFGetAccessTokenResponse *)accessGrantedWithSignedBlindedToken:(QLFSignedBlindedToken *)signedBlindedToken slotNumber:(QLFKeySlotNumber)slotNumber remainingSecondsUntilTokenExpires:(int64_t)remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:(int64_t)remainingSecondsUntilNextTokenIsAvailable;

+ (QLFGetAccessTokenResponse *)accessDenied;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifAccessGranted:(void (^)(QLFSignedBlindedToken *, QLFKeySlotNumber , int64_t , int64_t ))ifAccessGrantedBlock ifAccessDenied:(void (^)())ifAccessDeniedBlock;
- (NSComparisonResult)compare:(QLFGetAccessTokenResponse *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToGetAccessTokenResponse:(QLFGetAccessTokenResponse *)other;
- (NSUInteger)hash;

@end


@interface QLFAccessGranted : QLFGetAccessTokenResponse

@property (readonly) QLFSignedBlindedToken *signedBlindedToken;
@property (readonly) QLFKeySlotNumber slotNumber;
@property (readonly) int64_t remainingSecondsUntilTokenExpires;
@property (readonly) int64_t remainingSecondsUntilNextTokenIsAvailable;

+ (QLFGetAccessTokenResponse *)accessGrantedWithSignedBlindedToken:(QLFSignedBlindedToken *)signedBlindedToken slotNumber:(QLFKeySlotNumber)slotNumber remainingSecondsUntilTokenExpires:(int64_t)remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:(int64_t)remainingSecondsUntilNextTokenIsAvailable;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSignedBlindedToken:(QLFSignedBlindedToken *)signedBlindedToken slotNumber:(QLFKeySlotNumber)slotNumber remainingSecondsUntilTokenExpires:(int64_t)remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:(int64_t)remainingSecondsUntilNextTokenIsAvailable;
- (NSComparisonResult)compare:(QLFAccessGranted *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAccessGranted:(QLFAccessGranted *)other;
- (NSUInteger)hash;

@end


@interface QLFAccessDenied : QLFGetAccessTokenResponse



+ (QLFGetAccessTokenResponse *)accessDenied;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)init;
- (NSComparisonResult)compare:(QLFAccessDenied *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAccessDenied:(QLFAccessDenied *)other;
- (NSUInteger)hash;

@end


@interface QLFAuthenticatedClaim : NSObject<QredoMarshallable>

@property (readonly) QLFCredentialValidationResult *validity;
@property (readonly) QLFAuthenticationCode *claimHash;
@property (readonly) NSString *attesterInfo;

+ (QLFAuthenticatedClaim *)authenticatedClaimWithValidity:(QLFCredentialValidationResult *)validity claimHash:(QLFAuthenticationCode *)claimHash attesterInfo:(NSString *)attesterInfo;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithValidity:(QLFCredentialValidationResult *)validity claimHash:(QLFAuthenticationCode *)claimHash attesterInfo:(NSString *)attesterInfo;
- (NSComparisonResult)compare:(QLFAuthenticatedClaim *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAuthenticatedClaim:(QLFAuthenticatedClaim *)other;
- (NSUInteger)hash;

@end


@interface QLFAuthenticationResponse : NSObject<QredoMarshallable>

@property (readonly) NSArray *credentialValidationResults;
@property (readonly) BOOL sameIdentity;
@property (readonly) NSData *authenticatorCertChain;
@property (readonly) NSData *signature;

+ (QLFAuthenticationResponse *)authenticationResponseWithCredentialValidationResults:(NSArray *)credentialValidationResults sameIdentity:(BOOL)sameIdentity authenticatorCertChain:(NSData *)authenticatorCertChain signature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithCredentialValidationResults:(NSArray *)credentialValidationResults sameIdentity:(BOOL)sameIdentity authenticatorCertChain:(NSData *)authenticatorCertChain signature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFAuthenticationResponse *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAuthenticationResponse:(QLFAuthenticationResponse *)other;
- (NSUInteger)hash;

@end


@interface QLFClaim : NSObject<QredoMarshallable>

@property (readonly) NSSet *name;
@property (readonly) NSString *datatype;
@property (readonly) NSData *value;

+ (QLFClaim *)claimWithName:(NSSet *)name datatype:(NSString *)datatype value:(NSData *)value;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithName:(NSSet *)name datatype:(NSString *)datatype value:(NSData *)value;
- (NSComparisonResult)compare:(QLFClaim *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToClaim:(QLFClaim *)other;
- (NSUInteger)hash;

@end


@interface QLFAttestationRequest : NSObject<QredoMarshallable>

@property (readonly) NSString *attestationId;
@property (readonly) QLFAuthenticationKey256 *identityPubKey;
@property (readonly) NSSet *claims;
@property (readonly) NSData *signature;

+ (QLFAttestationRequest *)attestationRequestWithAttestationId:(NSString *)attestationId identityPubKey:(QLFAuthenticationKey256 *)identityPubKey claims:(NSSet *)claims signature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithAttestationId:(NSString *)attestationId identityPubKey:(QLFAuthenticationKey256 *)identityPubKey claims:(NSSet *)claims signature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFAttestationRequest *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAttestationRequest:(QLFAttestationRequest *)other;
- (NSUInteger)hash;

@end


@interface QLFCredential : NSObject<QredoMarshallable>

@property (readonly) NSString *serialNumber;
@property (readonly) NSData *claimant;
@property (readonly) NSData *hashedClaim;
@property (readonly) NSString *notBefore;
@property (readonly) NSString *notAfter;
@property (readonly) NSString *revocationLocator;
@property (readonly) NSString *attesterInfo;
@property (readonly) NSData *signature;

+ (QLFCredential *)credentialWithSerialNumber:(NSString *)serialNumber claimant:(NSData *)claimant hashedClaim:(NSData *)hashedClaim notBefore:(NSString *)notBefore notAfter:(NSString *)notAfter revocationLocator:(NSString *)revocationLocator attesterInfo:(NSString *)attesterInfo signature:(NSData *)signature;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithSerialNumber:(NSString *)serialNumber claimant:(NSData *)claimant hashedClaim:(NSData *)hashedClaim notBefore:(NSString *)notBefore notAfter:(NSString *)notAfter revocationLocator:(NSString *)revocationLocator attesterInfo:(NSString *)attesterInfo signature:(NSData *)signature;
- (NSComparisonResult)compare:(QLFCredential *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToCredential:(QLFCredential *)other;
- (NSUInteger)hash;

@end


@interface QLFAttestation : NSObject<QredoMarshallable>

@property (readonly) QLFClaim *claim;
@property (readonly) QLFCredential *credential;

+ (QLFAttestation *)attestationWithClaim:(QLFClaim *)claim credential:(QLFCredential *)credential;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithClaim:(QLFClaim *)claim credential:(QLFCredential *)credential;
- (NSComparisonResult)compare:(QLFAttestation *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAttestation:(QLFAttestation *)other;
- (NSUInteger)hash;

@end


@interface QLFAttestationResponse : NSObject<QredoMarshallable>

@property (readonly) NSString *attestationId;
@property (readonly) NSSet *attestations;

+ (QLFAttestationResponse *)attestationResponseWithAttestationId:(NSString *)attestationId attestations:(NSSet *)attestations;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithAttestationId:(NSString *)attestationId attestations:(NSSet *)attestations;
- (NSComparisonResult)compare:(QLFAttestationResponse *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAttestationResponse:(QLFAttestationResponse *)other;
- (NSUInteger)hash;

@end


@interface QLFClaimMessage : NSObject<QredoMarshallable>

@property (readonly) QLFAuthenticationCode *claimHash;
@property (readonly) QLFCredential *credential;

+ (QLFClaimMessage *)claimMessageWithClaimHash:(QLFAuthenticationCode *)claimHash credential:(QLFCredential *)credential;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithClaimHash:(QLFAuthenticationCode *)claimHash credential:(QLFCredential *)credential;
- (NSComparisonResult)compare:(QLFClaimMessage *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToClaimMessage:(QLFClaimMessage *)other;
- (NSUInteger)hash;

@end


@interface QLFAuthenticationRequest : NSObject<QredoMarshallable>

@property (readonly) NSArray *claimMessages;
@property (readonly) QLFEncryptionKey256 *conversationSecret;

+ (QLFAuthenticationRequest *)authenticationRequestWithClaimMessages:(NSArray *)claimMessages conversationSecret:(QLFEncryptionKey256 *)conversationSecret;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithClaimMessages:(NSArray *)claimMessages conversationSecret:(QLFEncryptionKey256 *)conversationSecret;
- (NSComparisonResult)compare:(QLFAuthenticationRequest *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToAuthenticationRequest:(QLFAuthenticationRequest *)other;
- (NSUInteger)hash;

@end


@interface QLFPresentation : NSObject<QredoMarshallable>

@property (readonly) NSSet *attestations;

+ (QLFPresentation *)presentationWithAttestations:(NSSet *)attestations;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithAttestations:(NSSet *)attestations;
- (NSComparisonResult)compare:(QLFPresentation *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToPresentation:(QLFPresentation *)other;
- (NSUInteger)hash;

@end


@interface QLFPresentationRequest : NSObject<QredoMarshallable>

@property (readonly) NSSet *requestedAttestationTypes;
@property (readonly) NSString *authenticator;

+ (QLFPresentationRequest *)presentationRequestWithRequestedAttestationTypes:(NSSet *)requestedAttestationTypes authenticator:(NSString *)authenticator;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithRequestedAttestationTypes:(NSSet *)requestedAttestationTypes authenticator:(NSString *)authenticator;
- (NSComparisonResult)compare:(QLFPresentationRequest *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToPresentationRequest:(QLFPresentationRequest *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationDescriptor : NSObject<QredoMarshallable>

@property (readonly) NSString *rendezvousTag;
@property (readonly) BOOL amRendezvousOwner;
@property (readonly) QLFConversationId *conversationId;
@property (readonly) NSString *conversationType;
@property (readonly) QLFRendezvousAuthType *authenticationType;
@property (readonly) QLFKeyPairLF *myKey;
@property (readonly) QLFKeyLF *yourPublicKey;
@property (readonly) QLFKeyLF *inboundBulkKey;
@property (readonly) QLFKeyLF *outboundBulkKey;
@property (readonly) NSSet *initialTransCap;

+ (QLFConversationDescriptor *)conversationDescriptorWithRendezvousTag:(NSString *)rendezvousTag amRendezvousOwner:(BOOL)amRendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey inboundBulkKey:(QLFKeyLF *)inboundBulkKey outboundBulkKey:(QLFKeyLF *)outboundBulkKey initialTransCap:(NSSet *)initialTransCap;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithRendezvousTag:(NSString *)rendezvousTag amRendezvousOwner:(BOOL)amRendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey inboundBulkKey:(QLFKeyLF *)inboundBulkKey outboundBulkKey:(QLFKeyLF *)outboundBulkKey initialTransCap:(NSSet *)initialTransCap;
- (NSComparisonResult)compare:(QLFConversationDescriptor *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationDescriptor:(QLFConversationDescriptor *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousCreationInfo : NSObject<QredoMarshallable>

@property (readonly) QLFRendezvousHashedTag *hashedTag;
@property (readonly) QLFRendezvousAuthType *authenticationType;
@property (readonly) NSString *conversationType;
@property (readonly) NSSet *durationSeconds;
@property (readonly) NSSet *maxResponseCount;
@property (readonly) NSSet *transCap;
@property (readonly) QLFRequesterPublicKey *requesterPublicKey;
@property (readonly) QLFAccessControlPublicKey *accessControlPublicKey;
@property (readonly) QLFAuthenticationCode *authenticationCode;

+ (QLFRendezvousCreationInfo *)rendezvousCreationInfoWithHashedTag:(QLFRendezvousHashedTag *)hashedTag authenticationType:(QLFRendezvousAuthType *)authenticationType conversationType:(NSString *)conversationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount transCap:(NSSet *)transCap requesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey accessControlPublicKey:(QLFAccessControlPublicKey *)accessControlPublicKey authenticationCode:(QLFAuthenticationCode *)authenticationCode;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithHashedTag:(QLFRendezvousHashedTag *)hashedTag authenticationType:(QLFRendezvousAuthType *)authenticationType conversationType:(NSString *)conversationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount transCap:(NSSet *)transCap requesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey accessControlPublicKey:(QLFAccessControlPublicKey *)accessControlPublicKey authenticationCode:(QLFAuthenticationCode *)authenticationCode;
- (NSComparisonResult)compare:(QLFRendezvousCreationInfo *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousCreationInfo:(QLFRendezvousCreationInfo *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousDescriptor : NSObject<QredoMarshallable>

@property (readonly) NSString *tag;
@property (readonly) QLFRendezvousHashedTag *hashedTag;
@property (readonly) NSString *conversationType;
@property (readonly) QLFRendezvousAuthType *authenticationType;
@property (readonly) NSSet *durationSeconds;
@property (readonly) NSSet *maxResponseCount;
@property (readonly) NSSet *transCap;
@property (readonly) QLFKeyPairLF *requesterKeyPair;
@property (readonly) QLFKeyPairLF *accessControlKeyPair;

+ (QLFRendezvousDescriptor *)rendezvousDescriptorWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount transCap:(NSSet *)transCap requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair accessControlKeyPair:(QLFKeyPairLF *)accessControlKeyPair;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount transCap:(NSSet *)transCap requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair accessControlKeyPair:(QLFKeyPairLF *)accessControlKeyPair;
- (NSComparisonResult)compare:(QLFRendezvousDescriptor *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousDescriptor:(QLFRendezvousDescriptor *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousRespondResult : NSObject<QredoMarshallable>



+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithCreationInfo:(QLFRendezvousCreationInfo *)creationInfo;

+ (QLFRendezvousRespondResult *)rendezvousResponseUnknownTag;

+ (QLFRendezvousRespondResult *)rendezvousResponseRejectedWithReason:(QLFRendezvousResponseRejectionReason *)reason;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifRendezvousResponseRegistered:(void (^)(QLFRendezvousCreationInfo *))ifRendezvousResponseRegisteredBlock ifRendezvousResponseUnknownTag:(void (^)())ifRendezvousResponseUnknownTagBlock ifRendezvousResponseRejected:(void (^)(QLFRendezvousResponseRejectionReason *))ifRendezvousResponseRejectedBlock;
- (NSComparisonResult)compare:(QLFRendezvousRespondResult *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToRendezvousRespondResult:(QLFRendezvousRespondResult *)other;
- (NSUInteger)hash;

@end


@interface QLFRendezvousResponseRegistered : QLFRendezvousRespondResult

@property (readonly) QLFRendezvousCreationInfo *creationInfo;

+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithCreationInfo:(QLFRendezvousCreationInfo *)creationInfo;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithCreationInfo:(QLFRendezvousCreationInfo *)creationInfo;
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


@interface QLFSV : NSObject<QredoMarshallable>



+ (QLFSV *)sBoolWithV:(BOOL)v;

+ (QLFSV *)sInt64WithV:(int64_t)v;

+ (QLFSV *)sDTWithV:(QredoUTCDateTime *)v;

+ (QLFSV *)sQUIDWithV:(QredoQUID *)v;

+ (QLFSV *)sStringWithV:(NSString *)v;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (void)ifSBool:(void (^)(BOOL ))ifSBoolBlock ifSInt64:(void (^)(int64_t ))ifSInt64Block ifSDT:(void (^)(QredoUTCDateTime *))ifSDTBlock ifSQUID:(void (^)(QredoQUID *))ifSQUIDBlock ifSString:(void (^)(NSString *))ifSStringBlock;
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


@interface QLFConversationMessageMetaDataLF : NSObject<QredoMarshallable>

@property (readonly) QLFConversationMessageId *id;
@property (readonly) NSSet *parentId;
@property (readonly) QLFConversationSequenceValue *sequence;
@property (readonly) NSString *dataType;
@property (readonly) NSSet *summaryValues;

+ (QLFConversationMessageMetaDataLF *)conversationMessageMetaDataLFWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence dataType:(NSString *)dataType summaryValues:(NSSet *)summaryValues;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence dataType:(NSString *)dataType summaryValues:(NSSet *)summaryValues;
- (NSComparisonResult)compare:(QLFConversationMessageMetaDataLF *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationMessageMetaDataLF:(QLFConversationMessageMetaDataLF *)other;
- (NSUInteger)hash;

@end


@interface QLFConversationMessageLF : NSObject<QredoMarshallable>

@property (readonly) QLFConversationMessageMetaDataLF *metadata;
@property (readonly) NSData *value;

+ (QLFConversationMessageLF *)conversationMessageLFWithMetadata:(QLFConversationMessageMetaDataLF *)metadata value:(NSData *)value;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithMetadata:(QLFConversationMessageMetaDataLF *)metadata value:(NSData *)value;
- (NSComparisonResult)compare:(QLFConversationMessageLF *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToConversationMessageLF:(QLFConversationMessageLF *)other;
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


@interface QLFVaultItemMetaDataLF : NSObject<QredoMarshallable>

@property (readonly) NSString *dataType;
@property (readonly) int32_t accessLevel;
@property (readonly) NSSet *summaryValues;

+ (QLFVaultItemMetaDataLF *)vaultItemMetaDataLFWithDataType:(NSString *)dataType accessLevel:(int32_t)accessLevel summaryValues:(NSSet *)summaryValues;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithDataType:(NSString *)dataType accessLevel:(int32_t)accessLevel summaryValues:(NSSet *)summaryValues;
- (NSComparisonResult)compare:(QLFVaultItemMetaDataLF *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItemMetaDataLF:(QLFVaultItemMetaDataLF *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultItemLF : NSObject<QredoMarshallable>

@property (readonly) QLFVaultItemMetaDataLF *metadata;
@property (readonly) NSData *value;

+ (QLFVaultItemLF *)vaultItemLFWithMetadata:(QLFVaultItemMetaDataLF *)metadata value:(NSData *)value;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithMetadata:(QLFVaultItemMetaDataLF *)metadata value:(NSData *)value;
- (NSComparisonResult)compare:(QLFVaultItemLF *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItemLF:(QLFVaultItemLF *)other;
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
@property (readonly) NSSet *keyStore;

+ (QLFVaultInfoType *)vaultInfoTypeWithVaultID:(QLFVaultId *)vaultID keyStore:(NSSet *)keyStore;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithVaultID:(QLFVaultId *)vaultID keyStore:(NSSet *)keyStore;
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


@interface QLFEncryptedVaultItemMetaData : NSObject<QredoMarshallable>

@property (readonly) QLFVaultId *vaultId;
@property (readonly) QLFVaultSequenceId *sequenceId;
@property (readonly) QLFVaultSequenceValue sequenceValue;
@property (readonly) QLFVaultItemId *itemId;
@property (readonly) NSData *encryptedHeaders;

+ (QLFEncryptedVaultItemMetaData *)encryptedVaultItemMetaDataWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId encryptedHeaders:(NSData *)encryptedHeaders;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId encryptedHeaders:(NSData *)encryptedHeaders;
- (NSComparisonResult)compare:(QLFEncryptedVaultItemMetaData *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedVaultItemMetaData:(QLFEncryptedVaultItemMetaData *)other;
- (NSUInteger)hash;

@end


@interface QLFEncryptedVaultItem : NSObject<QredoMarshallable>

@property (readonly) QLFEncryptedVaultItemMetaData *meta;
@property (readonly) NSData *encryptedValue;

+ (QLFEncryptedVaultItem *)encryptedVaultItemWithMeta:(QLFEncryptedVaultItemMetaData *)meta encryptedValue:(NSData *)encryptedValue;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithMeta:(QLFEncryptedVaultItemMetaData *)meta encryptedValue:(NSData *)encryptedValue;
- (NSComparisonResult)compare:(QLFEncryptedVaultItem *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToEncryptedVaultItem:(QLFEncryptedVaultItem *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultItemDescriptorLF : NSObject<QredoMarshallable>

@property (readonly) QLFVaultId *vaultId;
@property (readonly) QLFVaultSequenceId *sequenceId;
@property (readonly) QLFVaultSequenceValue sequenceValue;
@property (readonly) QLFVaultItemId *itemId;

+ (QLFVaultItemDescriptorLF *)vaultItemDescriptorLFWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId;
- (NSComparisonResult)compare:(QLFVaultItemDescriptorLF *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItemDescriptorLF:(QLFVaultItemDescriptorLF *)other;
- (NSUInteger)hash;

@end


@interface QLFVaultItemMetaDataResults : NSObject<QredoMarshallable>

@property (readonly) NSArray *results;
@property (readonly) BOOL current;
@property (readonly) NSSet *sequenceIds;

+ (QLFVaultItemMetaDataResults *)vaultItemMetaDataResultsWithResults:(NSArray *)results current:(BOOL)current sequenceIds:(NSSet *)sequenceIds;

+ (QredoMarshaller)marshaller;

+ (QredoUnmarshaller)unmarshaller;

- (instancetype)initWithResults:(NSArray *)results current:(BOOL)current sequenceIds:(NSSet *)sequenceIds;
- (NSComparisonResult)compare:(QLFVaultItemMetaDataResults *)other;
- (BOOL)isEqualTo:(id)other;
- (BOOL)isEqualToVaultItemMetaDataResults:(QLFVaultItemMetaDataResults *)other;
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
- (void)publishWithQueueId:(QLFConversationQueueId *)queueId item:(QLFConversationItem *)item completionHandler:(void(^)(QLFConversationPublishResult *result, NSError *error))completionHandler;
- (void)queryItemsWithQueueId:(QLFConversationQueueId *)queueId after:(NSSet *)after fetchSize:(NSSet *)fetchSize completionHandler:(void(^)(QLFConversationQueryItemsResult *result, NSError *error))completionHandler;
- (void)acknowledgeReceiptWithQueueId:(QLFConversationQueueId *)queueId upTo:(QLFConversationSequenceValue *)upTo completionHandler:(void(^)(QLFConversationAckResult *result, NSError *error))completionHandler;
- (void)subscribeWithQueueId:(QLFConversationQueueId *)queueId completionHandler:(void(^)(QLFConversationItemWithSequenceValue *result, NSError *error))completionHandler;

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
- (void)respondWithResponse:(QLFRendezvousResponse *)response completionHandler:(void(^)(QLFRendezvousRespondResult *result, NSError *error))completionHandler;
- (void)getChallengeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag completionHandler:(void(^)(QLFNonce *result, NSError *error))completionHandler;
- (void)getResponsesWithHashedTag:(QLFRendezvousHashedTag *)hashedTag challenge:(QLFNonce *)challenge signature:(QLFAccessControlSignature *)signature after:(QLFRendezvousSequenceValue)after completionHandler:(void(^)(QLFRendezvousResponsesResult *result, NSError *error))completionHandler;
- (void)subscribeToResponsesWithHashedTag:(QLFRendezvousHashedTag *)hashedTag challenge:(QLFNonce *)challenge signature:(QLFAccessControlSignature *)signature completionHandler:(void(^)(QLFRendezvousResponseWithSequenceValue *result, NSError *error))completionHandler;
- (void)deleteWithHashedTag:(QLFRendezvousHashedTag *)hashedTag challenge:(QLFNonce *)challenge signature:(QLFAccessControlSignature *)signature completionHandler:(void(^)(QLFRendezvousDeleteResult *result, NSError *error))completionHandler;

@end


@interface QLFAccess : NSObject



+ (QLFAccess *)accessWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;
- (void)getKeySlotsWithCompletionHandler:(void(^)(QLFGetKeySlotsResponse *result, NSError *error))completionHandler;
- (void)getAccessTokenWithAccountId:(QLFAccountId *)accountId accountCredential:(QLFAccountCredential *)accountCredential blindedToken:(QLFBlindedToken *)blindedToken slotNumber:(QLFKeySlotNumber)slotNumber completionHandler:(void(^)(QLFGetAccessTokenResponse *result, NSError *error))completionHandler;
- (void)getNextAccessTokenWithAccountId:(QLFAccountId *)accountId accountCredential:(QLFAccountCredential *)accountCredential blindedToken:(QLFBlindedToken *)blindedToken slotNumber:(QLFKeySlotNumber)slotNumber completionHandler:(void(^)(QLFGetAccessTokenResponse *result, NSError *error))completionHandler;

@end


@interface QLFVault : NSObject



+ (QLFVault *)vaultWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker;
- (void)putItemWithItem:(QLFEncryptedVaultItem *)item completionHandler:(void(^)(BOOL result, NSError *error))completionHandler;
- (void)getItemWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(NSSet *)sequenceValue itemId:(QLFVaultItemId *)itemId completionHandler:(void(^)(NSSet *result, NSError *error))completionHandler;
- (void)getItemMetaDataWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(NSSet *)sequenceValue itemId:(QLFVaultItemId *)itemId completionHandler:(void(^)(NSSet *result, NSError *error))completionHandler;
- (void)queryItemMetaDataWithVaultId:(QLFVaultId *)vaultId sequenceStates:(NSSet *)sequenceStates completionHandler:(void(^)(QLFVaultItemMetaDataResults *result, NSError *error))completionHandler;

@end



