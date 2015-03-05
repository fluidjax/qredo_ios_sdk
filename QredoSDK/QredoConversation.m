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
#import "QredoClient.h"
#import "QredoConversationMessagePrivate.h"
#import "QredoUpdateListener.h"

QredoConversationHighWatermark *const QredoConversationHighWatermarkOrigin = nil;
NSString *const kQredoConversationVaultItemType = @"com.qredo.conversation";

NSString *const kQredoConversationVaultItemLabelAmOwner = @"A";
NSString *const kQredoConversationVaultItemLabelId = @"id";
NSString *const kQredoConversationVaultItemLabelTag = @"tag";
NSString *const kQredoConversationVaultItemLabelHwm = @"hwm";
NSString *const kQredoConversationVaultItemLabelType = @"type";

NSString *const kQredoConversationMessageKeyCreated = @"_created";

// Conversation message store
NSString *const kQredoConversationSequenceId = @"_conv_sequenceid";
NSString *const kQredoConversationSequenceValue = @"_conv_seq_value";

NSString *const kQredoConversationItemIsMine = @"_mine";
NSString *const kQredoConversationItemDateSent = @"_sent";
NSString *const kQredoConversationItemHighWatermark = @"_conv_highwater";

//static const double kQredoConversationUpdateInterval = 1.0; // seconds - polling period for items (non-multi-response transports)
//static const double kQredoConversationRenewSubscriptionInterval = 300.0; // 5 mins in seconds - auto-renew subscription period (multi-response transports)

// TODO: these values should not be in clear memory. Add red herring
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

- (BOOL)isEphemeral
{
    return [self.type hasSuffix:@"~"];
}

- (BOOL)isPersistent
{
    return ![self isEphemeral];
}

@end

@interface QredoConversationHighWatermark()
@property NSData *sequenceValue;
@end

@implementation QredoConversationHighWatermark

- (instancetype)initWithSequenceValue:(NSData*)sequenceValue
{
    self = [super init];
    self.sequenceValue = sequenceValue;
    return self;
}

- (BOOL)isLaterThan:(QredoConversationHighWatermark*)other
{
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

- (NSString*)description
{
    return [NSString stringWithFormat:@"QredoConversationHighWatermark: sequenceValue=%@", [self.sequenceValue description]];
}
@end


@interface QredoConversation () <QredoUpdateListenerDelegate, QredoUpdateListenerDataSource>
{
    id<CryptoImpl> _crypto;
    QredoConversationCrypto *_conversationCrypto;
    QredoConversations *_conversationService;

    NSData *_inboundBulkKey;
    NSData *_inboundAuthKey;

    NSData *_outboundBulkKey;
    NSData *_outboundAuthKey;

    QredoQUID *_inboundQueueId;
    QredoQUID *_outboundQueueId;

    dispatch_queue_t _conversationQueue;
    dispatch_queue_t _enumerationQueue;

    BOOL _deleted;

    NSSet *_transCap;
    QredoDhPublicKey *_yourPublicKey;
    QredoDhPrivateKey *_myPrivateKey;
    QredoConversationMetadata *_metadata;

    QredoVault *_store;

    QredoConversationHighWatermark *_highestStoredIncomingHWM;

    QredoUpdateListener *_updateListener;
}

@property (nonatomic, readwrite) QredoClient *client;

@end

@implementation QredoConversation (Private)

- (instancetype)initWithClient:(QredoClient *)client
{
    return [self initWithClient:client rendezvousTag:nil converationType:nil transCap:nil];
}

- (instancetype)initWithClient:(QredoClient *)client
                 rendezvousTag:(NSString *)rendezvousTag
               converationType:(NSString *)conversationType
                      transCap:(NSSet *)transCap
{
    self = [super init];
    if (!self) return nil;

    self.client = client;

    // TODO: move to a singleton to avoid creation of these stateless objects for every conversation
    // or make all the methods as class methods
    _crypto = [CryptoImplV1 new];
    _conversationCrypto = [[QredoConversationCrypto alloc] initWithCrypto:_crypto];

    _conversationQueue = dispatch_queue_create("com.qredo.conversation", nil);

    _enumerationQueue = dispatch_queue_create("com.qredo.enumeration", nil);
    _conversationService = [QredoConversations conversationsWithServiceInvoker:self.client.serviceInvoker];

    _metadata = [QredoConversationMetadata new];
    _metadata.rendezvousTag = rendezvousTag;
    _metadata.type = conversationType;

    _transCap = transCap;

    _updateListener = [QredoUpdateListener new];
    _updateListener.dataSource = self;
    _updateListener.delegate = self;

    return self;
}

- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QredoConversationDescriptor*)descriptor
{
    self = [self initWithClient:client
                  rendezvousTag:descriptor.rendezvousTag
                converationType:descriptor.conversationType
                       transCap:descriptor.initialTransCap];
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

- (void)loadHighestHWMWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    if (self.metadata.isPersistent) {
        [self.store enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {

            NSDictionary *summaryValues = vaultItemMetadata.summaryValues;
            id isMineObj = [summaryValues objectForKey:kQredoConversationItemIsMine];
            if (![isMineObj isKindOfClass:[NSNumber class]]) {
                return ;
            }

            NSNumber *isMine = (NSNumber *)isMineObj;

            if ([isMine boolValue]) {
                return ;
            }

            id hwmObj = [summaryValues objectForKeyedSubscript:kQredoConversationItemHighWatermark];

            if (![hwmObj isKindOfClass:[NSData class]]) {
                return ;
            }

            QredoConversationHighWatermark *hwm = [[QredoConversationHighWatermark alloc] initWithSequenceValue:hwmObj];

            if (!hwm) {
                return ;
            }

            if ([hwmObj isLaterThan:_highestStoredIncomingHWM]) {
                _highestStoredIncomingHWM = hwm;
            }
        } since:QredoVaultHighWatermarkOrigin completionHandler:^(NSError *error) {
            if (completionHandler) completionHandler(error);
        }];
    }
}

