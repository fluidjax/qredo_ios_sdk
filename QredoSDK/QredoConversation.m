/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoConversation.h"
#import "QredoRendezvousCrypto.h"
#import "QredoConversationCrypto.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"
#import "QredoRsaPrivateKey.h"
#import "QredoRsaPublicKey.h"
#import "CryptoImplV1.h"
#import "QredoClient.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoPrivate.h"
#import "QredoVaultPrivate.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"
#import "QredoLogging.h"

QredoConversationHighWatermark *const QredoConversationHighWatermarkOrigin = nil;
NSString *const kQredoConversationVaultItemType = @"com.qredo.conversation";

NSString *const kQredoConversationVaultItemLabelAmOwner = @"A";
NSString *const kQredoConversationVaultItemLabelId = @"id";
NSString *const kQredoConversationVaultItemLabelTag = @"tag";
NSString *const kQredoConversationVaultItemLabelHwm = @"hwm";
NSString *const kQredoConversationVaultItemLabelType = @"type";


static NSString *const kQredoConversationMessageTypeControl = @"Ctrl";

static const double kQredoConversationUpdateInterval = 1.0; // seconds


// TODO these values should not be in clear memory. Add red herring
#define SALT_CONVERSATION_ID [@"ConversationID" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_A_BULKKEY [@"ConversationBulkEncryptionKeyA" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_A_AUTHKEY [@"ConversationAuthenticationKeyA" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_B_BULKKEY [@"ConversationBulkEncryptionKeyB" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_B_AUTHKEY [@"ConversationAuthenticationKeyB" dataUsingEncoding:NSUTF8StringEncoding]

@interface QredoConversationMetadata ()
@property (readwrite) NSString *type;
@property (readwrite) QredoQUID *conversationId;
@property (readwrite) BOOL amRendezvousOwner;
@property (readwrite) NSString *rendezvousTag;

@end

@implementation QredoConversationMetadata

- (BOOL)isEphemeral {
    return [self.type hasSuffix:@"~"];
}

- (BOOL)isPersistent {
    return ![self isEphemeral];
}

@end

@interface QredoConversationHighWatermark()
@property NSData *sequenceValue;
@end

@implementation QredoConversationHighWatermark

- (instancetype)initWithSequenceValue:(NSData*)sequenceValue {
    self = [super init];
    self.sequenceValue = sequenceValue;
    return self;
}

- (BOOL)isLaterThan:(QredoConversationHighWatermark*)other {
    if (!other) return YES;

    // assuming that watermark is just an integer in the NSData
    // Just to handle the generic usecase treating this as variable length

    const uint8_t *myBytes = (const uint8_t*)_sequenceValue.bytes;
    const uint8_t *otherBytes = (const uint8_t*)other.sequenceValue.bytes;

    unsigned long mySkipBytes = (self.sequenceValue.length < other.sequenceValue.length) ? other.sequenceValue.length - self.sequenceValue.length : 0;
    unsigned long otherSkipBytes = (self.sequenceValue.length > other.sequenceValue.length) ? self.sequenceValue.length - other.sequenceValue.length : 0;

    unsigned long max = MAX(self.sequenceValue.length, other.sequenceValue.length);

    for (unsigned long i = 0; i < max; i++) {
        uint8_t myByte = (i < mySkipBytes) ? 0 : myBytes[i - mySkipBytes]; // adding leading zero
        uint8_t otherByte = (i < otherSkipBytes) ? 0 : otherBytes[i - otherSkipBytes]; // adding leading zero

        if (myByte > otherByte) return YES;
    }
    return NO;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"QredoConversationHighWatermark: sequenceValue=%@", [self.sequenceValue description]];
}
@end

@interface QredoConversationMessage ()

// making read/write for private use
@property QredoConversationHighWatermark *highWatermark;

- (instancetype)initWithMessageLF:(QredoConversationMessageLF*)messageLF incoming:(BOOL)incoming;
- (QredoConversationMessageLF*)messageLF;

@end

@implementation QredoConversationMessage

- (instancetype)initWithMessageLF:(QredoConversationMessageLF*)messageLF incoming:(BOOL)incoming
{
    self = [self initWithValue:messageLF.value dataType:messageLF.metadata.dataType summaryValues:[messageLF.metadata.summaryValues dictionaryFromIndexableSet]];
    if (!self) return nil;

    _messageId = messageLF.metadata.id;
    _parentId = [messageLF.metadata.parentId anyObject];
    _incoming = incoming;

    return self;
}

