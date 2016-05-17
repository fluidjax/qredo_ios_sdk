/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import "QredoConversation.h"
#import "QredoConversationPrivate.h"
#import "QredoTypesPrivate.h"
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
#import "QredoLoggerPrivate.h"
#import "QredoClient.h"
#import "QredoConversationMessagePrivate.h"
#import "QredoUpdateListener.h"
#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoSigner.h"
#import "QredoVaultCrypto.h"
#import "QredoObserverList.h"
#import "QredoNetworkTime.h"


QredoConversationHighWatermark *const QredoConversationHighWatermarkOrigin = nil;
NSString *const kQredoConversationVaultItemType = @"com.qredo.conversation";

NSString *const kQredoConversationVaultItemLabelAmOwner = @"A";
NSString *const kQredoConversationVaultItemLabelId = @"id";
NSString *const kQredoConversationVaultItemLabelTag = @"tag";
NSString *const kQredoConversationVaultItemLabelHwm = @"hwm";
NSString *const kQredoConversationVaultItemLabelType = @"type";


// Bit 0   //Your public key has been dictated to you over the phone by the other party
// Bit 1   //You have dictated the remote public key to the other party over the phone

NSString *const kQredoConversationVaultItemLabelAuthStatus = @"as";


static NSString *const kQredoConversationMessageKeyCreated = @"_created";

// Conversation message store
NSString *const kQredoConversationSequenceId = @"_conv_sequenceid";
NSString *const kQredoConversationSequenceValue = @"_conv_seq_value";

NSString *const kQredoConversationItemIsMine = @"_mine";
NSString *const kQredoConversationItemDateSent = @"_sent";
NSString *const kQredoConversationItemHighWatermark = @"_conv_highwater";

//static const double kQredoConversationUpdateInterval = 1.0; // seconds - polling period for items (non-multi-response transports)
//static const double kQredoConversationRenewSubscriptionInterval = 300.0; // 5 mins in seconds - auto-renew subscription period (multi-response transports)

@implementation QredoConversationRef

-(NSString *)description{
    return [NSString stringWithFormat:@"%@",self.vaultItemDescriptor];
}

@end

@interface QredoConversationMetadata ()
@property (readwrite) QredoConversationRef *conversationRef;
@property (readwrite) NSString *type;
@property (readwrite) QredoQUID *conversationId;
@property (readwrite) BOOL amRendezvousOwner;
@property (readwrite) NSString *rendezvousTag;
@property (readwrite) int authStatus;

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


@interface QredoConversation () <QredoUpdateListenerDelegate, QredoUpdateListenerDataSource>{
    
    id<CryptoImpl> _crypto;
    QredoConversationCrypto *_conversationCrypto;
    QLFConversations *_conversationService;

    NSData *_inboundBulkKey;
    NSData *_inboundAuthKey;

    NSData *_outboundBulkKey;
    NSData *_outboundAuthKey;

    QredoQUID *_inboundQueueId;
    QredoQUID *_outboundQueueId;

    QredoED25519SigningKey *_inboundSigningKey;
    QredoED25519SigningKey *_outboundSigningKey;

    dispatch_queue_t _conversationQueue;
    dispatch_queue_t _enumerationQueue;

    BOOL _deleted;

    QredoDhPublicKey *_yourPublicKey;
    QredoDhPrivateKey *_myPrivateKey;
    QredoDhPublicKey *_myPublicKey;
    
    
    QLFRendezvousAuthType *_authenticationType;
    QredoConversationMetadata *_metadata;

    QredoVault *_store;

    QredoConversationHighWatermark *_highestStoredIncomingHWM;

    QredoObserverList *_observers;
    QredoUpdateListener *_updateListener;
}

@property (nonatomic, readwrite) QredoClient *client;

@end

@implementation QredoConversation (Private)


- (instancetype)initWithClient:(QredoClient *)client{
    return [self initWithClient:client authenticationType:nil rendezvousTag:nil converationType:nil];
}

- (instancetype)initWithClient:(QredoClient *)client
            authenticationType:(QLFRendezvousAuthType *)authenticationType
                 rendezvousTag:(NSString *)rendezvousTag
               converationType:(NSString *)conversationType{
    self = [super init];
    if (!self) return nil;

    self.client = client;

    // TODO: move to a singleton to avoid creation of these stateless objects for every conversation
    // or make all the methods as class methods
    _crypto = [CryptoImplV1 new];
    _conversationCrypto = [[QredoConversationCrypto alloc] initWithCrypto:_crypto];

    _conversationQueue = dispatch_queue_create("com.qredo.conversation", nil);

    _enumerationQueue = dispatch_queue_create("com.qredo.enumeration", nil);
    _conversationService = [QLFConversations conversationsWithServiceInvoker:self.client.serviceInvoker];

    _metadata = [QredoConversationMetadata new];
    _metadata.rendezvousTag = rendezvousTag;
    _metadata.type = conversationType;

    _authenticationType = authenticationType;

    _observers = [[QredoObserverList alloc] init];
    
    _updateListener = [QredoUpdateListener new];
    _updateListener.dataSource = self;
    _updateListener.delegate = self;

    return self;
}

- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QLFConversationDescriptor*)descriptor{
    self = [self initWithClient:client
             authenticationType:descriptor.authenticationType
                  rendezvousTag:descriptor.rendezvousTag
                converationType:descriptor.conversationType];
    if (!self) return nil;

    _metadata = [[QredoConversationMetadata alloc] init];
    _metadata.conversationId = descriptor.conversationId;
    _metadata.amRendezvousOwner = descriptor.rendezvousOwner;
    _metadata.rendezvousTag = descriptor.rendezvousTag;
    _metadata.type = descriptor.conversationType;
    _metadata.authStatus = descriptor.authStatus;

    _yourPublicKey = [[QredoDhPublicKey alloc] initWithData:[descriptor.yourPublicKey bytes]];
    _myPrivateKey  = [[QredoDhPrivateKey alloc] initWithData:[descriptor.myKey.privKey bytes]];
    _myPublicKey   = [[QredoDhPublicKey alloc] initWithData:[descriptor.myKey.pubKey bytes]];

    // this method is called when we are loading the conversation from the vault, therefore, we don't need to store it again. Only generating keys here
    [self generateKeysWithPrivateKey:_myPrivateKey publicKey:_yourPublicKey  myPublicKey:_myPublicKey rendezvousOwner:_metadata.amRendezvousOwner];
    

    return self;
}

