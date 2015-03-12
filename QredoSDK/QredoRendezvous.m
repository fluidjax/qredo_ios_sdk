/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoClient.h"
#import "QredoRendezvous.h"
#import "QredoConversationPrivate.h"
#import "QredoVaultPrivate.h"

#import "QredoRendezvousPrivate.h"

#import "QredoRendezvousCrypto.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"
#import "QredoCrypto.h"
#import "QredoVaultCrypto.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"
#import "QredoLogging.h"
#import "QredoRendezvousHelpers.h"
#import "QredoUpdateListener.h"

const QredoRendezvousHighWatermark QredoRendezvousHighWatermarkOrigin = 0;

static const double kQredoRendezvousUpdateInterval = 1.0; // seconds - polling period for responses (non-multi-response transports)
static const double kQredoRendezvousRenewSubscriptionInterval = 300.0; // 5 mins in seconds - auto-renew subscription period (multi-response transports)
NSString *const kQredoRendezvousVaultItemType = @"com.qredo.rendezvous";
NSString *const kQredoRendezvousVaultItemLabelTag = @"tag";

static const int PSS_SALT_LENGTH_IN_BYTES = 32;

@implementation QredoRendezvousMetadata

- (instancetype)initWithTag:(NSString*)tag vaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor {
    self = [super init];
    if (!self) return nil;

    self.tag = tag;
    _vaultItemDescriptor = vaultItemDescriptor;

    return self;
}

- (QredoVaultItemDescriptor *)vaultItemDescriptor {
    return _vaultItemDescriptor;
}

@end

@implementation QredoRendezvousConfiguration

- (instancetype)initWithConversationType:(NSString*)conversationType
{
    return [self initWithConversationType:conversationType durationSeconds:nil maxResponseCount:nil];
}

- (instancetype)initWithConversationType:(NSString*)conversationType durationSeconds:(NSNumber *)durationSeconds maxResponseCount:(NSNumber *)maxResponseCount
{
    return [self initWithConversationType:conversationType durationSeconds:durationSeconds maxResponseCount:maxResponseCount transCap:nil];
}

- (instancetype)initWithConversationType:(NSString*)conversationType durationSeconds:(NSNumber *)durationSeconds maxResponseCount:(NSNumber *)maxResponseCount transCap:(NSSet*)transCap
{
    return [self initWithConversationType:conversationType authenticationType:QredoRendezvousAuthenticationTypeAnonymous durationSeconds:durationSeconds maxResponseCount:maxResponseCount transCap:transCap];
}

- (instancetype)initWithConversationType:(NSString*)conversationType authenticationType:(QredoRendezvousAuthenticationType)authenticationType durationSeconds:(NSNumber *)durationSeconds maxResponseCount:(NSNumber *)maxResponseCount transCap:(NSSet*)transCap
{
    self = [super init];
    if (!self) return nil;
    
    _conversationType = conversationType;
    _authenticationType = authenticationType;
    _durationSeconds = durationSeconds;
    _maxResponseCount = maxResponseCount;
    _transCap = transCap;
    
    return self;
}


@end

@interface QredoRendezvous () <QredoUpdateListenerDataSource, QredoUpdateListenerDelegate>
{
    QredoClient *_client;
    QredoRendezvousHighWatermark _highWatermark;

    QredoInternalRendezvous *_rendezvous;
    QredoVault *_vault;
    QredoDhPrivateKey *_requesterPrivateKey;
    QredoRendezvousHashedTag *_hashedTag;
    QredoRendezvousDescriptor *_descriptor;

    NSString *_tag;

    dispatch_queue_t _enumerationQueue;
    QredoUpdateListener *_updateListener;
    id _subscriptionCorrelationId;
}

// making the properties read/write for private use
@property QredoRendezvousConfiguration *configuration;
@property NSString *tag;

- (NSSet *)maybe:(id)object;

@end

@implementation QredoRendezvous (Private)