- (instancetype)initWithValue:(NSData*)value dataType:(NSString*)dataType summaryValues:(NSDictionary*)summaryValues
{
    self = [super init];
    if (!self) return nil;

    _dataType = [dataType copy];
    _value = [value copy];
    _summaryValues = [summaryValues copy];

    return self;
}

- (QredoConversationMessageLF*)messageLF
{
    QredoConversationMessageMetaDataLF *messageMetadata = [QredoConversationMessageMetaDataLF conversationMessageMetaDataLFWithID:[QredoQUID QUID]
                                                                                                                         parentId:self.parentId ? [NSSet setWithObject:self.parentId] : nil
                                                                                                                         sequence:nil // TODO
                                                                                                                         dataType:self.dataType
                                                                                                                    summaryValues:[self.summaryValues indexableSet]];

    QredoConversationMessageLF *message = [[QredoConversationMessageLF alloc] initWithMetadata:messageMetadata value:self.value];
    return message;
}

- (BOOL)isControlMessage
{
    return [self.dataType isEqualToString:kQredoConversationMessageTypeControl];
}

- (QredoConversationControlMessageType)controlMessageType
{
    if (![self isControlMessage]) return QredoConversationControlMessageTypeUnknown;

    NSData *qrvValue = [QredoPrimitiveMarshallers marshalObject:[QredoCtrl QRV]
                                                     marshaller:[QredoClientMarshallers ctrlMarshaller]];


    if ([self.value isEqualToData:qrvValue]) return QredoConversationControlMessageTypeJoined;

    NSData *qrtValue = [QredoPrimitiveMarshallers marshalObject:[QredoCtrl QRT]
                                                     marshaller:[QredoClientMarshallers ctrlMarshaller]];


    if ([self.value isEqualToData:qrtValue]) return QredoConversationControlMessageTypeLeft;

    return QredoConversationControlMessageTypeUnknown;
}


@end

@interface QredoConversation ()
{
    QredoClient *_client;
    id<CryptoImpl> _crypto;
    QredoConversationCrypto *_conversationCrypto;
    QredoConversations *_conversationService;

    NSData *_inboundBulkKey;
    NSData *_inboundAuthKey;

    NSData *_outboundBulkKey;
    NSData *_outboundAuthKey;

    QredoQUID *_inboundQueueId;
    QredoQUID *_outboundQueueId;

    dispatch_queue_t _queue;
    dispatch_source_t _timer;

    BOOL _deleted;

    NSSet *_transCap;
    QredoDhPublicKey *_yourPublicKey;
    QredoDhPrivateKey *_myPrivateKey;
    QredoConversationMetadata *_metadata;

    int scheduled, responded; // TODO use locks for queues
}

@end

@implementation QredoConversation (Private)

- (instancetype)initWithClient:(QredoClient *)client
{
    return [self initWithClient:client rendezvousTag:nil converationType:nil transCap:nil];
}

- (instancetype)initWithClient:(QredoClient *)client rendezvousTag:(NSString *)rendezvousTag converationType:(NSString *)conversationType transCap:(NSSet *)transCap
{
    self = [super init];
    if (!self) return nil;

    _client = client;

    // TODO: move to a singleton to avoid creation of these stateless objects for every conversation
    // or make all the methods as class methods
    _crypto = [CryptoImplV1 new];
    _conversationCrypto = [[QredoConversationCrypto alloc] initWithCrypto:_crypto];
    _queue = dispatch_queue_create("com.qredo.conversation.updates", nil);
    _conversationService = [QredoConversations conversationsWithServiceInvoker:_client.serviceInvoker];


    _metadata = [[QredoConversationMetadata alloc] init];
    _metadata.rendezvousTag = rendezvousTag;
    _metadata.type = conversationType;

    _transCap = transCap;


    return self;
}

- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QredoConversationDescriptor*)descriptor
{
    self = [self initWithClient:client rendezvousTag:descriptor.rendezvousTag converationType:descriptor.conversationType transCap:descriptor.initialTransCap];
    if (!self) return nil;

    _metadata = [[QredoConversationMetadata alloc] init];
    _metadata.conversationId = descriptor.conversationId;
    _metadata.amRendezvousOwner = [descriptor.amRendezvousOwner boolValue];

    _yourPublicKey = [[QredoDhPublicKey alloc] initWithData:[descriptor.yourPublicKey bytes]];
    _myPrivateKey = [[QredoDhPrivateKey alloc] initWithData:[descriptor.myKey.privKey bytes]];

    // this method is called when we are loading the conversation from the vault, therefore, we don't need to store it again. Only generating keys here
    [self generateKeysWithPrivateKey:_myPrivateKey publicKey:_yourPublicKey rendezvousOwner:_metadata.amRendezvousOwner];

    return self;
}