- (void)loadHighestHWMWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    if (self.metadata.isPersistent) {
        [self.store enumerateConsolidatedVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {

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

- (void)generateAndStoreKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey
                                 publicKey:(QredoDhPublicKey*)publicKey
                               myPublicKey:(QredoDhPublicKey*)myPublicKey
                           rendezvousOwner:(BOOL)rendezvousOwner
                               saveToVault:(BOOL)saveToVault
                         completionHandler:(void(^)(NSError *error))completionHandler{
    
    [self generateKeysWithPrivateKey:privateKey publicKey:publicKey  myPublicKey:myPublicKey rendezvousOwner:rendezvousOwner];
    
    
        [self storeWithCompletionHandler:^(NSError *error){
            if (error) {
                if (completionHandler)completionHandler(error);
                return;
            }

            NSData *qrvValue = [QredoPrimitiveMarshallers marshalObject:[QLFCtrl qRV]
                                                             marshaller:[QLFCtrl marshaller]];

            QredoConversationMessage *joinedControlMessage = [[QredoConversationMessage alloc] initWithValue:qrvValue
                                                                                                    dataType:kQredoConversationMessageTypeControl
                                                                                               summaryValues:nil];

            [self publishMessage:joinedControlMessage
               completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                   if (completionHandler)completionHandler(error);
               }];
        }];
}

- (void)generateKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey
                         publicKey:(QredoDhPublicKey*)publicKey
                       myPublicKey:(QredoDhPublicKey*)myPublicKey
                   rendezvousOwner:(BOOL)rendezvousOwner{
    if (!_metadata) _metadata = [[QredoConversationMetadata alloc] init];

    _metadata.amRendezvousOwner = rendezvousOwner;
    _myPrivateKey = privateKey;
    _myPublicKey = myPublicKey;
    _yourPublicKey = publicKey;

    NSData *masterKey = [_conversationCrypto conversationMasterKeyWithMyPrivateKey:privateKey
                                                                     yourPublicKey:publicKey];

    NSData *requesterInboundBulkKey = [_conversationCrypto requesterInboundEncryptionKeyWithMasterKey:masterKey];

    NSData *requesterInboundAuthKey = [_conversationCrypto requesterInboundAuthenticationKeyWithMasterKey:masterKey];

    NSData *responderInboundBulkKey = [_conversationCrypto responderInboundEncryptionKeyWithMasterKey:masterKey];

    NSData *responderInboundAuthKey = [_conversationCrypto responderInboundAuthenticationKeyWithMasterKey:masterKey];

    NSData *requesterInboundQueueKeyPairSalt = [_conversationCrypto requesterInboundQueueSeedWithMasterKey:masterKey];

    NSData *responderInboundQueueKeyPairSalt = [_conversationCrypto responderInboundQueueSeedWithMasterKey:masterKey];

    QredoED25519SigningKey *requesterInboundQueueSigningKey = [_crypto qredoED25519SigningKeyWithSeed:requesterInboundQueueKeyPairSalt];
    QredoED25519SigningKey *responderInboundQueueSigningKey = [_crypto qredoED25519SigningKeyWithSeed:responderInboundQueueKeyPairSalt];

    QredoQUID *requesterInboundQueueId = [[QredoQUID alloc] initWithQUIDData:requesterInboundQueueSigningKey.verifyKey.data];
    QredoQUID *responderInboundQueueId = [[QredoQUID alloc] initWithQUIDData:responderInboundQueueSigningKey.verifyKey.data];

    if (rendezvousOwner) {
        _inboundBulkKey = requesterInboundBulkKey;
        _inboundAuthKey = requesterInboundAuthKey;
        _inboundQueueId = requesterInboundQueueId;
        _inboundSigningKey = requesterInboundQueueSigningKey;

        _outboundBulkKey = responderInboundBulkKey;
        _outboundAuthKey = responderInboundAuthKey;
        _outboundQueueId = responderInboundQueueId;
        _outboundSigningKey = responderInboundQueueSigningKey;
    } else {
        _inboundBulkKey = responderInboundBulkKey;
        _inboundAuthKey = responderInboundAuthKey;
        _inboundQueueId = responderInboundQueueId;
        _inboundSigningKey = responderInboundQueueSigningKey;

        _outboundBulkKey = requesterInboundBulkKey;
        _outboundAuthKey = requesterInboundAuthKey;
        _outboundQueueId = requesterInboundQueueId;
        _outboundSigningKey = requesterInboundQueueSigningKey;
    }

    _metadata.conversationId = [_conversationCrypto conversationIdWithMasterKey:masterKey];
}


-(void)updateConversationWithCompletionHandler:(void (^)(NSError *error))completionHandler{
    QLFKeyPairLF *myKey = [QLFKeyPairLF keyPairLFWithPubKey:[QLFKeyLF keyLFWithBytes:[_myPublicKey data]]
                                                    privKey:[QLFKeyLF keyLFWithBytes:[_myPrivateKey data]]];
    
    
    QLFConversationDescriptor *descriptor =
    [QLFConversationDescriptor conversationDescriptorWithRendezvousTag:_metadata.rendezvousTag
                                                       rendezvousOwner:_metadata.amRendezvousOwner
                                                        conversationId:_metadata.conversationId
                                                      conversationType:_metadata.type
                                                    authenticationType:_authenticationType
                                                                 myKey:myKey
                                                         yourPublicKey:[QLFKeyLF keyLFWithBytes:[_yourPublicKey data]]
                                                            authStatus:_metadata.authStatus];
    
    NSData *serializedDescriptor = [QredoPrimitiveMarshallers marshalObject:descriptor
                                                                 marshaller:[QLFConversationDescriptor marshaller]];
    
    NSDictionary *summaryValues = @{
                                    kQredoConversationVaultItemLabelAmOwner: [NSNumber numberWithBool:_metadata.amRendezvousOwner],
                                    kQredoConversationVaultItemLabelId: _metadata.conversationId,
                                    kQredoConversationVaultItemLabelTag: _metadata.rendezvousTag,
                                    kQredoConversationVaultItemLabelType: _metadata.type,
                                    kQredoConversationVaultItemLabelAuthStatus:[NSNumber numberWithInteger:_metadata.authStatus]
                                    };
    
    QredoVault *sysvault = [self.client systemVault];
    
    
    @synchronized(self) {
        [sysvault getItemMetadataWithDescriptor:self.metadata.conversationRef.vaultItemDescriptor
                           completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
             if (error) {
                 QredoLogError(@"Update Conversation failed with error %@",error);
                 
                 if (completionHandler)completionHandler(error);
                 return ;
             }
             
              
             QredoVaultItemMetadata *metadataCopy = [vaultItemMetadata mutableCopy];
             metadataCopy.created = [QredoNetworkTime dateTime];
             metadataCopy.summaryValues = summaryValues;
                               
                               
             QredoVaultItem *newVaultItem = [QredoVaultItem vaultItemWithMetadata:metadataCopy value:serializedDescriptor];
                               
                               
                               
             [sysvault strictlyUpdateItem:newVaultItem
                                       completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
                                       if (newItemMetadata) {
                                            self.metadata.conversationRef = [[QredoConversationRef alloc] initWithVaultItemDescriptor:newItemMetadata.descriptor
                                                                                                                                 vault:self.client.systemVault];
                                       }
                                       if (completionHandler)completionHandler(error);
             }];

         }];

    }
}




