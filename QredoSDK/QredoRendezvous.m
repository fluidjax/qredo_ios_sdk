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

@interface QredoRendezvous ()
{
    QredoClient *_client;
    QredoRendezvousHighWatermark _highWatermark;

    QredoInternalRendezvous *_rendezvous;
    QredoVault *_vault;
    QredoDhPrivateKey *_requesterPrivateKey;
    QredoRendezvousHashedTag *_hashedTag;
    QredoRendezvousDescriptor *_descriptor;
    BOOL _subscribedToResponses;
    NSMutableDictionary *_dedupeStore; // Key is response, value is sequence number (as getResponses can return multiple responses for a single sequence number)
    BOOL _dedupeNecessary; // Dedupe only necessary during subscription setup - once subsequent query has completed, dedupe no longer required
    BOOL _queryAfterSubscribeComplete; // Indicates that the Query after Subscribe has completed, and no more entries to process

    NSString *_tag;

    dispatch_queue_t _enumerationQueue;

    // Listener
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
    dispatch_queue_t _subscriptionRenewalQueue;
    dispatch_source_t _subscriptionRenewalTimer;

    int scheduled, responded; // TODO: use locks for queues
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
    _dedupeStore = [[NSMutableDictionary alloc] init];
    LogDebug(@"Created Rendezvous dedupe dictionary (%p): %@", _dedupeStore, _dedupeStore);

    _enumerationQueue = dispatch_queue_create("com.qredo.rendezvous.enumrate", nil);

    _queue = dispatch_queue_create("com.qredo.rendezvous.updates", nil);
    _subscriptionRenewalQueue = dispatch_queue_create("com.qredo.rendezvous.subscriptionRenewal", nil);

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

    [_client.systemVault strictlyPutNewItem:vaultItem itemId:itemId completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
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
    // If we support multi-response, then use it, otherwise poll
    if (_client.serviceInvoker.supportsMultiResponse)
    {
        LogDebug(@"Starting subscription to conversations");
        [self startSubscribing];
    }
    else
    {
        LogDebug(@"Starting polling for conversations");
        [self startPolling];
    }
}

- (void)stopListening
{
    // If we support multi-response, then use it, otherwise poll
    if (_client.serviceInvoker.supportsMultiResponse)
    {
        [self stopSubscribing];
    }
    else
    {
        [self stopPolling];
    }
}

// This method enables subscription (push) for responses to rendezvous, and creates new conversations from them. Will regularly re-send subsription request as subscriptions can fail silently
- (void)startSubscribing
{
    NSAssert(_delegate, @"Rendezvous delegate should be set before starting listening for the updates");

    if (_subscribedToResponses) {
        LogDebug(@"Already subscribed to responses, and cannot currently unsubscribe, so ignoring request.");
        return;
    }

    // Setup re-subscribe timer first
    @synchronized (self) {
        if (_subscriptionRenewalTimer) return;
        
        _subscriptionRenewalTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _subscriptionRenewalQueue);
        if (_subscriptionRenewalTimer)
        {
            dispatch_source_set_timer(_subscriptionRenewalTimer,
                                      dispatch_time(DISPATCH_TIME_NOW,
                                                    kQredoRendezvousRenewSubscriptionInterval * NSEC_PER_SEC), // start
                                      kQredoRendezvousRenewSubscriptionInterval * NSEC_PER_SEC, // interval
                                      (1ull * NSEC_PER_SEC) / 10); // how much it can defer from the interval
            dispatch_source_set_event_handler(_subscriptionRenewalTimer, ^{
                @synchronized (self) {
                    LogDebug(@"Rendezvous subscription renewal timer fired");

                    if (!_subscriptionRenewalTimer) {
                        return;
                    }
                    
                    // Should be able to keep subscribing without any side effects, but try to unsubscribing first
                    [self unsubscribe];
                    [self subscribe];
                }
            });
            dispatch_resume(_subscriptionRenewalTimer);
        }
    }
    
    // Start first subscription
    [self subscribe];
}