- (QredoVaultItemDescriptor*)vaultItemDescriptor {
    QredoVault *vault = [_client systemVault];

    QredoVaultItemId *itemId = [vault itemIdWithQUID:_metadata.conversationId type:kQredoConversationVaultItemType];

    QredoVaultItemDescriptor *itemDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:itemId];

    return itemDescriptor;
}

- (void)generateAndStoreKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey publicKey:(QredoDhPublicKey*)publicKey rendezvousOwner:(BOOL)rendezvousOwner completionHandler:(void(^)(NSError *error))completionHandler
{
    [self generateKeysWithPrivateKey:privateKey publicKey:publicKey rendezvousOwner:rendezvousOwner];

    QredoVault *vault = [_client systemVault];

    QredoVaultItemDescriptor *itemDescriptor = [self vaultItemDescriptor];

    void (^storeCompletionHandler)(NSError *) = ^(NSError *error) {
        if (error) {
            completionHandler(error);
            return;
        }

        NSData *qrvValue = [QredoPrimitiveMarshallers marshalObject:[QredoCtrl QRV]
                                                         marshaller:[QredoClientMarshallers ctrlMarshaller]];

        QredoConversationMessage *joinedControlMessage = [[QredoConversationMessage alloc] initWithValue:qrvValue
                                                                                                dataType:kQredoConversationMessageTypeControl
                                                                                           summaryValues:nil];

        [self publishMessage:joinedControlMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
            completionHandler(error);
        }];
    };

    [vault getItemMetadataWithDescriptor:itemDescriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        if (vaultItemMetadata) {
            // Already stored
            completionHandler(nil);
        } else {
            if (error.code == QredoErrorCodeVaultItemNotFound) {
                [self storeWithCompletionHandler:storeCompletionHandler];
            } else {
                storeCompletionHandler(error);
            }
        }
    }];
}

- (void)generateKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey publicKey:(QredoDhPublicKey*)publicKey rendezvousOwner:(BOOL)rendezvousOwner {
    if (!_metadata) _metadata = [[QredoConversationMetadata alloc] init];

    _metadata.amRendezvousOwner = rendezvousOwner;
    _myPrivateKey = privateKey;
    _yourPublicKey = publicKey;

    if (rendezvousOwner) {
        _inboundBulkKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_A_BULKKEY
                                                    myPrivateKey:privateKey
                                                   yourPublicKey:publicKey];

        _inboundAuthKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_A_AUTHKEY
                                                    myPrivateKey:privateKey
                                                   yourPublicKey:publicKey];

        _outboundBulkKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_B_BULKKEY
                                                     myPrivateKey:privateKey
                                                    yourPublicKey:publicKey];

        _outboundAuthKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_B_AUTHKEY
                                                     myPrivateKey:privateKey
                                                    yourPublicKey:publicKey];

    } else {
        _inboundBulkKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_B_BULKKEY
                                                    myPrivateKey:privateKey
                                                   yourPublicKey:publicKey];

        _inboundAuthKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_B_AUTHKEY
                                                    myPrivateKey:privateKey
                                                   yourPublicKey:publicKey];

        _outboundBulkKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_A_BULKKEY
                                                     myPrivateKey:privateKey
                                                    yourPublicKey:publicKey];

        _outboundAuthKey = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_A_AUTHKEY
                                                     myPrivateKey:privateKey
                                                    yourPublicKey:publicKey];
    }

    NSData *conversationIdData = [_crypto getDiffieHellmanSecretWithSalt:SALT_CONVERSATION_ID
                                                           myPrivateKey:privateKey
                                                          yourPublicKey:publicKey];
    _metadata.conversationId = [[QredoQUID alloc] initWithQUIDData:conversationIdData];
    

    NSMutableData *queueA = [NSMutableData data];
    [queueA appendBytes:"A" length:1];
    [queueA appendBytes:_metadata.conversationId.bytes
                 length:_metadata.conversationId.bytesCount];

    NSMutableData *queueB = [NSMutableData data];
    [queueB appendBytes:"B" length:1];
    [queueB appendBytes:_metadata.conversationId.bytes
                 length:_metadata.conversationId.bytesCount];

    QredoQUID *queueAQUID = [QredoQUID QUIDByHashingData:queueA];
    QredoQUID *queueBQUID = [QredoQUID QUIDByHashingData:queueB];

    if (rendezvousOwner) {
        // Inbound is to me (Alice)
        _inboundQueueId = queueAQUID;
        _outboundQueueId = queueBQUID;
    } else {
        // Inbound is to me (Bob)
        _inboundQueueId = queueBQUID;
        _outboundQueueId = queueAQUID;
    }

}

