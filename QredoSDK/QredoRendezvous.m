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
#import "QredoLogging.h"
#import "QredoRendezvousHelpers.h"
#import "QredoUpdateListener.h"

#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoSigner.h"

const QredoRendezvousHighWatermark QredoRendezvousHighWatermarkOrigin = 0;

static const double kQredoRendezvousUpdateInterval = 1.0; // seconds - polling period for responses (non-multi-response transports)
static const double kQredoRendezvousRenewSubscriptionInterval = 300.0; // 5 mins in seconds - auto-renew subscription period (multi-response transports)
NSString *const kQredoRendezvousVaultItemType = @"com.qredo.rendezvous";
NSString *const kQredoRendezvousVaultItemLabelTag = @"tag";
NSString *const kQredoRendezvousVaultItemLabelAuthenticationType = @"authenticationType";

@implementation QredoRendezvousMetadata

- (instancetype)initWithTag:(NSString*)tag
         authenticationType:(QredoRendezvousAuthenticationType)authenticationType
        vaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor
{
    self = [super init];
    if (!self) return nil;

    _tag = [tag copy];
    _authenticationType = authenticationType;
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
    
    _conversationType = [conversationType copy];
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

    QLFRendezvous *_rendezvous;
    QredoVault *_vault;
    QredoDhPrivateKey *_requesterPrivateKey;
    QLFRendezvousHashedTag *_hashedTag;
    QLFRendezvousDescriptor *_descriptor;

    QLFRendezvousAuthType *_lfAuthType;

    SecKeyRef _ownershipPrivateKey;

    NSString *_tag;

    dispatch_queue_t _enumerationQueue;
    QredoUpdateListener *_updateListener;
    id _subscriptionCorrelationId;
}

// making the properties read/write for private use
@property QredoRendezvousConfiguration *configuration;
@property (readwrite, copy) NSString *tag;
@property (readwrite) QredoRendezvousAuthenticationType authenticationType;

- (NSSet *)maybe:(id)object;

@end

@implementation QredoRendezvous (Private)

- (instancetype)initWithClient:(QredoClient *)client
{
    self = [super init];
    if (!self) return nil;

    _client = client;
    _rendezvous = [QLFRendezvous rendezvousWithServiceInvoker:_client.serviceInvoker];
    _vault = [_client systemVault];

    _enumerationQueue = dispatch_queue_create("com.qredo.rendezvous.enumrate", nil);

    _updateListener = [[QredoUpdateListener alloc] init];
    _updateListener.delegate = self;
    _updateListener.dataSource = self;

    _updateListener.pollInterval = kQredoRendezvousUpdateInterval;
    _updateListener.renewSubscriptionInterval = kQredoRendezvousRenewSubscriptionInterval;

    return self;
}

- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QLFRendezvousDescriptor*)descriptor
{
    self = [self initWithClient:client];
    _descriptor = descriptor;

    _lfAuthType = _descriptor.authenticationType;
    _tag = _descriptor.tag;
    _hashedTag = _descriptor.hashedTag;
    _requesterPrivateKey = [[QredoDhPrivateKey alloc] initWithData:descriptor.requesterKeyPair.privKey.bytes];
    _ownershipPrivateKey = [[QredoRendezvousCrypto instance] accessControlPrivateKeyWithTag:[_hashedTag QUIDString]];

    return self;
}