- (instancetype)initWithClient:(QredoClient *)client
{
    self = [super init];
    if (!self) return nil;

    _client = client;
    _rendezvous = [QredoInternalRendezvous rendezvousWithServiceInvoker:_client.serviceInvoker];
    _vault = [_client systemVault];

    _enumerationQueue = dispatch_queue_create("com.qredo.rendezvous.enumrate", nil);

    _updateListener = [[QredoUpdateListener alloc] init];
    _updateListener.delegate = self;
    _updateListener.dataSource = self;

    _updateListener.pollInterval = kQredoRendezvousUpdateInterval;
    _updateListener.renewSubscriptionInterval = kQredoRendezvousRenewSubscriptionInterval;

    return self;
}

- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QredoRendezvousDescriptor*)descriptor
{
    self = [self initWithClient:client];
    _descriptor = descriptor;

    _tag = _descriptor.tag;
    _hashedTag = _descriptor.hashedTag;
    _requesterPrivateKey = [[QredoDhPrivateKey alloc] initWithData:descriptor.requesterKeyPair.privKey.bytes];

    return self;
}

- (void)createRendezvousWithTag:(NSString *)tag configuration:(QredoRendezvousConfiguration *)configuration completionHandler:(void(^)(NSError *error))completionHandler
{
    LogDebug(@"Creating rendezvous with (plaintext) tag: %@", tag);
    
    self.configuration = configuration;
    QredoRendezvousCrypto *_crypto = [QredoRendezvousCrypto instance];
    // Box up optional values.
    NSSet *maybeDurationSeconds  = [self maybe:configuration.durationSeconds];
    NSSet *maybeMaxResponseCount = [self maybe:configuration.maxResponseCount];
    NSSet *maybeTransCap         = [self maybe:nil]; // TODO: review when TransCap is defined

    NSError *error = nil;
    id<QredoRendezvousCreateHelper> rendezvousHelper = [_crypto rendezvousHelperForAuthenticationType:self.configuration.authenticationType prefix:tag error:&error];
    if (!rendezvousHelper) {
        // TODO [GR]: Filter what errors we pass to the user. What we are currently passing may
        // be to much information.
        completionHandler(error);
        return;
    }
    _tag = [rendezvousHelper tag];

    // Hash the tag.
    QredoAuthenticationCode *authKey = [_crypto authKey:_tag];
    _hashedTag  = [_crypto hashedTagWithAuthKey:authKey];

    LogDebug(@"Hashed tag: %@", _hashedTag);

    // Generate the rendezvous key pairs.
    QredoKeyPairLF *accessControlKeyPair = [_crypto newAccessControlKeyPairWithId:[_hashedTag QUIDString]];
    QredoKeyPairLF *requesterKeyPair     = [_crypto newRequesterKeyPair];

    _requesterPrivateKey = [[QredoDhPrivateKey alloc] initWithData: requesterKeyPair.privKey.bytes];

    NSData *accessControlPublicKeyBytes  = [[accessControlKeyPair pubKey] bytes];
    NSData *requesterPublicKeyBytes      = [[requesterKeyPair pubKey] bytes];
    
    
    // Generate the authentication code.
    QredoAuthenticationCode *authenticationCode
    = [_crypto authenticationCodeWithHashedTag:_hashedTag
                              conversationType:configuration.conversationType
                               durationSeconds:maybeDurationSeconds
                              maxResponseCount:maybeMaxResponseCount
                                      transCap:maybeTransCap
                            requesterPublicKey:requesterPublicKeyBytes
                        accessControlPublicKey:accessControlPublicKeyBytes
                             authenticationKey:authKey
                              rendezvousHelper:rendezvousHelper];

    QredoRendezvousAuthType *authType = nil;
    if ([rendezvousHelper type] == QredoRendezvousAuthenticationTypeAnonymous) {
        authType= [QredoRendezvousAuthType rendezvousAnonymous];
    } else {
        QredoRendezvousAuthSignature *authSignature = [rendezvousHelper signatureWithData:authenticationCode error:&error];
        if (!authSignature) {
            // TODO [GR]: Filter what errors we pass to the user. What we are currently passing may
            // be to much information.
            completionHandler(error);
            return;
        }
        authType = [QredoRendezvousAuthType rendezvousTrustedWithSignature:authSignature];
    }
    
    // Create the Rendezvous.
    QredoRendezvousCreationInfo *_creationInfo =
    [QredoRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:_hashedTag
                                                  authenticationType:authType
                                                    conversationType:configuration.conversationType
                                                     durationSeconds:maybeDurationSeconds
                                                    maxResponseCount:maybeMaxResponseCount
                                                            transCap:maybeTransCap
                                                  requesterPublicKey:requesterPublicKeyBytes
                                              accessControlPublicKey:accessControlPublicKeyBytes
                                                  authenticationCode:authenticationCode];
    _descriptor =
    [QredoRendezvousDescriptor rendezvousDescriptorWithTag:_tag
                                                 hashedTag:_hashedTag
                                          conversationType:configuration.conversationType
                                           durationSeconds:maybeDurationSeconds
                                          maxResponseCount:maybeMaxResponseCount
                                                  transCap:maybeTransCap
                                          requesterKeyPair:requesterKeyPair
                                      accessControlKeyPair:accessControlKeyPair];

    [_rendezvous createWithCreationInfo:_creationInfo
                      completionHandler:^(QredoRendezvousCreateResult *result, NSError *error) {
                          if (error) {
                              completionHandler(error);
                              return;
                          }

                          [result ifCreated:^{
                              [self storeWithCompletionHandler:^(NSError *error) {
                                  completionHandler(error);
                              }];
                          } ifAlreadyExists:^{
                              completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                                    code:QredoErrorCodeRendezvousAlreadyExists
                                                                userInfo:@{NSLocalizedDescriptionKey: @"Rendezvous with the specified tag already exists"}]);
                          }];
                      }];
}