- (QredoVaultItemDescriptor*)vaultItemDescriptor
{
    QredoVault *vault = [self.client systemVault];

    QredoVaultItemId *itemId = [vault itemIdWithQUID:_metadata.conversationId type:kQredoConversationVaultItemType];

    QredoVaultItemDescriptor *itemDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId
                                                                                                    itemId:itemId];

    return itemDescriptor;
}

- (void)generateAndStoreKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey
                                 publicKey:(QredoDhPublicKey*)publicKey
                           rendezvousOwner:(BOOL)rendezvousOwner
                         completionHandler:(void(^)(NSError *error))completionHandler
{
    [self generateKeysWithPrivateKey:privateKey publicKey:publicKey rendezvousOwner:rendezvousOwner];

    QredoVault *vault = [self.client systemVault];

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

        [self publishMessage:joinedControlMessage
           completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
               completionHandler(error);
           }];
    };

    [vault getItemMetadataWithDescriptor:itemDescriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        if (vaultItemMetadata) {
            // Already stored
            completionHandler(nil);
        } else if (error.code == QredoErrorCodeVaultItemNotFound) {
            [self storeWithCompletionHandler:storeCompletionHandler];
        } else {
            storeCompletionHandler(error);
        }
    }];
}

- (void)generateKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey
                         publicKey:(QredoDhPublicKey*)publicKey
                   rendezvousOwner:(BOOL)rendezvousOwner
{
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
    QredoInternalRendezvous *_rendezvous = [QredoInternalRendezvous rendezvousWithServiceInvoker:self.client.serviceInvoker];

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
        
        if ([result isKindOfClass:[QredoRendezvousResponseRegistered class]]) {
            QredoRendezvousResponseRegistered* responseRegistered = (QredoRendezvousResponseRegistered*) result;

            QredoRendezvousCreationInfo *creationInfo = responseRegistered.creationInfo;

            // TODO [GR]: Take a view whether we need to show this error to the client code.
            
            if ([_rendezvousCrypto validateCreationInfo:creationInfo tag:rendezvousTag error:nil]) {
                
                QredoDhPublicKey *requesterPublicKey = [[QredoDhPublicKey alloc] initWithData:creationInfo.requesterPublicKey];
                
                QredoDhPrivateKey *responderPrivateKey = [[QredoDhPrivateKey alloc] initWithData:responderKeyPair.privKey.bytes];
                
                _metadata.rendezvousTag = rendezvousTag;
                _transCap = responseRegistered.creationInfo.transCap;
                _metadata.type = responseRegistered.creationInfo.conversationType;

                [self generateAndStoreKeysWithPrivateKey:responderPrivateKey publicKey:requesterPublicKey
                                         rendezvousOwner:NO completionHandler:completionHandler];
                
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

- (void)storeWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    QredoVault *vault = self.client.systemVault;

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

    NSDictionary *summaryValues = @{
                                    kQredoConversationVaultItemLabelAmOwner: [NSNumber numberWithBool:_metadata.amRendezvousOwner],
                                    kQredoConversationVaultItemLabelId: _metadata.conversationId,
                                    kQredoConversationVaultItemLabelTag: _metadata.rendezvousTag,
                                    kQredoConversationVaultItemLabelType: _metadata.type
                                    };
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:kQredoConversationVaultItemType
                                                                                 accessLevel:0
                                                                               summaryValues:summaryValues];

    QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:serializedDescriptor];

    [self.client.systemVault strictlyPutNewItem:vaultItem itemId:itemId
                              completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
        completionHandler(error);
    }];

}