- (void)respondToRendezvousWithTag:(NSString *)rendezvousTag completionHandler:(void(^)(NSError *error))completionHandler
{
    LogDebug(@"Responding to (hashed) tag: %@", rendezvousTag);
    
    QredoRendezvousCrypto *_rendezvousCrypto = [QredoRendezvousCrypto instance];
    QredoInternalRendezvous *_rendezvous = [QredoInternalRendezvous rendezvousWithServiceInvoker:_client.serviceInvoker];

    QredoAuthenticationCode *authKey = [_rendezvousCrypto authKey:rendezvousTag];
    QredoRendezvousHashedTag *hashedTag = [_rendezvousCrypto hashedTagWithAuthKey:authKey];

    // Generate the rendezvous key pairs.
    QredoKeyPairLF *responderKeyPair     = [_rendezvousCrypto newRequesterKeyPair];
    NSData *requesterPublicKeyBytes      = [[responderKeyPair pubKey] bytes];

    QredoRendezvousResponse *response = [QredoRendezvousResponse rendezvousResponseWithHashedTag:hashedTag
                                                                              responderPublicKey:requesterPublicKeyBytes
                                                                     responderAuthenticationCode:authKey];



    [_rendezvous respondWithResponse:response completionHandler:^(QredoRendezvousRespondResult *result, NSError *error) {

        // TODO: DH - this handler does not appear to deal with the NSError returned, only creating a new error (hiding returned error) if result is not of correct object type.
        
        if ([result isKindOfClass:[QredoRendezvousResponseRegistered class]])
        {
            QredoRendezvousResponseRegistered* responseRegistered = (QredoRendezvousResponseRegistered*) result;

            QredoRendezvousCreationInfo *creationInfo = responseRegistered.creationInfo;

            
            if ([_rendezvousCrypto validateCreationInfo:creationInfo tag:rendezvousTag]) {
                
                QredoDhPublicKey *requesterPublicKey = [[QredoDhPublicKey alloc] initWithData:creationInfo.requesterPublicKey];
                
                QredoDhPrivateKey *responderPrivateKey = [[QredoDhPrivateKey alloc] initWithData:responderKeyPair.privKey.bytes];
                
                _metadata.rendezvousTag = rendezvousTag;
                _transCap = responseRegistered.creationInfo.transCap;
                _metadata.type = responseRegistered.creationInfo.conversationType;
                
                [self generateAndStoreKeysWithPrivateKey:responderPrivateKey publicKey:requesterPublicKey rendezvousOwner:NO completionHandler:completionHandler];
                
            } else {
                
                completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                      code:QredoErrorCodeRendezvousWrongAuthenticationCode
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Authentication codes don't match"}]);
                return ;
                
            }

        } else if ([result isKindOfClass:[QredoRendezvousResponseUnknownTag class]]) {
            completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeRendezvousUnknownResponse
                                              userInfo:@{NSLocalizedDescriptionKey: @"Unknown rendezvous tag"}]);

        } else {
            completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeRendezvousUnknownResponse
                                              userInfo:@{NSLocalizedDescriptionKey: @"Unknown response from the server"}]);
        }
    }];
}