- (void)storeWithCompletionHandler:(void(^)(NSError* error))completionHandler
{
    QredoVault *vault = _client.systemVault;

    QredoVaultItemId *itemId = [vault itemIdWithName:_tag type:kQredoRendezvousVaultItemType];

    NSData *serializedDescriptor = [QredoPrimitiveMarshallers marshalObject:_descriptor
                                                                 marshaller:[QredoClientMarshallers rendezvousDescriptorMarshaller]];

    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:kQredoRendezvousVaultItemType
                                                                                 accessLevel:0
                                                                               summaryValues:@{kQredoRendezvousVaultItemLabelTag: _tag}];

    QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:serializedDescriptor];

    [_client.systemVault strictlyPutNewItem:vaultItem itemId:itemId completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
        completionHandler(error);
    }];
}

@end

@implementation QredoRendezvous

- (NSSet *)maybe:(id)object {
    return (object == nil ? [NSSet new] : [NSSet setWithObject:object]);
}

- (void)resetHighWatermark
{
    _highWatermark = QredoRendezvousHighWatermarkOrigin;
}

- (void)deleteWithCompletionHandler:(void (^)(NSError *error))completionHandler
{
    // TODO: implement later
}

- (void)startListening
{
    [_updateListener startListening];
}

- (void)stopListening
{
    [_updateListener stopListening];
}

- (BOOL)processResponse:(QredoRendezvousResponse *)response
          sequenceValue:(QredoRendezvousSequenceValue *)sequenceValue
              withBlock:(void(^)(QredoConversation *conversation))block
           errorHandler:(void (^)(NSError *))errorHandler
{

    return YES;
}

- (void)enumerateConversationsWithBlock:(void(^)(QredoConversation *conversation, BOOL *stop))block
                      completionHandler:(void (^)(NSError *))completionHandler
{
    [self enumerateConversationsWithBlock:block since:QredoRendezvousHighWatermarkOrigin completionHandler:completionHandler];
}

- (void)enumerateConversationsWithBlock:(void(^)(QredoConversation *conversation, BOOL *stop))block
                                  since:(QredoRendezvousHighWatermark)sinceWatermark
                         completionHandler:(void(^)(NSError *error))completionHandler
{
    [self enumerateConversationsWithBlock:block completionHandler:completionHandler since:sinceWatermark highWatermarkHandler:nil];
}