@end


@implementation QredoConversation

- (instancetype)copyWithZone:(NSZone *)zone {
    return self; // for immutable objects
}

- (QredoConversationMetadata *)metadata
{
    return _metadata;
}


- (void)resetHighWatermark
{
    _highWatermark = QredoConversationHighWatermarkOrigin;
}

- (void)sendMessageWithoutStoring:(QredoConversationMessage*)message
                completionHandler:(void(^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler
{
    QredoConversationMessageLF *messageLF = [message messageLF];

    NSData *encryptedItem = [_conversationCrypto encryptMessage:messageLF
                                                        bulkKey:_outboundBulkKey
                                                        authKey:_outboundAuthKey];

    // it may happen that both watermark and error != nil, when the message has been sent but failed to be stored
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

         completionHandler(watermark, error);
     }];
}

- (void)publishMessage:(QredoConversationMessage *)message
     completionHandler:(void(^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler
{
    if (_deleted) {
        completionHandler(nil, [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationDeleted
                                               userInfo:@{NSLocalizedDescriptionKey: @"Conversation has been deleted"}]);
        return;
    }

    // Adding _created field with current date
    NSMutableDictionary *summaryValues = [message.summaryValues mutableCopy];
    if (!summaryValues) summaryValues = [NSMutableDictionary dictionary];

    [summaryValues setObject:[NSDate date] forKey:kQredoConversationMessageKeyCreated];

    QredoConversationMessage *modifiedMessage = [[QredoConversationMessage alloc] initWithValue:message.value
                                                                                       dataType:message.dataType
                                                                                  summaryValues:summaryValues];


    if (!self.metadata.isPersistent || [message isControlMessage]) {
        [self sendMessageWithoutStoring:modifiedMessage completionHandler:completionHandler];

        return;
    }


    [self storeMessage:modifiedMessage
                isMine:YES
     completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
    {
        [summaryValues setObject:newItemDescriptor.sequenceId forKey:kQredoConversationSequenceId];
        [summaryValues setObject:newItemDescriptor.sequenceValue forKey:kQredoConversationSequenceValue];

        QredoConversationMessage *modifiedMessage = [[QredoConversationMessage alloc] initWithValue:message.value
                                                                                           dataType:message.dataType
                                                                                      summaryValues:summaryValues];

        [self sendMessageWithoutStoring:modifiedMessage completionHandler:completionHandler];
    }];
}

- (void)acknowledgeReceiptUpToHighWatermark:(QredoConversationHighWatermark*)highWatermark
{
    // TODO: Implement acknowledgeReceiptUpToHighWatermark
}

- (void)startListening
{
    [_updateListener startListening];
}

- (void)stopListening
{
    [_updateListener stopListening];
}

- (void)deleteConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSData *qrtValue = [QredoPrimitiveMarshallers marshalObject:[QredoCtrl QRT]
                                                     marshaller:[QredoClientMarshallers ctrlMarshaller]];
    
    QredoConversationMessage *leftControlMessage = [[QredoConversationMessage alloc] initWithValue:qrtValue
                                                                                            dataType:kQredoConversationMessageTypeControl
                                                                                       summaryValues:nil];

    [self publishMessage:leftControlMessage
       completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error)
    {
        if (error) {
            completionHandler(error);
            return ;
        }
        
        _deleted = YES;
        
        QredoVault *vault = [_client systemVault];
        
        QredoVaultItemDescriptor *itemDescriptor = [self vaultItemDescriptor];

        [vault getItemMetadataWithDescriptor:itemDescriptor
                           completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
        {
            if (error) {
                completionHandler(error);
                return ;
            }

            [vault deleteItem:vaultItemMetadata
            completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
            {
                completionHandler(error);
            }];
            
        }];
    }];
}