- (void)respondToRendezvousWithTag:(NSString *)rendezvousTag
                   trustedRootPems:(NSArray *)trustedRootPems
                           crlPems:(NSArray *)crlPems
                    appCredentials:(QredoAppCredentials*)appCredentials
                 completionHandler:(void(^)(NSError *error))completionHandler{
    QredoRendezvousCrypto *_rendezvousCrypto = [QredoRendezvousCrypto instance];
    QLFRendezvous *_rendezvous = [QLFRendezvous rendezvousWithServiceInvoker:self.client.serviceInvoker];

    NSData *masterKey = [_rendezvousCrypto masterKeyWithTag:rendezvousTag appId:appCredentials.appId];
    NSData *authKey = [_rendezvousCrypto authenticationKeyWithMasterKey:masterKey];

    QLFRendezvousHashedTag *hashedTag = [_rendezvousCrypto hashedTagWithMasterKey:masterKey];

    // Generate the rendezvous key pairs.
    QLFKeyPairLF *responderKeyPair     = [_rendezvousCrypto newRequesterKeyPair];
    
    NSData *responderPublicKeyBytes    = [[responderKeyPair pubKey] bytes];
    _myPublicKey = [[QredoDhPublicKey alloc] initWithData:responderPublicKeyBytes];
    

    QLFAuthenticationCode *responderAuthenticationCode   = [_rendezvousCrypto responderAuthenticationCodeWithHashedTag:hashedTag
                                                                                                     authenticationKey:authKey
                                                                                                    responderPublicKey:responderPublicKeyBytes];


    QLFRendezvousResponse *response = [QLFRendezvousResponse rendezvousResponseWithHashedTag:hashedTag
                                                                          responderPublicKey:responderPublicKeyBytes
                                                                 responderAuthenticationCode:responderAuthenticationCode];



    [_rendezvous respondWithResponse:response completionHandler:^(QLFRendezvousRespondResult *result, NSError *error) {

        // TODO: DH - this handler does not appear to deal with the NSError returned, only creating a new error (hiding returned error) if result is not of correct object type.
        
        if ([result isKindOfClass:[QLFRendezvousResponseRegistered class]]) {
            QLFRendezvousResponseRegistered* responseRegistered = (QLFRendezvousResponseRegistered*) result;

            // TODO: [GR]: Take a view whether we need to show this error to the client code.

            if ([_rendezvousCrypto validateEncryptedResponderInfo:responseRegistered.info
                                                authenticationKey:authKey
                                                              tag:rendezvousTag
                                                        hashedTag:hashedTag
                                                  trustedRootPems:trustedRootPems
                                                          crlPems:crlPems
                                                            error:nil]){
                NSError *error = nil;

                NSData *encKey = [_rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
                
                QLFRendezvousResponderInfo *responderInfo =
                [_rendezvousCrypto decryptResponderInfoWithData:responseRegistered.info.value
                                                  encryptionKey:encKey
                                                          error:&error];

                QredoDhPublicKey *requesterPublicKey = [[QredoDhPublicKey alloc] initWithData:responderInfo.requesterPublicKey];
                QredoDhPrivateKey *responderPrivateKey = [[QredoDhPrivateKey alloc] initWithData:responderKeyPair.privKey.bytes];
                
                _metadata.rendezvousTag = rendezvousTag;
                _metadata.type = responderInfo.conversationType;
                _authenticationType = responseRegistered.info.authenticationType;

                [self generateAndStoreKeysWithPrivateKey:responderPrivateKey
                                               publicKey:requesterPublicKey
                                             myPublicKey:_myPublicKey
                                         rendezvousOwner:NO
                                             saveToVault:YES
                                       completionHandler:completionHandler];
                
            } else {
                
                if (completionHandler)completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                      code:QredoErrorCodeRendezvousWrongAuthenticationCode
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Authentication codes don't match"}]);
                return ;
            }

        } else if ([result isKindOfClass:[QLFRendezvousResponseUnknownTag class]]) {
            if (completionHandler)completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeRendezvousUnknownResponse
                                              userInfo:@{NSLocalizedDescriptionKey: @"Unknown rendezvous tag"}]);

        } else {
            if (completionHandler)completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeRendezvousUnknownResponse
                                              userInfo:@{NSLocalizedDescriptionKey: @"Unknown response from the server"}]);
        }
    }];

}