- (void)subscribe
{
    NSAssert(_delegate, @"Rendezvous delegate should be set before starting listening for the updates");
    
    LogDebug(@"Subscribing to new responses/conversations.");
    
    // TODO: DH - look at blocks holding strong reference to self, and whether that's causing
    // Subscribe to conversations newer than our highwatermark
    [self subscribeToConversationsWithBlock:^(QredoConversation *conversation) {
        
        LogDebug(@"Rendezvous subscription returned conversation: %@", conversation);
        
        if ([_delegate respondsToSelector:@selector(qredoRendezvous:didReceiveReponse:)]) {
            [_delegate qredoRendezvous:self didReceiveReponse:conversation];
        }
        
    } subscriptionTerminatedHandler:^(NSError *error) {
        
        LogError("Rendezvous subscription terminated with error: %@", error);
        _subscribedToResponses = NO;
        
    } since:self.highWatermark highWatermarkHandler:^(QredoRendezvousHighWatermark newWatermark) {
        
        LogDebug(@"Rendezvous subscription returned new HighWatermark: %llu", newWatermark);
        
        self->_highWatermark = newWatermark;
    }];
}

- (void)unsubscribe
{
    // TODO: DH - No current way to stop subscribing, short of disconnecting from server. Services team may add support for this in future.
    LogDebug(@"NOTE: Cannot currently unsubscribe from Rendezvous responses.  This request is ignored.");
}

// This method disables subscription (push) for responses to rendezvous
- (void)stopSubscribing
{
    // Need to stop the subsription renewal timer as well
    @synchronized (self) {
        if (_subscriptionRenewalTimer) {
            LogDebug(@"Stoping rendezvous subscription renewal timer");
            dispatch_source_cancel(_subscriptionRenewalTimer);
            _subscriptionRenewalTimer = nil;
        }
    }
    
    [self unsubscribe];
}

// This method polls for (new) responses to rendezvous, and creates new conversations from them.
- (void)startPolling
{
    NSAssert(_delegate, @"Rendezvous delegate should be set before starting listening for the updates");

    @synchronized (self) {
        if (_timer) return;

        scheduled = 0;
        responded = 0;

        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
        if (_timer)
        {
            dispatch_block_t pollingBlock = ^{
                @synchronized (self) {
                    if (!_timer) return;

                    if (scheduled != responded) {
                        return;
                    }
                    scheduled++;

                    [self enumerateConversationsWithBlock:^(QredoConversation *conversation, BOOL *stop) {
                        @synchronized (self) {
                            if (!_timer) return ;
                            if ([_delegate respondsToSelector:@selector(qredoRendezvous:didReceiveReponse:)]) {
                                [_delegate qredoRendezvous:self didReceiveReponse:conversation];
                            }
                        }
                    } completionHandler:^(NSError *error) {
                        // TODO: DH - need to deal with any error returned - e.g. may indicate transport has been terminated
                        responded++;
                    } since:self.highWatermark highWatermarkHandler:^(QredoRendezvousHighWatermark newWatermark) {
                        self->_highWatermark = newWatermark;
                    }];
                }
            };

            dispatch_async(_queue, pollingBlock);

            dispatch_source_set_timer(_timer,
                                      dispatch_time(DISPATCH_TIME_NOW, kQredoRendezvousUpdateInterval * NSEC_PER_SEC), // start
                                      kQredoRendezvousUpdateInterval * NSEC_PER_SEC, // interval
                                      (1ull * NSEC_PER_SEC) / 10); // how much it can defer from the interval
            dispatch_source_set_event_handler(_timer, pollingBlock);
            dispatch_resume(_timer);
        }
    }
}

- (void)stopPolling
{
    @synchronized (self) {
        if (_timer) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
    }
}