// TODO: DH - Reorder parameters to be consistent with enumerate methods? (i.e. move 'since' to 2nd argument as reads better)
- (void)subscribeToMessagesWithBlock:(void(^)(QredoConversationMessage *message))block
       subscriptionTerminatedHandler:(void (^)(NSError *))subscriptionTerminatedHandler
                               since:(QredoConversationHighWatermark *)sinceWatermark
                highWatermarkHandler:(void(^)(QredoConversationHighWatermark *newWatermark))highWatermarkHandler
{
    

    // Subscription is an inbound only service
    QredoQUID *messageQueue = _inboundQueueId;
    
    [_conversationService subscribeToQueueId:_inboundQueueId
                           completionHandler:^(QredoConversationItemWithSequenceValue *result, NSError *error)
     {
         LogDebug(@"Conversation subscription completion handler called");

         if (error) {
             subscriptionTerminatedHandler(error);
             return;
         }

         if (!result) {
             return ;
         }

         QredoConversationQueryItemsResult *resultItems
            = [QredoConversationQueryItemsResult conversationQueryItemsResultWithItems:@[result]
                                                                      maxSequenceValue:result.sequenceValue
                                                                               current:@0];

         // Subscriptions (or pseudo subscriptions) should not exclude control messages
         [self enumerateBodyWithResult:resultItems
                 conversationItemIndex:0
                              incoming:YES
                excludeControlMessages:NO
                                 block:^(QredoConversationMessage *message, BOOL *stop) {
                                     block(message);
                                 }
                     completionHandler:^(NSError *error) {
                         if (error) {
                             subscriptionTerminatedHandler(error);
                         }
                     }
                  highWatermarkHandler:highWatermarkHandler];

     }];

    LogDebug(@"Getting other conversation items since HWM");
    [_conversationService queryItemsWithQueueId:messageQueue
                                          after:sinceWatermark ? [NSSet setWithObject:sinceWatermark.sequenceValue] : nil
                                      fetchSize:[NSSet setWithObject:@100000] // TODO: check what the logic should be
                              completionHandler:^(QredoConversationQueryItemsResult *result, NSError *error)
     {
         if (error) {
             subscriptionTerminatedHandler(error);
             return;
         }

         if (!result) {
             subscriptionTerminatedHandler([NSError errorWithDomain:QredoErrorDomain
                                                               code:QredoErrorCodeConversationUnknown
                                                           userInfo:@{NSLocalizedDescriptionKey: @"Empty result"}]);
             return;
         }

         LogDebug(@"Enumerating %lu conversation items(s)", (unsigned long)result.items.count);

         [self enumerateBodyWithResult:result
                 conversationItemIndex:0
                              incoming:YES
                excludeControlMessages:NO
                                 block:^(QredoConversationMessage *message, BOOL *stop) {
                                     block(message);
                                 }
                     completionHandler:^(NSError *error) {

                     }
                  highWatermarkHandler:highWatermarkHandler];
     }];
}

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                              since:(QredoConversationHighWatermark*)sinceWatermark
                  completionHandler:(void(^)(NSError *error))completionHandler
{
    [self enumerateMessagesUsingBlock:block
                                since:sinceWatermark
                    completionHandler:completionHandler
                 highWatermarkHandler:nil];
}

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                              since:(QredoConversationHighWatermark*)sinceWatermark
                  completionHandler:(void(^)(NSError *error))completionHandler
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler
{
    [self enumerateMessagesUsingBlock:block
                             incoming:true
               excludeControlMessages:YES
                                since:sinceWatermark
                    completionHandler:completionHandler
                 highWatermarkHandler:highWatermarkHandler];
}


- (void)enumerateSentMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                                  since:(QredoConversationHighWatermark*)sinceWatermark
                      completionHandler:(void(^)(NSError *error))completionHandler
{
    [self enumerateMessagesUsingBlock:block
                             incoming:false
               excludeControlMessages:YES
                                since:sinceWatermark
                    completionHandler:completionHandler
                 highWatermarkHandler:nil
];
}

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                           incoming:(BOOL)incoming
             excludeControlMessages:(BOOL)excludeControlMessages
                              since:(QredoConversationHighWatermark*)sinceWatermark
                  completionHandler:(void(^)(NSError *error))completionHandler
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler

{

    QredoQUID *messageQueue = incoming ? _inboundQueueId : _outboundQueueId;

    [_conversationService queryItemsWithQueueId:messageQueue
                                          after:sinceWatermark?[NSSet setWithObject:sinceWatermark.sequenceValue]:nil
                                      fetchSize:[NSSet setWithObject:@100000] // TODO check what the logic should be
                              completionHandler:^(QredoConversationQueryItemsResult *result, NSError *error)
     {
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

         LogDebug(@"Enumerating %lu conversation items(s)", (unsigned long)result.items.count);

         // There are a few complications when asynchronosity is added
         // 1. We need to wait until the messages is stored before returning it to the user,
         //    but at the same time the queue/thread should not be blocked
         // 2. The enumeration should proceed after we deliver the message back to the user

         // Because of that we can not just run a for-loop, instead enumerateBody will be called to handle each message.
         // After it finishes processing a message, it will schedule itself for the next message

         [self enumerateBodyWithResult:result
                 conversationItemIndex:0
                              incoming:incoming
                excludeControlMessages:excludeControlMessages
                                 block:block
                     completionHandler:completionHandler
                  highWatermarkHandler:highWatermarkHandler];
     }];
}

- (void)enumerateBodyWithResult:(QredoConversationQueryItemsResult *)result
          conversationItemIndex:(NSUInteger)conversationItemIndex
                       incoming:(BOOL)incoming
         excludeControlMessages:(BOOL)excludeControlMessages
                          block:(void(^)(QredoConversationMessage *message, BOOL *stop))block
              completionHandler:(void(^)(NSError *error))completionHandler
           highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler

{
    NSData *bulkKey = incoming ? _inboundBulkKey : _outboundBulkKey;
    NSData *authKey = incoming ? _inboundAuthKey : _outboundAuthKey;

    // The outcome of this function should be either calling `completionHandler` or `continueToNextMessage`

    void (^continueToNextMessage)() = ^{
        dispatch_async(_enumerationQueue, ^{
            [self enumerateBodyWithResult:result
                    conversationItemIndex:conversationItemIndex + 1
                                 incoming:incoming
                   excludeControlMessages:excludeControlMessages
                                    block:block
                        completionHandler:completionHandler
                     highWatermarkHandler:highWatermarkHandler];
        });
    };

    void (^finishEnumeration)() = ^{
        if (highWatermarkHandler) {
            highWatermarkHandler([[QredoConversationHighWatermark alloc] initWithSequenceValue:result.maxSequenceValue]);
        }

        completionHandler(nil);
    };

    void (^deliverMessage)(QredoConversationMessage *message) = ^(QredoConversationMessage *message)
    {
        BOOL stop = conversationItemIndex >= (result.items.count - 1);
        block(message, &stop);

        if (stop || ([message isControlMessage]
                     && ([message controlMessageType] == QredoConversationControlMessageTypeLeft)))
        {
            finishEnumeration();
            return;
        }

        continueToNextMessage();
    };


    // When we reach the end of the list of messages
    if (conversationItemIndex >= result.items.count) {
        finishEnumeration();
        return ;
    }

    QredoConversationItemWithSequenceValue *conversationItem = [result.items objectAtIndex:conversationItemIndex];

    NSError *decryptionError = nil;
    QredoConversationMessageLF *decryptedMessage = [_conversationCrypto decryptMessage:conversationItem.item
                                                                               bulkKey:bulkKey
                                                                               authKey:authKey
                                                                                 error:&decryptionError];

    if (decryptionError) {
        completionHandler(decryptionError);
        return;
    }

    QredoConversationHighWatermark *highWatermark
        = [[QredoConversationHighWatermark alloc] initWithSequenceValue:conversationItem.sequenceValue];

    if (highWatermarkHandler) {
        highWatermarkHandler(highWatermark);
    }

    QredoConversationMessage *message = [[QredoConversationMessage alloc] initWithMessageLF:decryptedMessage
                                                                                   incoming:incoming];

    if (excludeControlMessages && [message isControlMessage]) {
        if ([message controlMessageType] == QredoConversationControlMessageTypeLeft) {
            finishEnumeration();
        }

        continueToNextMessage();
        return;
    }

    message.highWatermark = highWatermark;

    if (incoming && ![message isControlMessage]
        && self.metadata.isPersistent && [message.highWatermark isLaterThan:_highestStoredIncomingHWM])
    {
        [self storeMessage:message
                    isMine:NO
         completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
         {
             if (error) {
                 completionHandler(error);
                 return ;
             }

             _highestStoredIncomingHWM = message.highWatermark;

             deliverMessage(message);
         }];
    } else {
        deliverMessage(message);
    }
}

