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

const QredoRendezvousHighWatermark QredoRendezvousHighWatermarkOrigin = 0;

static const double kQredoRendezvousUpdateInterval = 1.0; // seconds
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
    self = [super init];
    if (!self) return nil;

    _conversationType = conversationType;
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
    NSMutableDictionary *_dedupeStore; // Key is response, value is sequence number (as getResponses can return multiple responses for a sinlge sequence number)

    NSString *_tag;

    // Listener
    dispatch_queue_t _queue;
    dispatch_source_t _timer;

    int scheduled, responded; // TODO use locks for queues
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

    _queue = dispatch_queue_create("com.qredo.rendezvous.updates", nil);

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
    NSSet *maybeTransCap         = [self maybe:nil]; // TODO review when TransCap is defined

    _tag = tag;

    // Hash the tag.
    QredoAuthenticationCode *authKey = [_crypto authKey:tag];
    _hashedTag  = [_crypto hashedTagWithAuthKey:authKey];

    LogDebug(@"Hashed tag: %@", _hashedTag);

    // Generate the rendezvous key pairs.
    QredoKeyPairLF *accessControlKeyPair = [_crypto newAccessControlKeyPairWithId:[_hashedTag QUIDString]];
    QredoKeyPairLF *requesterKeyPair     = [_crypto newRequesterKeyPair];

    _requesterPrivateKey = [[QredoDhPrivateKey alloc] initWithData: requesterKeyPair.privKey.bytes];

    NSData *accessControlPublicKeyBytes  = [[accessControlKeyPair pubKey] bytes];
    NSData *requesterPublicKeyBytes      = [[requesterKeyPair pubKey] bytes];

    // Generate the authentication code.
    QredoAuthenticationCode *authenticationCode =
    [_crypto authenticationCodeWithHashedTag:_hashedTag
                          authenticationType:[QredoRendezvousAuthType rendezvousAnonymous] // TODO:
                            conversationType:configuration.conversationType
                             durationSeconds:maybeDurationSeconds
                            maxResponseCount:maybeMaxResponseCount
                                    transCap:maybeTransCap
                          requesterPublicKey:requesterPublicKeyBytes
                      accessControlPublicKey:accessControlPublicKeyBytes
                           authenticationKey:authKey];

    // Create the Rendezvous.
    QredoRendezvousCreationInfo *_creationInfo =
    [QredoRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:_hashedTag
     authenticationType:[QredoRendezvousAuthType rendezvousAnonymous] // TODO:
                                                    conversationType:configuration.conversationType
                                                     durationSeconds:maybeDurationSeconds
                                                    maxResponseCount:maybeMaxResponseCount
                                                            transCap:maybeTransCap
                                                  requesterPublicKey:requesterPublicKeyBytes
                                              accessControlPublicKey:accessControlPublicKeyBytes
                                                  authenticationCode:authenticationCode];
    _descriptor =
    [QredoRendezvousDescriptor rendezvousDescriptorWithTag:tag
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
    // TODO implement later
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

// This method enables subscription (push) for responses to rendezvous, and creates new conversations form them
- (void)startSubscribing
{
    NSAssert(_delegate, @"Delegate should be set before starting listening for the updates");

    if (_subscribedToResponses) {
        LogDebug(@"Already subscribed to responses, and cannot currently unsubscribe, so ignoring request.");
        return;
    }
    
    // Subscribe to conversations newer than our highwatermark
    [self subscribeToConversationsWithBlock:^(QredoConversation *conversation) {

        LogDebug(@"Subscription returned conversation: %@", conversation);
        
        if ([_delegate respondsToSelector:@selector(qredoRendezvous:didReceiveReponse:)]) {
            [_delegate qredoRendezvous:self didReceiveReponse:conversation];
        }
        
    } subscriptionTerminatedHandler:^(NSError *error) {

        LogError("Subscription terminated with error: %@", error);
        _subscribedToResponses = NO;

    } since:self.highWatermark highWatermarkHandler:^(QredoRendezvousHighWatermark newWatermark) {

        LogDebug(@"Subscription returned new HighWatermark: %llu", newWatermark);
        
        self->_highWatermark = newWatermark;

    }];
}

// This method disables subscription (push) for responses to rendezvous
- (void)stopSubscribing
{
    // TODO: DH - No current way to stop subscribing, short of disconnecting from server. Services team may add support for this in future.
    LogDebug(@"NOTE: Cannot currently unsubscribe.  This request is ignored.");
}

// This method polls for (new) responses to rendezvous, and creates new conversations from them.
- (void)startPolling
{
    NSAssert(_delegate, @"Delegate should be set before starting listening for the updates");

    @synchronized (self) {
        if (_timer) return;

        scheduled = 0;
        responded = 0;

        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
        if (_timer)
        {
            dispatch_source_set_timer(_timer,
                                      dispatch_time(DISPATCH_TIME_NOW, kQredoRendezvousUpdateInterval * NSEC_PER_SEC), // start
                                      kQredoRendezvousUpdateInterval * NSEC_PER_SEC, // interval
                                      (1ull * NSEC_PER_SEC) / 10); // how much it can defer from the interval
            dispatch_source_set_event_handler(_timer, ^{
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
            });
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
    
    LogDebug(@"Dictionary contains %lu items.", _dedupeStore.count);

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
    }
    
    // TODO: DH - deal with size of dictionary - should not just keep growing
    
    LogDebug(@"Response is duplicate: %@", responseIsDuplicate ? @"YES" : @"NO");
    return responseIsDuplicate;
}

- (BOOL)processResponse:(QredoRendezvousResponse *)response sequenceValue:(QredoRendezvousSequenceValue *)sequenceValue withBlock:(void(^)(QredoConversation *conversation))block errorHandler:(void (^)(NSError *))errorHandler
{
    BOOL didProcessResponse = NO;
    
    if ([self isDuplicateOrOldResponse:response sequenceValue:sequenceValue]) {
        LogDebug(@"Ignoring duplicate/old rendezvous response. Response: %@. Sequence Value: %@", response, sequenceValue);
    }
    else {
        NSError *creationError = nil;
        QredoConversation *conversation = [self createConversationAndStoreKeysForResponse:response error:creationError];
        
        if (creationError) {
            errorHandler(creationError);
            return didProcessResponse;
        }

        @synchronized(_dedupeStore) {
            // Success, so store this response/sequenceValue pair for later to prevent duplication
            [_dedupeStore setObject:sequenceValue forKey:response];
        }

        block(conversation);
        
        didProcessResponse = YES;
    }
    
    return didProcessResponse;
}

- (void)subscribeToConversationsWithBlock:(void(^)(QredoConversation *conversation))block
            subscriptionTerminatedHandler:(void (^)(NSError *))subscriptionTerminatedHandler
                                    since:(QredoRendezvousHighWatermark)sinceWatermark
                     highWatermarkHandler:(void(^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler
{
    _subscribedToResponses = YES;

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

                                         // TODO: DH - remove deliberate duplication
//                                         QredoRendezvousResponse *duplicateResponse = [QredoRendezvousResponse rendezvousResponseWithHashedTag:result.response.hashedTag responderPublicKey:result.response.responderPublicKey responderAuthenticationCode:result.response.responderAuthenticationCode];
//                                         [self processResponse:duplicateResponse sequenceValue:result.sequenceValue withBlock:block errorHandler:subscriptionTerminatedHandler];
                                         // TODO: DH - end deliberate duplication

                                         if (didProcessResponse &&
                                             result.sequenceValue &&
                                             highWatermarkHandler) {
                                             highWatermarkHandler(result.sequenceValue.longLongValue);
                                         }
                                     }];
        
        // Must have actually sent the subscription request before getting responses, otherwise chance of invalidating challenege/signatures - only 1 challenge per hashedTag at a time
        LogDebug(@"Getting other responses to ensure none missed during subscription setup.");
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
//                                         QredoRendezvousResponse *duplicateResponse = [QredoRendezvousResponse rendezvousResponseWithHashedTag:response.hashedTag responderPublicKey:response.responderPublicKey responderAuthenticationCode:response.responderAuthenticationCode];
//                                         [self processResponse:duplicateResponse sequenceValue:result.sequenceValue withBlock:block errorHandler:subscriptionTerminatedHandler];
                                         // TODO: DH - end deliberate duplication
                                         
                                         if (stop) {
                                             break;
                                         }
                                     }
                                     
                                     if (didProcessResponse &&
                                         result.sequenceValue &&
                                         highWatermarkHandler) {
                                         highWatermarkHandler(result.sequenceValue.longLongValue);
                                     }
                                     
                                     // TODO: DH - clear out dedupe store?
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
                             completionHandler:^(QredoRendezvousResponsesResult *result, NSError *error) {
                                 if (error) {
                                     completionHandler(error);
                                     return ;
                                 }

                                 LogDebug(@"Enumerating %lu response(s)", (unsigned long)result.responses.count);
                                 
                                 for (QredoRendezvousResponse *response in result.responses) {
                                     BOOL stop = result.responses.lastObject == response;

                                     NSError *localError = nil;
                                     QredoConversation *conversation = [self createConversationAndStoreKeysForResponse:response error:localError];

                                     if (localError) {
                                         completionHandler(localError);
                                         return;
                                     }

                                     block(conversation, &stop);

                                     if (stop) {
                                         break;
                                     }
                                 }

                                 if (result.sequenceValue && highWatermarkHandler) {
                                     highWatermarkHandler(result.sequenceValue.longLongValue);
                                 }

                                 completionHandler(nil);
                             }];
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

- (QredoConversation *)createConversationAndStoreKeysForResponse:(QredoRendezvousResponse *)response error:(NSError *)error
{
    QredoConversation *conversation = [[QredoConversation alloc] initWithClient:_client
                                                                  rendezvousTag:_tag
                                                                converationType:_configuration.conversationType
                                                                       transCap:_configuration.transCap];
    QredoDhPublicKey *responderPublicKey = [[QredoDhPublicKey alloc] initWithData:response.responderPublicKey];
    
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *savingError = nil;
    
    [conversation generateAndStoreKeysWithPrivateKey:_requesterPrivateKey publicKey:responderPublicKey rendezvousOwner:YES completionHandler:^(NSError *blockError) {
        savingError = blockError;
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (savingError) {
        // Do not return a valid object if we could not save the keys, but return the error
        error = savingError;
        conversation = nil;
    }
    
    return conversation;
}

- (QredoRendezvousMetadata*)metadata {
    QredoVault *vault = _client.systemVault;

    QredoVaultItemId *itemId = [vault itemIdWithName:_tag type:kQredoRendezvousVaultItemType];
    QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:itemId];

    return [[QredoRendezvousMetadata alloc] initWithTag:self.tag vaultItemDescriptor:descriptor];
}

@end