- (void)createRendezvousWithTag:(NSString *)tag
             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                  configuration:(QredoRendezvousConfiguration *)configuration
                 signingHandler:(signDataBlock)signingHandler
              completionHandler:(void(^)(NSError *error))completionHandler
{
    LogDebug(@"Creating rendezvous with (plaintext) tag: %@", tag);
    
    // TODO: DH - write tests 
    // TODO: DH - validate that the configuration and tag formats match
    
    self.configuration = configuration;
    QredoRendezvousCrypto *_crypto = [QredoRendezvousCrypto instance];
    // Box up optional values.
    NSSet *maybeDurationSeconds  = [self maybe:configuration.durationSeconds];
    NSSet *maybeMaxResponseCount = [self maybe:configuration.maxResponseCount];
    NSSet *maybeTransCap         = [self maybe:nil]; // TODO: review when TransCap is defined

    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> rendezvousHelper = [_crypto rendezvousHelperForAuthenticationType:authenticationType
                                                                                              fullTag:tag
                                                                                       signingHandler:signingHandler
                                                                                                error:&error];
    if (!rendezvousHelper) {
        // TODO: [GR]: Filter what errors we pass to the user. What we are currently passing may
        // be to much information.
        completionHandler(error);
        return;
    }
    _tag = [rendezvousHelper tag];

    // Hash the tag.
    QLFAuthenticationCode *authKey = [_crypto authKey:_tag];
    _hashedTag  = [_crypto hashedTagWithAuthKey:authKey];

    LogDebug(@"Hashed tag: %@", _hashedTag);

    // Generate the rendezvous key pairs.
    QLFKeyPairLF *accessControlKeyPair = [_crypto newAccessControlKeyPairWithId:[_hashedTag QUIDString]];
    QLFKeyPairLF *requesterKeyPair     = [_crypto newRequesterKeyPair];

    _requesterPrivateKey = [[QredoDhPrivateKey alloc] initWithData: requesterKeyPair.privKey.bytes];

    _ownershipPrivateKey = [_crypto accessControlPrivateKeyWithTag:[_hashedTag QUIDString]];

    NSData *accessControlPublicKeyBytes  = [[accessControlKeyPair pubKey] bytes];
    NSData *requesterPublicKeyBytes      = [[requesterKeyPair pubKey] bytes];
    
    
    // Generate the authentication code.
    QLFAuthenticationCode *authenticationCode
    = [_crypto authenticationCodeWithHashedTag:_hashedTag
                              conversationType:configuration.conversationType
                               durationSeconds:maybeDurationSeconds
                              maxResponseCount:maybeMaxResponseCount
                                      transCap:maybeTransCap
                            requesterPublicKey:requesterPublicKeyBytes
                        accessControlPublicKey:accessControlPublicKeyBytes
                             authenticationKey:authKey
                              rendezvousHelper:rendezvousHelper];

    QLFRendezvousAuthType *authType = nil;
    if ([rendezvousHelper type] == QredoRendezvousAuthenticationTypeAnonymous) {
        authType = [QLFRendezvousAuthType rendezvousAnonymous];
    } else {
        QLFRendezvousAuthSignature *authSignature = [rendezvousHelper signatureWithData:authenticationCode error:&error];
        if (!authSignature) {
            // TODO: [GR]: Filter what errors we pass to the user. What we are currently passing may
            // be to much information.
            completionHandler(error);
            return;
        }
        authType = [QLFRendezvousAuthType rendezvousTrustedWithSignature:authSignature];
    }

    _lfAuthType = authType;
    
    // Create the Rendezvous.
    QLFRendezvousCreationInfo *_creationInfo =
    [QLFRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:_hashedTag
                                                authenticationType:authType
                                                  conversationType:configuration.conversationType
                                                   durationSeconds:maybeDurationSeconds
                                                  maxResponseCount:maybeMaxResponseCount
                                                          transCap:maybeTransCap
                                                requesterPublicKey:requesterPublicKeyBytes
                                                ownershipPublicKey:accessControlPublicKeyBytes
                                                authenticationCode:authenticationCode];
    _descriptor =
    [QLFRendezvousDescriptor rendezvousDescriptorWithTag:_tag
                                               hashedTag:_hashedTag
                                        conversationType:configuration.conversationType
                                      authenticationType:authType
                                         durationSeconds:maybeDurationSeconds
                                        maxResponseCount:maybeMaxResponseCount
                                                transCap:maybeTransCap
                                        requesterKeyPair:requesterKeyPair
                                    accessControlKeyPair:accessControlKeyPair];

    [_rendezvous createWithCreationInfo:_creationInfo
                      completionHandler:^(QLFRendezvousCreateResult *result, NSError *error) {
                          if (error) {
                              completionHandler(error);
                              return;
                          }

                          [result ifRendezvousCreated:^{
                              [self storeWithCompletionHandler:^(NSError *error) {
                                  completionHandler(error);
                              }];
                          } ifRendezvousAlreadyExists:^{
                              completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                                    code:QredoErrorCodeRendezvousAlreadyExists
                                                                userInfo:@{NSLocalizedDescriptionKey: @"Rendezvous with the specified tag already exists"}]);
                          }];
                      }];
}

- (void)storeWithCompletionHandler:(void(^)(NSError* error))completionHandler
{
    QredoVault *vault = _client.systemVault;

    QLFVaultItemId *itemId = [vault itemIdWithName:_tag type:kQredoRendezvousVaultItemType];

    NSData *serializedDescriptor = [QredoPrimitiveMarshallers marshalObject:_descriptor
                                                                 marshaller:[QLFRendezvousDescriptor marshaller]];

    QredoVaultItemMetadata *metadata
    = [QredoVaultItemMetadata vaultItemMetadataWithDataType:kQredoRendezvousVaultItemType
                                                accessLevel:0
                                              summaryValues:@{
                                                              kQredoRendezvousVaultItemLabelTag: self.tag,
                                                              kQredoRendezvousVaultItemLabelAuthenticationType:
                                                                  [NSNumber numberWithInt:self.authenticationType]
                                                              }];

    QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:serializedDescriptor];

    [_client.systemVault strictlyPutNewItem:vaultItem
                                     itemId:itemId
                          completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
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

- (BOOL)processResponse:(QLFRendezvousResponse *)response
          sequenceValue:(QLFRendezvousSequenceValue)sequenceValue
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
    [self enumerateResponsesWithBlock:^(QLFRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop)
    {
        block(conversation, stop);
    }
                    completionHandler:completionHandler
                                since:sinceWatermark
                 highWatermarkHandler:highWatermarkHandler];
}


