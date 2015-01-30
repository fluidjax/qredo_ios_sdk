/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoQUID.h"
#import "QredoConversation.h"
#import "QredoTypes.h"
#import "QredoVault.h"
#import "QredoRendezvous.h"
#import "QredoErrorCodes.h"

// Revision 1
// See https://github.com/Qredo/ios-sdk/wiki/SDK-revisions

/** Options for [QredoClient initWithServiceURL:options:] */
extern NSString *const QredoClientOptionServiceURL;
extern NSString *const QredoRendezvousURIProtocol;

@class QredoClient;
@class QredoRendezvousMetadata;

@interface QredoClientOptions : NSObject

@property BOOL useMQTT;
@property BOOL resetData;


- (instancetype)initWithMQTT:(BOOL)useMQTT;
- (instancetype)initWithMQTT:(BOOL)useMQTT resetData:(BOOL)resetData;
- (instancetype)initWithResetData:(BOOL)resetData;

@end

/** Qredo Client */
@interface QredoClient : NSObject
/** Before using the SDK, the application should call this function with the required conversation types and vault data types.
 During the authorization the SDK may ask user to allow access to their Qredo account.
 
 If the app calls any Vault, Rendezvous or Conversation API without an authorization, then those methods will return `QredoErrorCodeAppNotAuthorized` error immediately.
 */
+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes vaultDataTypes:(NSArray*)vaultDataTypes completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler;

+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes vaultDataTypes:(NSArray*)vaultDataTypes options:(QredoClientOptions*)options completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler;

+ (void)openSettings;

- (void)closeSession;
- (BOOL)isClosed;

- (QredoVault*) defaultVault;

@end

@interface QredoClient (Rendezvous)

/** Creates a rendezvous and automatically stores it in the vault */
- (void)createRendezvousWithTag:(NSString *)tag configuration:(QredoRendezvousConfiguration *)configuration completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Enumerates through the rendezvous that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
- (void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
- (void)fetchRendezvousWithTag:(NSString *)tag completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
- (void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Joins the rendezvous and stores conversation into the vault */
- (void)respondWithTag:(NSString *)tag completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler;

/** Enumerates through the conversations that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
- (void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;

- (void)fetchConversationWithId:(QredoQUID*)conversationId completionHandler:(void(^)(QredoConversation* conversation, NSError *error))completionHandler;

- (void)deleteConversationWithId:(QredoQUID*)conversationId completionHandler:(void(^)(NSError *error))completionHandler;

@end

@class QredoVendorAttestation;
@class QredoVendorAttestationMetadata; // name, tag
@class QredoVendorAttestationSession;

@interface QredoClient (Attestation)

- (void)registerVendorAttestation:(NSArray*)attestationTypes /* dob, photo */
                completionHandler:(void(^)(QredoVendorAttestation *vendorAttestation, NSError *error))completionHandler;

- (void)enumeratateVendorAttestationsWithBlock:(void(^)(QredoVendorAttestation *vendorAttestation, BOOL *stop))block
                             completionHandler:(void(^)(NSError *error))completionHandler;

@end

@protocol QredoVendorAttestationDelegate <NSObject>

@required
- (void)qredoVendorAttestation:(QredoVendorAttestation*)vendorAttestation didReceivePresenterSession:(QredoVendorAttestationSession*)vendorAttestationSession;

@optional
- (void)qredoVendorAttestation:(QredoVendorAttestation*)vendorAttestation didFinishPresenterSession:(QredoVendorAttestationSession*)vendorAttestationSession;

@end

@interface QredoVendorAttestation : NSObject

@property QredoVendorAttestationMetadata *metadata;

@property id<QredoVendorAttestationDelegate> delegate;

// return only new
- (void)startListening;
- (void)stopListening;

// return only active
- (void)enumeratePresentersWithBlock:(void(^)(QredoVendorAttestationSession *))block completionHandler:(void(^)(NSError *error))completionHandler;
@end

@interface QredoAuthenticationResult : NSObject

@property BOOL verified;
// signature and other crap

@property NSError *error;

@end

typedef NS_ENUM(NSUInteger, QredoAuthenticationStatus) {
    QredoAuthenticationStatusAuthenticating,
    QredoAuthenticationStatusReceivedResult,
    QredoAuthenticationStatusFailed
};

@interface QredoClaim : NSObject

@property NSString *name;
@property NSString *dataType;
@property NSData   *value;

@property QredoAuthenticationStatus authenticationStatus;
@property QredoAuthenticationResult *authenticationResult;

@end

@protocol QredoVendorAttestationSessionDelegate <NSObject>

@required
- (void)qredoVendorAttestationSession:(QredoVendorAttestationSession*)session didReceiveClaims:(NSArray /* QredoClaim */ *)claims;
- (void)qredoVendorAttestationSessionDidFinishAuthentication:(QredoVendorAttestationSession *)session;

@optional
- (void)qredoVendorAttestationSession:(QredoVendorAttestationSession*)session claim:(QredoClaim *)claim didChangeStatusTo:(QredoAuthenticationStatus)status;

@end

@interface QredoVendorAttestationSession : NSObject

// if claims are received before the delegate is set, then didReceiveClaims: will be called straight after receiving claims
@property id<QredoVendorAttestationSessionDelegate> delegate;

- (void)startAuthentication;

- (void)cancelWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)finishAttestationWithResult:(BOOL)result completionHandler:(void(^)(NSError *error))completionHandler;

@end