- (BOOL)isDuplicateOrOldResponse:(QredoRendezvousResponse *)response sequenceValue:(QredoRendezvousSequenceValue *)sequenceValue
{
    LogDebug(@"Checking for old/duplicate. Response Hashed Tag: %@. Responder Public Key: %@. Responder Auth Code: %@. SequenceValue: %@.", response.hashedTag, response.responderPublicKey, response.responderAuthenticationCode, sequenceValue);
    
    LogDebug(@"Rendezvous dedupe dictionary contains %lu items.", (unsigned long)_dedupeStore.count);
    LogDebug(@"Rendezvous dedupe dictionary (%p): %@", _dedupeStore, _dedupeStore);

    BOOL responseIsDuplicate = NO;
    
    // A duplicate response is being taken to be a specific response which has the same sequence value
    @synchronized(_dedupeStore) {
        QredoRendezvousSequenceValue *fetchedSequenceValue = [_dedupeStore objectForKey:response];
        
        if (!fetchedSequenceValue) {
            LogDebug(@"Response was not found in dictionary.");
        }

        // If we already seen that response, check the sequence value. We only care about newer sequence values
        if (fetchedSequenceValue && fetchedSequenceValue <= sequenceValue) {
            // Found a duplicate/old response
            responseIsDuplicate = YES;
        }
        else if (_queryAfterSubscribeComplete) {
            // We have completed processing the Query after Subscribe, and we have a non-duplicate Response - therefore we have passed the point where dedupe is required, so can empty the dedupe store
            LogDebug(@"Query completed and have received a non-duplicate response. Passed point where dedupe required - emptying dedupe store and preventing further dedupe.");
            _dedupeNecessary = NO;
            [_dedupeStore removeAllObjects];
        }
        else {
            // Not a duplicate, and Query has not completed, so store this response/sequenceValue pair for later to prevent duplication
            [_dedupeStore setObject:sequenceValue forKey:response];
        }
    }
    
    LogDebug(@"Response is duplicate: %@", responseIsDuplicate ? @"YES" : @"NO");
    return responseIsDuplicate;
}

- (BOOL)processResponse:(QredoRendezvousResponse *)response
          sequenceValue:(QredoRendezvousSequenceValue *)sequenceValue
              withBlock:(void(^)(QredoConversation *conversation))block
           errorHandler:(void (^)(NSError *))errorHandler
{
    BOOL didProcessResponse = NO;
    
    if (_dedupeNecessary) {
        if ([self isDuplicateOrOldResponse:response sequenceValue:sequenceValue]) {
            LogDebug(@"Ignoring duplicate/old rendezvous response. Response: %@. Sequence Value: %@", response, sequenceValue);

            return didProcessResponse;
        }
    }
    else {
        LogDebug(@"No dedupe necessary, rendezvous subscription setup completed.");
    }

    [self createConversationAndStoreKeysForResponse:response completionHandler:^(QredoConversation *conversation, NSError *creationError) {
        if (creationError) {
            errorHandler(creationError);
            return;
        }

        block(conversation);

    }];
    return YES;
}