- (void)storeWithCompletionHandler:(void(^)(NSError *error))completionHandler {
    QredoVault *vault = _client.systemVault;

    QredoVaultItemId *itemId = [vault itemIdWithQUID:_metadata.conversationId type:kQredoConversationVaultItemType];


    QredoKeyPairLF *myKey = [QredoKeyPairLF keyPairLFWithPubKey:[QredoKeyLF keyLFWithBytes:[NSData data]] /* should be empty */
                                                        privKey:[QredoKeyLF keyLFWithBytes:[_myPrivateKey data]]];

    QredoConversationDescriptor *descriptor =
    [QredoConversationDescriptor conversationDescriptorWithRendezvousTag:_metadata.rendezvousTag
                                                       amRendezvousOwner:[NSNumber numberWithBool:_metadata.amRendezvousOwner]
                                                          conversationId:_metadata.conversationId
                                                        conversationType:_metadata.type
                                                                   myKey:myKey
                                                           yourPublicKey:[QredoKeyLF keyLFWithBytes:[_yourPublicKey data]]
                                                          inboundBulkKey:[QredoKeyLF keyLFWithBytes:_inboundBulkKey]
                                                         outboundBulkKey:[QredoKeyLF keyLFWithBytes:_outboundBulkKey]
                                                         initialTransCap:_transCap];

    NSData *serializedDescriptor = [QredoPrimitiveMarshallers marshalObject:descriptor
                                                                 marshaller:[QredoClientMarshallers conversationDescriptorMarshaller]];

    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:kQredoConversationVaultItemType
                                                                                 accessLevel:0
                                                                               summaryValues:@{
                                                                                               kQredoConversationVaultItemLabelAmOwner: [NSNumber numberWithBool:_metadata.amRendezvousOwner],
                                                                                               kQredoConversationVaultItemLabelId: _metadata.conversationId,
                                                                                               kQredoConversationVaultItemLabelTag: _metadata.rendezvousTag,
                                                                                               kQredoConversationVaultItemLabelType: _metadata.type
                                                                                               }];

    QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:serializedDescriptor];

    [_client.systemVault strictlyPutNewItem:vaultItem itemId:itemId completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
        completionHandler(error);
    }];

}

@end


@implementation QredoConversation


- (QredoConversationMetadata *)metadata
{
    return _metadata;
}


- (void)resetHighWatermark
{
    _highWatermark = QredoConversationHighWatermarkOrigin;
}

- (void)publishMessage:(QredoConversationMessage *)message completionHandler:(void(^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler
{
    if (_deleted) {
        completionHandler(nil, [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationDeleted
                                               userInfo:@{NSLocalizedDescriptionKey: @"Conversation has been deleted"}]);
        return;
    }
    NSData *encryptedItem = [_conversationCrypto encryptMessage:[message messageLF]
                                                        bulkKey:_outboundBulkKey
                                                        authKey:_outboundAuthKey];



    [_conversationService publishWithQueueId:_outboundQueueId
                                         item:encryptedItem
                            completionHandler:^(QredoConversationPublishResult *result, NSError *error)
     {
         if (error) {
             completionHandler(QredoConversationHighWatermarkOrigin, error);
             return;
         }

         if (!result) {
             completionHandler(QredoConversationHighWatermarkOrigin,
                               [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationUnknown
                                               userInfo:@{NSLocalizedDescriptionKey: @"Empty result"}]);
             return;
         }

         QredoConversationHighWatermark *watermark = [[QredoConversationHighWatermark alloc] initWithSequenceValue:result.sequenceValue];
         completionHandler(watermark, nil);
     }];

}

- (void)acknowledgeReceiptUpToHighWatermark:(QredoConversationHighWatermark*)highWatermark
{

}

- (void)startListening
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
                                      dispatch_time(DISPATCH_TIME_NOW, kQredoConversationUpdateInterval * NSEC_PER_SEC), // start
                                      kQredoConversationUpdateInterval * NSEC_PER_SEC, // interval
                                      (1ull * NSEC_PER_SEC) / 10); // how much it can defer from the interval
            dispatch_source_set_event_handler(_timer, ^{
                if (scheduled != responded) {
                    return;
                }
                scheduled++;

                [self enumerateMessagesUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
                    if ([_delegate respondsToSelector:@selector(qredoConversation:didReceiveNewMessage:)]) {
                        [_delegate qredoConversation:self didReceiveNewMessage:message];
                    }
                } completionHandler:^(NSError *error) {
                    // TODO: DH - need to deal with any error returned - e.g. may indicate transport has been terminated
                    responded++;
                } since:self.highWatermark
                             highWatermarkHandler:^(QredoConversationHighWatermark *highWatermark) {
                    _highWatermark = highWatermark;
                }];
            });
            dispatch_resume(_timer);
        }
    }
}

- (void)stopListening
{
    @synchronized (self) {
        if (_timer) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
    }
}