- (void)storeWithCompletionHandler:(void(^)(NSError *error))completionHandler{
    NSAssert(!self.metadata.conversationRef, @"Conversation has been already stored");
    QLFKeyPairLF *myKey = [QLFKeyPairLF keyPairLFWithPubKey:[QLFKeyLF keyLFWithBytes:[_myPublicKey data]] 
                                                        privKey:[QLFKeyLF keyLFWithBytes:[_myPrivateKey data]]];


    QLFConversationDescriptor *descriptor =
    [QLFConversationDescriptor conversationDescriptorWithRendezvousTag:_metadata.rendezvousTag
                                                       rendezvousOwner:_metadata.amRendezvousOwner
                                                        conversationId:_metadata.conversationId
                                                      conversationType:_metadata.type
                                                    authenticationType:_authenticationType
                                                                 myKey:myKey
                                                         yourPublicKey:[QLFKeyLF keyLFWithBytes:[_yourPublicKey data]]
                                                            authStatus:_metadata.authStatus];

    NSData *serializedDescriptor = [QredoPrimitiveMarshallers marshalObject:descriptor
                                                                 marshaller:[QLFConversationDescriptor marshaller]];

    NSDictionary *summaryValues = @{
                                    kQredoConversationVaultItemLabelAmOwner: [NSNumber numberWithBool:_metadata.amRendezvousOwner],
                                    kQredoConversationVaultItemLabelId: _metadata.conversationId,
                                    kQredoConversationVaultItemLabelTag: _metadata.rendezvousTag,
                                    kQredoConversationVaultItemLabelType: _metadata.type
                                    };
    
    NSDate *created = [QredoNetworkTime dateTime];
    QredoVaultItemMetadata *metadata =
    [QredoVaultItemMetadata vaultItemMetadataWithDataType:kQredoConversationVaultItemType
                            created: created
                            summaryValues:summaryValues];

    QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:serializedDescriptor];

    @synchronized(self) {

        [self.client.systemVault strictlyPutNewItem:vaultItem
                completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
            if (newItemMetadata) {
                self.metadata.conversationRef =
                [[QredoConversationRef alloc] initWithVaultItemDescriptor:newItemMetadata.descriptor
                                                                    vault:self.client.systemVault];
            }
            if (completionHandler)completionHandler(error);
        }];
    }
}

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                           incoming:(BOOL)incoming
             excludeControlMessages:(BOOL)excludeControlMessages
                              since:(QredoConversationHighWatermark*)sinceWatermark
                  completionHandler:(void(^)(NSError *error))completionHandler
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler{

    QredoQUID *messageQueue = incoming ? _inboundQueueId : _outboundQueueId;
    QredoED25519SigningKey *signingKey = incoming ? _inboundSigningKey : _outboundSigningKey;


    NSSet *sinceWatermarkSet = sinceWatermark?[NSSet setWithObject:sinceWatermark.sequenceValue]:[NSSet set];
    NSSet *fetchSizeSet = [NSSet setWithObject:@100000]; // TODO check what the logic should be

    NSError *error = nil;

    NSData *signaturePayloadData
    = [QredoPrimitiveMarshallers marshalObject:nil
                                    marshaller:^(id element, QredoWireFormatWriter *writer){
           [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]](sinceWatermarkSet, writer);
           [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]](fetchSizeSet, writer);
       }
                                 includeHeader:NO];


    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:signingKey]
                                            operationType:[QLFOperationType operationList]
                                           marshalledData:signaturePayloadData
                                                    error:&error];

    if (error) {
        if (completionHandler)completionHandler(error);
        return ;
    }

    [_conversationService queryItemsWithQueueId:messageQueue
                                          after:sinceWatermarkSet
                                      fetchSize:fetchSizeSet
                                      signature:ownershipSignature
                              completionHandler:^(QLFConversationQueryItemsResult *result, NSError *error){
         if (error) {
             if (completionHandler)completionHandler(error);
             return;
         }

         if (!result) {
             if (completionHandler)completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationUnknown
                                               userInfo:@{NSLocalizedDescriptionKey: @"Empty result"}]);
             return;
         }

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