- (void)subscribeToConversationsWithBlock:(void(^)(QredoConversation *conversation))block
            subscriptionTerminatedHandler:(void (^)(NSError *))subscriptionTerminatedHandler
                                    since:(QredoRendezvousHighWatermark)sinceWatermark
                     highWatermarkHandler:(void(^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler
{
    _subscribedToResponses = YES;

    // Dedupe is necessary when setting up, as will do Subscribe and Query. Both could return the same Response, so need dedupe. Once Query has completed, Subscribe takes over and dedupe no longer required.
    _dedupeNecessary = YES;
    _queryAfterSubscribeComplete = NO;
    
    [_rendezvous getChallengeWithHashedTag:_hashedTag completionHandler:^(NSData *result, NSError *error) {
        if (error) {
            subscriptionTerminatedHandler(error);
            return ;
        }

        NSData *subscriptionNonce = result;
        NSData *subscriptionSignature = [QredoRendezvous signatureForHashedTag:_hashedTag nonce:subscriptionNonce];

        [_rendezvous subscribeToResponsesWithHashedTag:_hashedTag
                                             challenge:subscriptionNonce
                                             signature:subscriptionSignature
                                     completionHandler:^(QredoRendezvousResponseWithSequenceValue *result, NSError *error) {
                                         
                                         LogDebug(@"Rendezvous subscription completion handler called");

                                         if (error) {
                                             subscriptionTerminatedHandler(error);
                                             return ;
                                         }
                                         
                                         BOOL didProcessResponse = [self processResponse:result.response sequenceValue:result.sequenceValue withBlock:block errorHandler:subscriptionTerminatedHandler];

                                         if (didProcessResponse &&
                                             result.sequenceValue &&
                                             highWatermarkHandler) {
                                             highWatermarkHandler(result.sequenceValue.longLongValue);
                                         }
                                     }];
        
        // Must have actually sent the subscription request before getting responses, otherwise chance of invalidating challenege/signatures - only 1 challenge per hashedTag at a time
        LogDebug(@"Getting other responses since HWM");
        [_rendezvous getChallengeWithHashedTag:_hashedTag completionHandler:^(NSData *result, NSError *error) {
            if (error) {
                subscriptionTerminatedHandler(error);
                return ;
            }
            
            NSData *getResponsesNonce = result;
            NSData *getResponsesSignature = [QredoRendezvous signatureForHashedTag:_hashedTag nonce:getResponsesNonce];
            
            // Now query to get responses made whilst subscription being set up. Will need to dedupe as want to avoid multiple notifications for same response (done in processResponse)

            [_rendezvous getResponsesWithHashedTag:_hashedTag
                                         challenge:getResponsesNonce
                                         signature:getResponsesSignature
                                             after:[NSNumber numberWithLongLong:sinceWatermark]
                                 completionHandler:^(QredoRendezvousResponsesResult *result, NSError *error) {
                                     
                                     LogDebug(@"Get rendezvous responses completion handler called");

                                     if (error) {
                                         subscriptionTerminatedHandler(error);
                                         return ;
                                     }
                                     
                                     BOOL didProcessResponse = NO;
                                     
                                     LogDebug(@"Have %lu response(s) to process", (unsigned long)result.responses.count);
                                     
                                     for (QredoRendezvousResponse *response in result.responses) {
                                         BOOL stop = result.responses.lastObject == response;

                                         // OR the flag each time so it's set if at least one response was processed
                                         didProcessResponse |= [self processResponse:response sequenceValue:result.sequenceValue withBlock:block errorHandler:subscriptionTerminatedHandler];
                                         
                                         // TODO: DH - remove deliberate duplication
//                                         LogDebug(@"Deliberately duplicating query response");
//                                         QredoRendezvousResponse *duplicateResponse = [QredoRendezvousResponse rendezvousResponseWithHashedTag:response.hashedTag responderPublicKey:response.responderPublicKey responderAuthenticationCode:response.responderAuthenticationCode];
//                                         [self processResponse:duplicateResponse sequenceValue:result.sequenceValue withBlock:block errorHandler:subscriptionTerminatedHandler];
//                                         didProcessResponse |= [self processResponse:duplicateResponse sequenceValue:result.sequenceValue withBlock:block errorHandler:subscriptionTerminatedHandler];
                                         // TODO: DH - end deliberate duplication
                                         
                                         if (stop) {
                                             break;
                                         }
                                     }
                                     
                                     // HWM handler only called at end as we only have 1 sequence value for the entire query response
                                     if (didProcessResponse &&
                                         result.sequenceValue &&
                                         highWatermarkHandler) {
                                         highWatermarkHandler(result.sequenceValue.longLongValue);
                                     }
                                     
                                     _queryAfterSubscribeComplete = YES;
                                 }];
        }];
    }];
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
                                             block:block
                              highWatermarkHandler:highWatermarkHandler
                                 completionHandler:completionHandler];

         }];
    }];
}

- (void)processRendezvousResponseResult:(QredoRendezvousResponsesResult *)result
                          responseIndex:(NSUInteger)responseIndex
                                  block:(void(^)(QredoConversation *conversation, BOOL *stop))block
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
                                            block:block
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

         block(conversation, &stop);
         
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

@end