- (void)deleteConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSData *qrtValue = [QredoPrimitiveMarshallers marshalObject:[QredoCtrl QRT]
                                                     marshaller:[QredoClientMarshallers ctrlMarshaller]];

    QredoConversationMessage *leftControlMessage = [[QredoConversationMessage alloc] initWithValue:qrtValue
                                                                                            dataType:kQredoConversationMessageTypeControl
                                                                                       summaryValues:nil];

    [self publishMessage:leftControlMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        if (error) {
            completionHandler(error);
            return ;
        }

        _deleted = YES;

        QredoVault *vault = [_client systemVault];

        QredoVaultItemDescriptor *itemDescriptor = [self vaultItemDescriptor];

        [vault getItemMetadataWithDescriptor:itemDescriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
            if (error) {
                completionHandler(error);
                return ;
            }

            [vault deleteItem:vaultItemMetadata completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
                completionHandler(error);
            }];

        }];
    }];
}

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block since:(QredoConversationHighWatermark*)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler
{
    [self enumerateMessagesUsingBlock:block completionHandler:completionHandler since:sinceWatermark highWatermarkHandler:nil];
}


- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                  completionHandler:(void(^)(NSError *error))completionHandler
                              since:(QredoConversationHighWatermark*)sinceWatermark
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler
{
    [self enumerateMessagesUsingBlock:block incoming:true completionHandler:completionHandler since:sinceWatermark highWatermarkHandler:highWatermarkHandler];
}


- (void)enumerateSentMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block since:(QredoConversationHighWatermark*)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler {
    [self enumerateMessagesUsingBlock:block incoming:false completionHandler:completionHandler since:sinceWatermark highWatermarkHandler:nil];
}


- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                       incoming:(BOOL)incoming
                  completionHandler:(void(^)(NSError *error))completionHandler
                              since:(QredoConversationHighWatermark*)sinceWatermark
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler
{

    QredoQUID *messageQueue = incoming ? _inboundQueueId : _outboundQueueId;
    NSData *bulkKey = incoming ? _inboundBulkKey : _outboundBulkKey;
    NSData *authKey = incoming ? _inboundAuthKey : _outboundAuthKey;
    [_conversationService queryItemsWithQueueId:messageQueue
                                          after:sinceWatermark?[NSSet setWithObject:sinceWatermark.sequenceValue]:nil
                                       fetchSize:[NSSet setWithObject:@100000] // TODO check what the logic should be
                               completionHandler:^(QredoConversationQueryItemsResult *result, NSError *error) {
                                   if (error) {
                                       completionHandler(error);
                                       return;
                                   }

                                   if (!result) {
                                       completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                                          code:QredoErrorCodeConversationUnknown
                                                                      userInfo:@{NSLocalizedDescriptionKey: @"Empty result"}]);
                                       return;
                                   }

                                   NSError *returnError = nil;

                                   LogDebug(@"Enumerating %lu conversation items(s)", (unsigned long)result.items.count);

                                   // Decrypting messages
                                   for (QredoConversationItemWithSequenceValue *conversationItem in result.items) {
                                       NSError *decryptionError = nil;
                                       QredoConversationMessageLF *decryptedMessage =
                                           [_conversationCrypto decryptMessage:conversationItem.item
                                                                       bulkKey:bulkKey
                                                                       authKey:authKey
                                                                         error:&decryptionError];

                                       if (decryptionError) {
                                           returnError = decryptionError;
                                           break;
                                       }

                                       if (highWatermarkHandler) highWatermarkHandler([[QredoConversationHighWatermark alloc] initWithSequenceValue:conversationItem.sequenceValue]);

                                       BOOL stop = conversationItem == result.items.lastObject;
                                       QredoConversationMessage *message = [[QredoConversationMessage alloc] initWithMessageLF:decryptedMessage incoming:incoming];


                                       message.highWatermark = [[QredoConversationHighWatermark alloc] initWithSequenceValue:conversationItem.sequenceValue];
                                       block(message, &stop);

                                       if ([message isControlMessage]) {
                                           if ([message controlMessageType] == QredoConversationControlMessageTypeLeft) break;
                                       }

                                       if (stop) {
                                           break;
                                       }
                                   }

                                   if (highWatermarkHandler) highWatermarkHandler([[QredoConversationHighWatermark alloc] initWithSequenceValue:result.maxSequenceValue]);

                                   completionHandler(returnError);
                               }];
}

@end