- (void)enumerateBodyWithResult:(QLFConversationQueryItemsResult *)result
          conversationItemIndex:(NSUInteger)conversationItemIndex
                       incoming:(BOOL)incoming
         excludeControlMessages:(BOOL)excludeControlMessages
                          block:(void(^)(QredoConversationMessage *message, BOOL *stop))block
              completionHandler:(void(^)(NSError *error))completionHandler
           highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler{
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

        if (completionHandler)completionHandler(nil);
    };

    void (^deliverMessage)(QredoConversationMessage *message) = ^(QredoConversationMessage *message){
        BOOL stop = conversationItemIndex >= (result.items.count - 1);
        block(message, &stop);

        if (stop || ([message isControlMessage]
                     && ([message controlMessageType] == QredoConversationControlMessageTypeLeft))){
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

    QLFConversationItemWithSequenceValue *conversationItem = [result.items objectAtIndex:conversationItemIndex];

    NSError *decryptionError = nil;
    QLFConversationMessage *decryptedMessage = [_conversationCrypto decryptMessage:conversationItem.item
                                                                           bulkKey:bulkKey
                                                                           authKey:authKey
                                                                             error:&decryptionError];

    if (decryptionError) {
        if (completionHandler)completionHandler(decryptionError);
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
        && self.metadata.isPersistent && [message.highWatermark isLaterThan:_highestStoredIncomingHWM]){
        [self storeMessage:message
                    isMine:NO
         completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error){
             if (error) {
                 if (completionHandler)completionHandler(error);
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
   completionHandler:(void(^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler{
    NSMutableDictionary *summaryValues = [message.summaryValues mutableCopy];

    [summaryValues setObject:@(mine) forKey:kQredoConversationItemIsMine];
    
    // TO DO verify where this code is called from and how kQredoConversationItemDateSent and
    // kQredoConversationMessageKeyCreated is used

    NSDate *sentDate = [summaryValues objectForKey:kQredoConversationMessageKeyCreated];
    if (sentDate) {
        [summaryValues setObject:sentDate forKey:kQredoConversationItemDateSent];
    }
    else sentDate = [QredoNetworkTime dateTime];

    // if there is '_created' in the vault item, it can be taken as not a new item
    [summaryValues removeObjectForKey:kQredoConversationMessageKeyCreated];

    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:message.dataType
                                                                                     created:sentDate
                                                                               summaryValues:summaryValues];

    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:metadata value:message.value];

    [self.store putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
        if (completionHandler)completionHandler(newItemMetadata.descriptor, error);
    }];
}



- (QredoVault*)store{
    if (_metadata.isEphemeral) return nil;
    if (_store) return _store;
    
    NSData *vaultKey = [QredoVaultCrypto vaultKeyWithVaultMasterKey:self.client.systemVault.vaultKeys.vaultKey
                                                           infoData:_inboundQueueId.data];
    QredoVaultKeys *keys = [[QredoVaultKeys alloc] initWithVaultKey:vaultKey];
    _store = [[QredoVault alloc] initWithClient:self.client vaultKeys:keys withLocalIndex:NO];
    return _store;
}

@end


@implementation QredoConversation


-(void)remoteFingerPrintCheckedLocally:(void (^)(NSError *error))completionHandler{
    self.metadata.authStatus |= 2;
    [self updateConversationWithCompletionHandler:completionHandler];
}

-(void)localFingerPrintCheckedRemotely:(void (^)(NSError *error))completionHandler{
    self.metadata.authStatus |= 1;
    [self updateConversationWithCompletionHandler:completionHandler];
}

-(QredoAuthenticationStatus)authTrafficLight{
    if (self.metadata.authStatus && 1 == 1)return QREDO_GREEN;
    
    return QREDO_RED;
}




-(NSString*)creatorFingerPrint{
    NSData *fp =  [QredoCrypto sha256:[self creatorPublicKey]];
    return [QredoUtils dataToHexString:fp];
}


-(NSString*)responderFingerPrint{
    NSData *fp = [QredoCrypto sha256:[self responderPublicKey]];
    return [QredoUtils dataToHexString:fp];
}


-(NSString*)fingerPrintPair{
    NSMutableData *fingerPrintData = [[NSMutableData alloc] init];
    [fingerPrintData appendData:[self creatorPublicKey]];
    [fingerPrintData appendData:[self responderPublicKey]];
    NSData *fp = [QredoCrypto sha256:fingerPrintData];
    return [QredoUtils dataToHexString:fp];
}


-(NSData*)creatorPublicKey{
    if ([self.metadata amRendezvousOwner]==YES){
        return _myPublicKey.data;
    }else{
        return _yourPublicKey.data;
    }
}


-(NSData*)responderPublicKey{
    if ([self.metadata amRendezvousOwner]==NO){
        return _myPublicKey.data;
    }else{
        return _yourPublicKey.data;
    }
}


- (instancetype)copyWithZone:(NSZone *)zone {
    return self; // for immutable objects
}

- (QredoConversationMetadata *)metadata{
    return _metadata;
}


- (void)resetHighWatermark{
    _highWatermark = QredoConversationHighWatermarkOrigin;
}

- (void)sendMessageWithoutStoring:(QredoConversationMessage*)message
                completionHandler:(void(^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler{
    QredoLogVerbose(@"Start sendMessageWithoutStoring");
    QLFConversationMessage *messageLF = [message messageLF];

    QLFEncryptedConversationItem *encryptedItem = [_conversationCrypto encryptMessage:messageLF
                                                        bulkKey:_outboundBulkKey
                                                        authKey:_outboundAuthKey];

    NSData *signaturePayloadData = [QredoPrimitiveMarshallers marshalObject:encryptedItem
                                                                 marshaller:[QLFEncryptedConversationItem marshaller]
                                                              includeHeader:NO];

    NSError *error = nil;
    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:_outboundSigningKey]
                                            operationType:[QLFOperationType operationCreate]
                                           marshalledData:signaturePayloadData
                                                    error:&error];

    if (error) {
        if (completionHandler)completionHandler(nil, error);
        return;
    }

    
    // it may happen that both watermark and error != nil, when the message has been sent but failed to be stored
    [_conversationService publishWithQueueId:_outboundQueueId
                                        item:encryptedItem
                                   signature:ownershipSignature
                           completionHandler:^(QLFConversationPublishResult *result, NSError *error)
     {
         QredoLogVerbose(@"Completion start publishWithQueueId");
         if (error) {
             if (completionHandler)completionHandler(QredoConversationHighWatermarkOrigin, error);
             return;
         }

         if (!result) {
             if (completionHandler)completionHandler(QredoConversationHighWatermarkOrigin,
                               [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationUnknown
                                               userInfo:@{NSLocalizedDescriptionKey: @"Empty result"}]);
             return;
         }

         QredoConversationHighWatermark *watermark = [[QredoConversationHighWatermark alloc] initWithSequenceValue:result.sequenceValue];

         if (completionHandler)completionHandler(watermark, error);
         QredoLogVerbose(@"Completion end publishWithQueueId");
     }];
}

- (void)publishMessage:(QredoConversationMessage *)message
     completionHandler:(void(^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler{
    QredoLogVerbose(@"Start publish message");
    if (_deleted) {
        QredoLogVerbose(@"deleted is true");
        if (completionHandler)completionHandler(nil, [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationDeleted
                                               userInfo:@{NSLocalizedDescriptionKey: @"Conversation has been deleted"}]);
        return;
    }

    // Adding _created field with current date
    NSMutableDictionary *summaryValues = [message.summaryValues mutableCopy];
    if (!summaryValues) summaryValues = [NSMutableDictionary dictionary];

    [summaryValues setObject:[QredoNetworkTime dateTime] forKey:kQredoConversationMessageKeyCreated];

    QredoConversationMessage *modifiedMessage = [[QredoConversationMessage alloc] initWithValue:message.value
                                                                                       dataType:message.dataType
                                                                                  summaryValues:summaryValues];


    if (!self.metadata.isPersistent || [message isControlMessage]) {
         QredoLogVerbose(@"not persistent or control ");
        [self sendMessageWithoutStoring:modifiedMessage completionHandler:completionHandler];
        return;
    }


    [self storeMessage:modifiedMessage
                isMine:YES
     completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)    {
        if (error) {
            QredoLogVerbose(@"store Message Error");
            if (completionHandler)completionHandler(nil, error);
            return ;
        }
        [summaryValues setObject:newItemDescriptor.sequenceId forKey:kQredoConversationSequenceId];
        [summaryValues setObject:@(newItemDescriptor.sequenceValue) forKey:kQredoConversationSequenceValue]; // TODO: will not work with int64

        QredoConversationMessage *modifiedMessage = [[QredoConversationMessage alloc] initWithValue:message.value
                                                                                           dataType:message.dataType
                                                                                      summaryValues:summaryValues];

        QredoLogVerbose(@"start sendMessageWithoutStoring");
        [self sendMessageWithoutStoring:modifiedMessage completionHandler:completionHandler];
        QredoLogVerbose(@"end sendMessageWithoutStoring");
    }];
    QredoLogVerbose(@"End publish message");
}

- (void)acknowledgeReceiptUpToHighWatermark:(QredoConversationHighWatermark*)highWatermark{
    // TODO: Implement acknowledgeReceiptUpToHighWatermark
}

- (void)addConversationObserver:(id<QredoConversationObserver>)observer{
    QredoLogInfo(@"Added conversation observer");
    [_observers addObserver:observer];
    
    if (!_updateListener.isListening) {
        [_updateListener startListening];
    }
}

- (void)removeConversationObserver:(id<QredoConversationObserver>)observer{
    QredoLogInfo(@"Remove conversation observer");
    [_observers removeObserver:observer];
    
    if ([_observers count] < 1 && _updateListener.isListening) {
        [_updateListener stopListening];
    }
}

- (void)notifyObservers:(void(^)(id<QredoConversationObserver> observer))notificationBlock{
    [_observers notifyObservers:notificationBlock];
}


- (void)deleteConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler{
    NSData *qrtValue = [QredoPrimitiveMarshallers marshalObject:[QLFCtrl qRT]
                                                     marshaller:[QLFCtrl marshaller]];
    
    QredoConversationMessage *leftControlMessage = [[QredoConversationMessage alloc] initWithValue:qrtValue
                                                                                            dataType:kQredoConversationMessageTypeControl
                                                                                       summaryValues:nil];

    [self publishMessage:leftControlMessage
       completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error){
        if (error) {
            if (completionHandler)completionHandler(error);
            return ;
        }
        
        _deleted = YES;
        
        QredoVault *vault = [_client systemVault];

        [vault getItemMetadataWithDescriptor:self.metadata.conversationRef.vaultItemDescriptor
                           completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
        {
            if (error) {
                QredoLogError(@"Delete Conversation failed with error %@",error);

                if (completionHandler)completionHandler(error);
                return ;
            }

            [vault deleteItem:vaultItemMetadata
            completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
                
                if (completionHandler)completionHandler(error);
            }];
            
        }];
    }];
}

// TODO: DH - Reorder parameters to be consistent with enumerate methods? (i.e. move 'since' to 2nd argument as reads better)
- (void)subscribeToMessagesWithBlock:(void(^)(QredoConversationMessage *message))block
       subscriptionTerminatedHandler:(void (^)(NSError *))subscriptionTerminatedHandler
                               since:(QredoConversationHighWatermark *)sinceWatermark
                highWatermarkHandler:(void(^)(QredoConversationHighWatermark *newWatermark))highWatermarkHandler{

    NSError *error = nil;
    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:_inboundSigningKey]
                                            operationType:[QLFOperationType operationList]
                                           marshalledData:nil
                                                    error:&error];

    if (error) {
        subscriptionTerminatedHandler(error);
        return;
    }

    // Subscription is an inbound only service
    [_conversationService subscribeWithQueueId:_inboundQueueId
                                     signature:ownershipSignature
                             completionHandler:^(QLFConversationItemWithSequenceValue *result, NSError *error) {
        if (error) {
            subscriptionTerminatedHandler(error);
            return;
        }

        if (!result) {
            return ;
        }

        QLFConversationQueryItemsResult *resultItems
        = [QLFConversationQueryItemsResult conversationQueryItemsResultWithItems:@[result]
                                                                maxSequenceValue:result.sequenceValue
                                                                         current:0];

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

    [self qredoUpdateListener:_updateListener pollWithCompletionHandler:^(NSError *error) {
        if (error) {
            subscriptionTerminatedHandler(error);
            return;
        }
    }];
}



- (void)enumerateReceivedMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                                     since:(QredoConversationHighWatermark*)sinceWatermark
                         completionHandler:(void(^)(NSError *error))completionHandler{
    __block int messageCount =0;
    __block QredoConversationHighWatermark *highWaterMark;
    
    [self enumerateReceivedMessagesPagedUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
        messageCount++;
        if (block)block(message,stop);
        highWaterMark = message.highWatermark;
    } since:sinceWatermark completionHandler:^(NSError *error) {
        if (messageCount>0){
            //maybe some more messages - recurse
            [self enumerateReceivedMessagesUsingBlock:block
                                               since:highWaterMark
                                   completionHandler:completionHandler];
        }else{
            QredoLogInfo(@"Enumerate received messages complete");
            if (completionHandler)completionHandler(error);
        }
    }];
}


- (void)enumerateReceivedMessagesPagedUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                              since:(QredoConversationHighWatermark*)sinceWatermark
                  completionHandler:(void(^)(NSError *error))completionHandler{
    [self enumerateMessagesUsingBlock:block
                                since:sinceWatermark
                    completionHandler:completionHandler
                 highWatermarkHandler:nil];
}

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                              since:(QredoConversationHighWatermark*)sinceWatermark
                  completionHandler:(void(^)(NSError *error))completionHandler
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler{
    [self enumerateMessagesUsingBlock:block
                             incoming:true
               excludeControlMessages:YES
                                since:sinceWatermark
                    completionHandler:completionHandler
                 highWatermarkHandler:highWatermarkHandler];
}




- (void)enumerateSentMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                                     since:(QredoConversationHighWatermark*)sinceWatermark
                         completionHandler:(void(^)(NSError *error))completionHandler{
    
        __block int messageCount =0;
        __block QredoConversationHighWatermark *highWaterMark;
    
        [self enumerateSentMessagesPagedUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
            messageCount++;
            if (block)block(message,stop);
            highWaterMark = message.highWatermark;
        } since:sinceWatermark completionHandler:^(NSError *error) {
            if (messageCount>0){
                //maybe some more messages - recurse
                [self enumerateSentMessagesUsingBlock:block
                                                   since:highWaterMark
                                       completionHandler:completionHandler];
            }else{
                QredoLogInfo(@"Enumerate Sent messages complete");
                if (completionHandler)completionHandler(error);
            }
        }];
}




- (void)enumerateSentMessagesPagedUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                                  since:(QredoConversationHighWatermark*)sinceWatermark
                      completionHandler:(void(^)(NSError *error))completionHandler{
    [self enumerateMessagesUsingBlock:block
                             incoming:false
               excludeControlMessages:YES
                                since:sinceWatermark
                    completionHandler:completionHandler
                 highWatermarkHandler:nil];
}



#pragma mark -
#pragma mark Qredo Update Listener - Data Source
- (BOOL)qredoUpdateListenerDoesSupportMultiResponseQuery:(QredoUpdateListener *)updateListener{
    return _client.serviceInvoker.supportsMultiResponse;
}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
  pollWithCompletionHandler:(void (^)(NSError *))completionHandler{
    
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
subscribeWithCompletionHandler:(void (^)(NSError *))completionHandler{
    
    if ([_observers count] == 0) {
        //    NSAssert([_observers count] > 0, @"Conversation observers should be added before starting listening for the updates");
        return;
    }

    // Subscribe to conversations newer than our highwatermark
    [self subscribeToMessagesWithBlock:^(QredoConversationMessage *message) {
        [_updateListener processSingleItem:message sequenceValue:message.highWatermark.sequenceValue];

    } subscriptionTerminatedHandler:^(NSError *error) {
        [_updateListener didTerminateSubscriptionWithError:error];
    } since:self.highWatermark highWatermarkHandler:^(QredoConversationHighWatermark *newWatermark) {
        self->_highWatermark = newWatermark;
    }];

}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
unsubscribeWithCompletionHandler:(void (^)(NSError *))completionHandler{
    // TODO: DH - No current way to stop subscribing, short of disconnecting from server. Services team may add support for this in future.
    [[NSNotificationCenter defaultCenter] removeObserver:updateListener name:@"resubscribe" object:nil];
//    updateListener = nil;
}

#pragma mark Qredo Update Listener - Delegate
- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item{
    
    [self notifyObservers:^(id<QredoConversationObserver> observer) {
    QredoConversationMessage *message = (QredoConversationMessage *)item;
    if ([message isControlMessage]) {
        if ([message controlMessageType] == QredoConversationControlMessageTypeLeft &&
                [observer respondsToSelector:@selector(qredoConversationOtherPartyHasLeft:)]) {
                [observer qredoConversationOtherPartyHasLeft:self];
        }
    } else {
            [observer qredoConversation:self didReceiveNewMessage:message];
    }
    }];
}

@end