- (void)storeMessage:(QredoConversationMessage*)message
              isMine:(BOOL)mine
   completionHandler:(void(^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{
    NSMutableDictionary *summaryValues = [message.summaryValues mutableCopy];

    [summaryValues setObject:@(mine) forKey:kQredoConversationItemIsMine];

    id sentDate = [summaryValues objectForKey:kQredoConversationMessageKeyCreated];
    if (sentDate) {
        [summaryValues setObject:sentDate forKey:kQredoConversationItemDateSent];
    }

    // if there is '_created' in the vault item, it can be taken as not a new item
    [summaryValues removeObjectForKey:kQredoConversationMessageKeyCreated];

    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:message.dataType
                                                                                 accessLevel:0
                                                                               summaryValues:summaryValues];

    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:metadata value:message.value];

    [self.store putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
        completionHandler(newItemMetadata.descriptor, error);
    }];
}

- (QredoVault*)store
{
    if (_metadata.isEphemeral) return nil;

    if (_store) return _store;

    NSMutableData *derivedVaultIdData = [[_client.systemVault.vaultId data] mutableCopy];
    [derivedVaultIdData appendData:_inboundQueueId.data];

    QredoQUID *conversationVaultID = [QredoQUID QUIDByHashingData:derivedVaultIdData];

    _store = [[QredoVault alloc] initWithClient:_client qredoKeychain:_client.systemVault.qredoKeychain
                                        vaultId:conversationVaultID];

    return _store;
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
    void (^block)(QredoConversationMessage *message, BOOL *stop) = ^(QredoConversationMessage *message, BOOL *stop) {
        [self->_updateListener processSingleItem:message sequenceValue:message.highWatermark.sequenceValue];
    };

    // Subscriptions (or pseudo subscriptions) should not exclude control messages
    [self enumerateMessagesUsingBlock:block
                             incoming:YES
               excludeControlMessages:NO
                                since:self.highWatermark
                    completionHandler:completionHandler
     highWatermarkHandler:^(QredoConversationHighWatermark *highWatermark) {
         _highWatermark = highWatermark;
     } ];

}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
subscribeWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    NSAssert(_delegate, @"Conversation delegate should be set before starting listening for the updates");

    LogDebug(@"Subscribing to new conversation items/messages.");

    // Subscribe to conversations newer than our highwatermark
    [self subscribeToMessagesWithBlock:^(QredoConversationMessage *message) {
        [_updateListener processSingleItem:message sequenceValue:message.highWatermark.sequenceValue];
    } subscriptionTerminatedHandler:^(NSError *error) {
        [_updateListener didTerminateSubscriptionWithError:error];
    } since:self.highWatermark highWatermarkHandler:^(QredoConversationHighWatermark *newWatermark) {
        LogDebug(@"Conversation subscription returned new HighWatermark: %@", newWatermark);

        self->_highWatermark = newWatermark;
    }];

}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
unsubscribeWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    // TODO: DH - No current way to stop subscribing, short of disconnecting from server. Services team may add support for this in future.
    LogDebug(@"NOTE: Cannot currently unsubscribe from Conversation items.  This request is ignored.");
}

#pragma mark Qredo Update Listener - Delegate
- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item
{
    QredoConversationMessage *message = (QredoConversationMessage *)item;
    if ([message isControlMessage]) {
        if ([message controlMessageType] == QredoConversationControlMessageTypeLeft &&
            [_delegate respondsToSelector:@selector(qredoConversationOtherPartyHasLeft:)]) {
            [_delegate qredoConversationOtherPartyHasLeft:self];
        }
    } else {
        [self.delegate qredoConversation:self didReceiveNewMessage:message];
    }
}

@end