- (void)enumerateConversationsWithBlock:(void(^)(QredoConversation *conversation, BOOL *stop))block
                      completionHandler:(void(^)(NSError *error))completionHandler
                                  since:(QredoRendezvousHighWatermark)sinceWatermark
                   highWatermarkHandler:(void(^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler

{
    [self enumerateResponsesWithBlock:^(QredoRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop)
    {
        block(conversation, stop);
    }
                    completionHandler:completionHandler
                                since:sinceWatermark
                 highWatermarkHandler:highWatermarkHandler];
}


- (void)enumerateResponsesWithBlock:(void(^)(QredoRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop))block
                  completionHandler:(void(^)(NSError *error))completionHandler
                              since:(QredoRendezvousHighWatermark)sinceWatermark
               highWatermarkHandler:(void(^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler
{

    [_rendezvous getChallengeWithHashedTag:_hashedTag completionHandler:^(NSData *result, NSError *error) {
        if (error) {
            completionHandler(error);
            return ;
        }

        NSData *nonce = result;
        NSData *signature = [QredoRendezvous signatureForHashedTag:_hashedTag nonce:nonce];

        [_rendezvous getResponsesWithHashedTag:_hashedTag
                                     challenge:nonce
                                     signature:signature
                                         after:[NSNumber numberWithLongLong:sinceWatermark]
                             completionHandler:^(QredoRendezvousResponsesResult *result, NSError *error)
         {
             if (error) {
                 completionHandler(error);
                 return ;
             }

             LogDebug(@"Enumerating %lu response(s)", (unsigned long)result.responses.count);

             [self processRendezvousResponseResult:result
                                     responseIndex:0
                           rendezvousResponseBlock:block
                              highWatermarkHandler:highWatermarkHandler
                                 completionHandler:completionHandler];

         }];
    }];
}

- (void)processRendezvousResponseResult:(QredoRendezvousResponsesResult *)result
                          responseIndex:(NSUInteger)responseIndex
                rendezvousResponseBlock:(void(^)(QredoRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop))rendezvousResponseBlock
                   highWatermarkHandler:(void(^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler
                      completionHandler:(void(^)(NSError *error))completionHandler
{
    void (^finishEnumeration)() = ^{
        if (result.sequenceValue && highWatermarkHandler) {
            highWatermarkHandler(result.sequenceValue.longLongValue);
        }

        completionHandler(nil);
    };

    void (^continueToNextItem)() = ^{
        dispatch_async(_enumerationQueue, ^{
            [self processRendezvousResponseResult:result
                                    responseIndex:responseIndex + 1
                          rendezvousResponseBlock:rendezvousResponseBlock
                             highWatermarkHandler:highWatermarkHandler
                                completionHandler:completionHandler];
        });

    };

    if (responseIndex >= result.responses.count) {
        finishEnumeration();
        return;
    }

    QredoRendezvousResponse *response = [result.responses objectAtIndex:responseIndex];

    [self createConversationAndStoreKeysForResponse:response
                                  completionHandler:^(QredoConversation *conversation, NSError *error)
     {
         if (error && error.code == QredoErrorCodeVaultItemNotFound) {
             continueToNextItem();
             return ;
         }

         BOOL stop = result.responses.lastObject == response;

         if (!conversation && !error) {
             // Might need to ignore the error, because there is not way for the client application to continue enumeration after this point
             error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousUnknownResponse
                                     userInfo:@{NSLocalizedDescriptionKey: @"Could not create conversation from response"}];
         }

         if (error) {
             completionHandler(error);
             return;
         }

         rendezvousResponseBlock(result, conversation, &stop);

         if (stop) {
             finishEnumeration();
             return;
         }
         
         continueToNextItem();
     }];

}

+ (NSData *)signatureForHashedTag:(QredoRendezvousHashedTag *)hashedTag nonce:(NSData *)nonce
{
    QredoRendezvousCrypto *crypto = [QredoRendezvousCrypto instance];
    SecKeyRef key = [crypto accessControlPrivateKeyWithTag:[hashedTag QUIDString]];

    NSMutableData *dataToSign = [NSMutableData dataWithData:[hashedTag data]];
    [dataToSign appendData:nonce];

    NSData *signature = [QredoCrypto rsaPssSignMessage:dataToSign saltLength:PSS_SALT_LENGTH_IN_BYTES keyRef:key];

    return signature;
}

- (void)createConversationAndStoreKeysForResponse:(QredoRendezvousResponse *)response
                                completionHandler:(void(^)(QredoConversation *conversation, NSError *error))completionHandler
{
    QredoConversation *conversation = [[QredoConversation alloc] initWithClient:_client
                                                                  rendezvousTag:_tag
                                                                converationType:_configuration.conversationType
                                                                       transCap:_configuration.transCap];
    QredoDhPublicKey *responderPublicKey = [[QredoDhPublicKey alloc] initWithData:response.responderPublicKey];
    
    [conversation generateAndStoreKeysWithPrivateKey:_requesterPrivateKey
                                           publicKey:responderPublicKey
                                     rendezvousOwner:YES
                                   completionHandler:^(NSError *error)
     {
         if (error) {
             completionHandler(nil, error);
             return ;
         }

         completionHandler(conversation, nil);
     }];
}

- (QredoRendezvousMetadata*)metadata {
    QredoVault *vault = _client.systemVault;

    QredoVaultItemId *itemId = [vault itemIdWithName:_tag type:kQredoRendezvousVaultItemType];
    QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:itemId];

    return [[QredoRendezvousMetadata alloc] initWithTag:self.tag vaultItemDescriptor:descriptor];
}

#pragma mark -
#pragma mark Qredo Update Listener - Data Source
- (BOOL)qredoUpdateListenerDoesSupportMultiResponseQuery:(QredoUpdateListener *)updateListener
{
    return _client.serviceInvoker.supportsMultiResponse;
}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
  pollWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    [self enumerateResponsesWithBlock:^(QredoRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop) {
        [_updateListener processSingleItem:conversation sequenceValue:rendezvousResponse.sequenceValue];
    }
                    completionHandler:completionHandler
                                since:self.highWatermark
                 highWatermarkHandler:^(QredoRendezvousHighWatermark newWatermark)
    {
        self->_highWatermark = newWatermark;
    }];
}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
subscribeWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    NSAssert(_delegate, @"Rendezvous delegate should be set before starting listening for the updates");

    LogDebug(@"Subscribing to new responses/conversations. self=%@", self);

    NSAssert(_subscriptionCorrelationId == nil, @"Already subscribed");

    // TODO: DH - look at blocks holding strong reference to self, and whether that's causing
    // Subscribe to conversations newer than our highwatermark
    [_rendezvous getChallengeWithHashedTag:_hashedTag completionHandler:^(NSData *result, NSError *error) {
        if (error) {
            completionHandler(error);
            return ;
        }

        NSData *subscriptionNonce = result;
        NSData *subscriptionSignature = [QredoRendezvous signatureForHashedTag:_hashedTag nonce:subscriptionNonce];

        _subscriptionCorrelationId = [_rendezvous subscribeToResponsesWithHashedTag:_hashedTag
                                             challenge:subscriptionNonce
                                             signature:subscriptionSignature
                                         resultHandler:^(QredoRendezvousResponseWithSequenceValue *result)
         {
             LogDebug(@"Rendezvous subscription result handler called. Correlation id = %@", _subscriptionCorrelationId);

             [self createConversationAndStoreKeysForResponse:result.response
                                           completionHandler:^(QredoConversation *conversation, NSError *creationError)
              {
                  if (creationError) {
                      completionHandler(error);
                      return;
                  }


                  LogDebug(@"Rendezvous subscription returned conversation: %@, self=%@, updateListener=%@", conversation, self, _updateListener);

                  [_updateListener processSingleItem:conversation sequenceValue:result.sequenceValue];

              }];

             LogDebug(@"Rendezvous subscription returned new HighWatermark: %llu", result.sequenceValue.longLongValue);
             self->_highWatermark = result.sequenceValue.longLongValue;
         } completionHandler:^(NSError *error) {
             completionHandler(error);
             if (error) {
                 [_updateListener didTerminateSubscriptionWithError:error];
             }
         }
         ];
        LogDebug(@"SUBSCRIBE correlation id=%@", _subscriptionCorrelationId);
    }];
}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
unsubscribeWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    LogDebug(@"UNSUBSCRIBE correlation id=%@", _subscriptionCorrelationId);
    [_rendezvous unsubscribeWithCorrelationId:_subscriptionCorrelationId completionHandler:^(NSError *error) {
        _subscriptionCorrelationId = nil;
        completionHandler(error);
    }];
}

#pragma mark Qredo Update Listener - Delegate

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item
{
    QredoConversation *conversation = (QredoConversation *)item;

    if ([_delegate respondsToSelector:@selector(qredoRendezvous:didReceiveReponse:)]) {
        [_delegate qredoRendezvous:self didReceiveReponse:conversation];
    }
}

@end