- (void)enumerateResponsesWithBlock:(void(^)(QLFRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop))block
                  completionHandler:(void(^)(NSError *error))completionHandler
                              since:(QredoRendezvousHighWatermark)sinceWatermark
               highWatermarkHandler:(void(^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler
{
    NSError *error = nil;

    NSData *payloadData = [QredoPrimitiveMarshallers marshalObject:nil
                                                        marshaller:^(id element, QredoWireFormatWriter *writer)
    {
        [writer writeQUID:_hashedTag];
        [writer writeInt64:@(sinceWatermark)];
    }
                                                     includeHeader:NO];

    QLFOwnershipSignature *ownershipSignature =
    [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoRSASinger alloc] initWithRSAKeyRef:_ownershipPrivateKey]
                                       operationType:[QLFOperationType operationList]
                                      marshalledData:payloadData
                                               error:&error];

    if (error) {
        completionHandler(error);
        return ;
    }

    [_rendezvous getResponsesWithHashedTag:_hashedTag
                                     after:sinceWatermark
                                 signature:ownershipSignature
                         completionHandler:^(QLFRendezvousResponsesResult *result, NSError *error)
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

}

- (void)processRendezvousResponseResult:(QLFRendezvousResponsesResult *)result
                          responseIndex:(NSUInteger)responseIndex
                rendezvousResponseBlock:(void(^)(QLFRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop))rendezvousResponseBlock
                   highWatermarkHandler:(void(^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler
                      completionHandler:(void(^)(NSError *error))completionHandler
{
    void (^finishEnumeration)() = ^{
        if (result.sequenceValue && highWatermarkHandler) {
            highWatermarkHandler(result.sequenceValue);
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

    QLFRendezvousResponse *response = [result.responses objectAtIndex:responseIndex];

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

- (void)createConversationAndStoreKeysForResponse:(QLFRendezvousResponse *)response
                                completionHandler:(void(^)(QredoConversation *conversation, NSError *error))completionHandler
{
    QredoConversation *conversation = [[QredoConversation alloc] initWithClient:_client
                                                             authenticationType:_lfAuthType
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

    QLFVaultItemId *itemId = [vault itemIdWithName:_tag type:kQredoRendezvousVaultItemType];
    QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:itemId];

    return [[QredoRendezvousMetadata alloc] initWithTag:self.tag
                                     authenticationType:self.authenticationType
                                    vaultItemDescriptor:descriptor];
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
    [self enumerateResponsesWithBlock:^(QLFRendezvousResponsesResult *rendezvousResponse, QredoConversation *conversation, BOOL *stop) {
        [_updateListener processSingleItem:conversation sequenceValue:@(rendezvousResponse.sequenceValue)];
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

    NSData *payloadData = [QredoPrimitiveMarshallers marshalObject:_hashedTag
                                                        marshaller:[QredoPrimitiveMarshallers quidMarshaller]
                                                     includeHeader:NO];
    NSError *error = nil;

    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoRSASinger alloc] initWithRSAKeyRef:_ownershipPrivateKey]
                                            operationType:[QLFOperationType operationList]
                                           marshalledData:payloadData
                                                    error:&error];

    if (error)
    {
        completionHandler(error);
        return;
    }

    [_rendezvous subscribeToResponsesWithHashedTag:_hashedTag
                                         signature:ownershipSignature
                                 completionHandler:^(QLFRendezvousResponseWithSequenceValue *result, NSError *error)
    {
        if (error) {
            [_updateListener didTerminateSubscriptionWithError:error];
            completionHandler(error);
            return ;
        }
        LogDebug(@"Rendezvous subscription result handler called. Correlation id = %@", _subscriptionCorrelationId);

         [self createConversationAndStoreKeysForResponse:result.response
                                       completionHandler:^(QredoConversation *conversation, NSError *creationError)
          {
              if (creationError) {
                  completionHandler(error);
                  return;
              }


              LogDebug(@"Rendezvous subscription returned conversation: %@, self=%@, updateListener=%@", conversation, self, _updateListener);

              [_updateListener processSingleItem:conversation sequenceValue:@(result.sequenceValue)];

          }];

         self->_highWatermark = result.sequenceValue;
     }
     ];
    LogDebug(@"SUBSCRIBE correlation id=%@", _subscriptionCorrelationId);

}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
unsubscribeWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    LogDebug(@"UNSUBSCRIBE correlation id=%@", _subscriptionCorrelationId);

    // TODO: ownership
//    [_rendezvous unsubscribeWithCorrelationId:_subscriptionCorrelationId completionHandler:^(NSError *error) {
//        _subscriptionCorrelationId = nil;
//        completionHandler(error);
//    }];
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