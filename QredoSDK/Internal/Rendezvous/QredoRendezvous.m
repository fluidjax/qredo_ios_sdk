/* HEADER GOES HERE */
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
#import "QredoLoggerPrivate.h"
#import "QredoRendezvousHelpers.h"
#import "QredoUpdateListener.h"

#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoSigner.h"
#import "NSData+QredoRandomData.h"
#import "QredoObserverList.h"
#import "QredoNetworkTime.h"
#import "NSData+ParseHex.h"

const QredoRendezvousHighWatermark QredoRendezvousHighWatermarkOrigin = 0;

static const double kQredoRendezvousUpdateInterval = 1.0; //seconds - polling period for responses (non-multi-response transports)
static const double kQredoRendezvousRenewSubscriptionInterval = 300.0; //5 mins in seconds - auto-renew subscription period (multi-response transports)
NSString *const kQredoRendezvousVaultItemType = @"com.qredo.rendezvous";
NSString *const kQredoRendezvousVaultItemLabelTag = @"tag";

NSString *const kQredoRendezvousVaultItemLabelAuthenticationType = @"authenticationType";



@implementation QredoRendezvousRef

-(NSString *)description {
    return [NSString stringWithFormat:@"%@",self.vaultItemDescriptor];
}


@end

@implementation QredoRendezvousMetadata

-(instancetype)initWithTag:(NSString *)tag
        authenticationType:(QredoRendezvousAuthenticationType)authenticationType
             rendezvousRef:(QredoRendezvousRef *)rendezvousRef
             summaryValues:(NSDictionary *)summaryValues {
    self = [super init];
    
    if (!self)return nil;
    
    _tag = [tag copy];
    _authenticationType = authenticationType;
    _rendezvousRef = rendezvousRef;
    _summaryValues = summaryValues;
    
    return self;
}


@end

@implementation QredoRendezvousConfiguration

-(instancetype)initWithConversationType:(NSString *)conversationType
                        durationSeconds:(long)durationSeconds
                          summaryValues:(NSDictionary *)summaryValues
               isUnlimitedResponseCount:(BOOL)isUnlimitedResponseCount {
    self = [super init];
    
    if (!self)return nil;
    
    _summaryValues = [summaryValues copy];
    _conversationType = [conversationType copy];
    _durationSeconds = durationSeconds;
    _isUnlimitedResponseCount = isUnlimitedResponseCount;
    _expiresAt = nil;
    return self;
}


-(instancetype)initWithConversationType:(NSString *)conversationType
                        durationSeconds:(long)durationSeconds
               isUnlimitedResponseCount:(BOOL)isUnlimitedResponseCount
                          summaryValues:(NSDictionary *)summaryValues
                              expiresAt:(NSDate *)expiresAt {
    self = [super init];
    
    if (!self)return nil;
    
    _summaryValues = [summaryValues copy];
    _conversationType = [conversationType copy];
    _durationSeconds = durationSeconds;
    _isUnlimitedResponseCount = isUnlimitedResponseCount;
    _expiresAt = expiresAt;
    return self;
}


@end

@interface QredoRendezvous () <QredoUpdateListenerDataSource,QredoUpdateListenerDelegate>{
    QredoClient *_client;
    QredoRendezvousHighWatermark _highWatermark;
    
    QLFRendezvous *_rendezvous;
    QredoVault *_vault;
    QredoDhPrivateKey *_requesterPrivateKey;
    QredoDhPublicKey *_requesterPublicKey;
    QLFRendezvousHashedTag *_hashedTag;
    QLFRendezvousDescriptor *_descriptor;
    
    QLFRendezvousAuthType *_lfAuthType;
    
    SecKeyRef _ownershipPrivateKey;
    
    NSString *_tag;
    
    dispatch_queue_t _enumerationQueue;
    QredoObserverList *_observers;
    QredoUpdateListener *_updateListener;
    id _subscriptionCorrelationId;
}

//making the properties read/write for private use
@property QredoRendezvousConfiguration *configuration;
@property (readwrite,copy) NSString *tag;
@property (readwrite) QredoRendezvousAuthenticationType authenticationType;
@property  QredoRendezvousMetadata *metadata;

-(NSSet *)maybe:(long)val;

@end

@implementation QredoRendezvous (Private)


-(void)loadHWM {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (!self.tag){
        self->_highWatermark = QredoRendezvousHighWatermarkOrigin;
        return;
    }
    
    NSNumber *hwmNum = [defaults objectForKey:self.tag];
    
    if (hwmNum==nil){
        self->_highWatermark = QredoRendezvousHighWatermarkOrigin;
    } else {
        self->_highWatermark = [hwmNum longLongValue];
    }
}


-(void)saveHWM {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:@(self.highWatermark) forKey:self.tag];
}


-(instancetype)initWithClient:(QredoClient *)client {
    self = [super init];
    
    if (!self)return nil;
    
    _client = client;
    _rendezvous = [QLFRendezvous rendezvousWithServiceInvoker:_client.serviceInvoker];
    _vault = [_client systemVault];
    
    _enumerationQueue = dispatch_queue_create("com.qredo.rendezvous.enumrate",nil);
    
    _observers = [[QredoObserverList alloc] init];
    
    _updateListener = [[QredoUpdateListener alloc] init];
    _updateListener.delegate = self;
    _updateListener.dataSource = self;
    _updateListener.pollInterval = kQredoRendezvousUpdateInterval;
    _updateListener.renewSubscriptionInterval = kQredoRendezvousRenewSubscriptionInterval;
    return self;
}


-(instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QLFRendezvousDescriptor *)descriptor {
    self = [self initWithClient:client];
    _descriptor = descriptor;
    
    _lfAuthType = _descriptor.authenticationType;
    _tag = _descriptor.tag;
    _hashedTag = _descriptor.hashedTag;
    _requesterPrivateKey = [[QredoDhPrivateKey alloc] initWithData:descriptor.requesterKeyPair.privKey.bytes];
    _requesterPublicKey  = [[QredoDhPublicKey alloc] initWithData:descriptor.requesterKeyPair.pubKey.bytes];
    _ownershipPrivateKey = [[QredoRendezvousCrypto instance] accessControlPrivateKeyWithTag:[_hashedTag QUIDString]];
    [self loadHWM];
    return self;
}


-(instancetype)initWithVaultItem:(QredoClient *)client fromVaultItem:(QredoVaultItem *)vaultItem {
    QLFRendezvousDescriptor *descriptor  = [QredoPrimitiveMarshallers unmarshalObject:vaultItem.value
                                                                         unmarshaller:[QLFRendezvousDescriptor unmarshaller]];
    
    self = [self initWithClient:client fromLFDescriptor:descriptor];
    
    __block BOOL isUnlimitedResponseCount = NO;
    
    [descriptor.responseCountLimit
     ifRendezvousSingleResponse:^{
         isUnlimitedResponseCount = NO;
     }
     ifRendezvousUnlimitedResponses:^{
         isUnlimitedResponseCount = YES;
     }];
    
    
    
    self.configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:descriptor.conversationType
                                                                        durationSeconds:[[descriptor.durationSeconds anyObject] intValue]
                                                                          summaryValues:vaultItem.metadata.summaryValues
                                                               isUnlimitedResponseCount:isUnlimitedResponseCount];
    
    
    QredoVault *vault = [_client systemVault];
    
    QredoRendezvousRef *rendezvousRef = [[QredoRendezvousRef alloc] initWithVaultItemDescriptor:vaultItem.metadata.descriptor
                                                                                          vault:vault];
    
    QredoRendezvousAuthenticationType authenticationType = [[vaultItem.metadata.summaryValues
                                                             objectForKey:kQredoRendezvousVaultItemLabelAuthenticationType] intValue];
    
    
    self.metadata = [[QredoRendezvousMetadata alloc] initWithTag:descriptor.tag
                                              authenticationType:authenticationType
                                                   rendezvousRef:rendezvousRef
                                                   summaryValues:vaultItem.metadata.summaryValues];
    [self loadHWM];
    return self;
}


//TODO: DH - provide alternative method signature for non-X.509 authenticated rendezvous without trustedRootPems?
-(void)createRendezvousWithTag:(NSString *)tag
            authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                 configuration:(QredoRendezvousConfiguration *)configuration
               trustedRootPems:(NSArray *)trustedRootPems
                       crlPems:(NSArray *)crlPems
                signingHandler:(signDataBlock)signingHandler
                appCredentials:(QredoAppCredentials *)appCredentials
             completionHandler:(void (^)(NSError *error))completionHandler {
    QredoLogVerbose(@"Creating rendezvous with (plaintext) tag: %@. TrustedRootPems count: %lul.",tag,(unsigned long)trustedRootPems.count);
    
    //TODO: DH - write tests
    //TODO: DH - validate that the configuration and tag formats match
    //TODO: DH - enforce non-nil trustedRootPems on X.509 PEM
    
    self.configuration = configuration;
    
    QredoRendezvousCrypto *crypto = [QredoRendezvousCrypto instance];
    
    //Box up optional values.
    
    
    NSSet *maybeDurationSeconds  = [self maybe:configuration.durationSeconds];
    QLFRendezvousResponseCountLimit *responseCount = configuration.isUnlimitedResponseCount
    ? [QLFRendezvousResponseCountLimit rendezvousUnlimitedResponses]
    : [QLFRendezvousResponseCountLimit rendezvousSingleResponse];
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> rendezvousHelper = [crypto rendezvousHelperForAuthenticationType:authenticationType
                                                                                             fullTag:tag
                                                                                     trustedRootPems:trustedRootPems
                                                                                             crlPems:crlPems
                                                                                      signingHandler:signingHandler
                                                                                               error:&error];
    
    if (!rendezvousHelper){
        //TODO: [GR]: Filter what errors we pass to the user. What we are currently passing may
        //be to much information.
        if (completionHandler)completionHandler(error);
        
        return;
    }
    
    _tag = [rendezvousHelper tag];
    
    //Hash the tag.
    NSData *masterKey = [crypto masterKeyWithTag:_tag appId:appCredentials.appId];
    QLFAuthenticationCode *authKey = [crypto authenticationKeyWithMasterKey:masterKey];
    _hashedTag  = [crypto hashedTagWithMasterKey:masterKey];
    NSData *responderInfoEncKey = [crypto encryptionKeyWithMasterKey:masterKey];
    
    QredoLogDebug(@"Hashed tag: %@",_hashedTag);
    
    //Generate the rendezvous key pairs.
    QLFKeyPairLF *ownershipKeyPair = [crypto newAccessControlKeyPairWithId:[_hashedTag QUIDString]];
    QLFKeyPairLF *requesterKeyPair     = [crypto newRequesterKeyPair];
    
    _requesterPrivateKey = [[QredoDhPrivateKey alloc] initWithData:requesterKeyPair.privKey.bytes];
    _requesterPublicKey  = [[QredoDhPublicKey alloc] initWithData:requesterKeyPair.pubKey.bytes];
    
    _ownershipPrivateKey = [crypto accessControlPrivateKeyWithTag:[_hashedTag QUIDString]];
    
    NSData *ownershipPublicKeyBytes      = [[ownershipKeyPair pubKey] bytes];
    NSData *requesterPublicKeyBytes      = [[requesterKeyPair pubKey] bytes];
    
    
    QLFRendezvousResponderInfo *responderInfo = [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKeyBytes
                                                                                                         conversationType:configuration.conversationType
                                                                                                                 transCap:[NSSet set]];
    NSData *encryptedResponderData = [crypto encryptResponderInfo:responderInfo
                                                    encryptionKey:responderInfoEncKey];
    
    //Generate the authentication code.
    QLFAuthenticationCode *authenticationCode  = [crypto authenticationCodeWithHashedTag:_hashedTag
                                                                       authenticationKey:authKey
                                                                  encryptedResponderData:encryptedResponderData];
    
    QLFRendezvousAuthType *authType = nil;
    
    if ([rendezvousHelper type] == QredoRendezvousAuthenticationTypeAnonymous){
        authType = [QLFRendezvousAuthType rendezvousAnonymous];
    } else {
        QLFRendezvousAuthSignature *authSignature = [rendezvousHelper signatureWithData:authenticationCode error:&error];
        
        if (!authSignature){
            //TODO: [GR]: Filter what errors we pass to the user. What we are currently passing may
            //be to much information.
            if (completionHandler)completionHandler(error);
            
            return;
        }
        
        authType = [QLFRendezvousAuthType rendezvousTrustedWithSignature:authSignature];
    }
    
    _lfAuthType = authType;
    
    //Create the Rendezvous.
    QLFEncryptedResponderInfo *encryptedResponderInfo = [QLFEncryptedResponderInfo encryptedResponderInfoWithValue:encryptedResponderData
                                                                                                authenticationCode:authenticationCode
                                                                                                authenticationType:authType];
    
    QLFRendezvousCreationInfo *_creationInfo = [QLFRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:_hashedTag
                                                                                              durationSeconds:maybeDurationSeconds
                                                                                           responseCountLimit:responseCount
                                                                                           ownershipPublicKey:ownershipPublicKeyBytes
                                                                                       encryptedResponderInfo:encryptedResponderInfo];
    
    [_rendezvous createWithCreationInfo:_creationInfo
                      completionHandler:^(QLFRendezvousCreateResult *result,NSError *error) {
                          if (error){
                              if (completionHandler) completionHandler(error);
                              
                              return;
                          }
                          
                          [result   ifRendezvousCreated:^(NSSet *expiresAt) {
                              _descriptor = [QLFRendezvousDescriptor            rendezvousDescriptorWithTag:_tag
                                                                                                  hashedTag:_hashedTag
                                                                                           conversationType:configuration.conversationType
                                                                                         authenticationType:authType
                                                                                            durationSeconds:maybeDurationSeconds
                                                                                                  expiresAt:expiresAt
                                                                                         responseCountLimit:responseCount
                                                                                           requesterKeyPair:requesterKeyPair
                                                                                           ownershipKeyPair:ownershipKeyPair];
                              self.configuration.expiresAt = [[expiresAt anyObject] asDate];
                              [self storeWithCompletionHandler:^(NSError *error) {
                                  if (completionHandler) completionHandler(error);
                              }];
                          }
                              ifRendezvousAlreadyExists:^{
                                  if (completionHandler) completionHandler([NSError  errorWithDomain:QredoErrorDomain
                                                                                                code:QredoErrorCodeRendezvousAlreadyExists
                                                                                            userInfo:@{ NSLocalizedDescriptionKey:@"Rendezvous with the specified tag already exists" }]);
                              }];
                      }];
}


-(void)storeWithCompletionHandler:(void (^)(NSError *error))completionHandler {
    NSData *serializedDescriptor = [QredoPrimitiveMarshallers marshalObject:_descriptor
                                                                 marshaller:[QLFRendezvousDescriptor marshaller]];
    
    
    NSMutableDictionary *newValues;
    
    if (self.configuration.summaryValues){
        newValues = [self.configuration.summaryValues mutableCopy];
    } else {
        newValues = [[NSMutableDictionary alloc] init];
    }
    
    //overrite these values
    [newValues setObject:self.tag forKey:kQredoRendezvousVaultItemLabelTag];
    [newValues setObject:[NSNumber numberWithInt:self.authenticationType] forKey:kQredoRendezvousVaultItemLabelAuthenticationType];
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:kQredoRendezvousVaultItemType
                                                                                     created:[QredoNetworkTime dateTime]
                                                                               summaryValues:newValues];
    
    QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:serializedDescriptor];
    
    [_client.systemVault
     strictlyPutNewItem:vaultItem
     completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
         if (newItemMetadata){
             QredoRendezvousRef *rendezvousRef = [[QredoRendezvousRef alloc] initWithVaultItemDescriptor:newItemMetadata.descriptor
                                                                                                   vault:_client.systemVault];
             self.metadata = [[QredoRendezvousMetadata alloc] initWithTag:self.tag
                                                       authenticationType:self.authenticationType
                                                            rendezvousRef:rendezvousRef
                                                            summaryValues:newValues];
         }
         
         if (completionHandler) completionHandler(error);
     }];
}


-(void)activateRendezvous:(long)duration completionHandler:(void (^)(NSError *error))completionHandler {
    NSError *error = nil;
    NSSet *durationSeconds  = [self maybe:duration];
    
    NSData *marshalledData = nil;
    NSMutableData *payloadData = [NSMutableData data];
    
    
    marshalledData = [QredoPrimitiveMarshallers marshalObject:nil marshaller:^(id element,QredoWireFormatWriter *writer) { [writer writeQUID:_hashedTag]; } includeHeader:NO];
    [payloadData appendData:marshalledData];
    
    
    QredoMarshaller setMarshaller = [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]];
    marshalledData = [QredoPrimitiveMarshallers marshalObject:durationSeconds marshaller:setMarshaller includeHeader:NO];
    [payloadData appendData:marshalledData];
    
    
    QLFOwnershipSignature *ownershipSignature =
    [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoRSASinger alloc] initWithRSAKeyRef:_ownershipPrivateKey]
                                          operationType:[QLFOperationType operationCreate]
                                         marshalledData:payloadData
                                                  error:&error];
    
    if (error){
        if (completionHandler)completionHandler(error);
        
        return;
    }
    
    [_rendezvous activateWithHashedTag:_hashedTag
                       durationSeconds:durationSeconds
                             signature:ownershipSignature
                     completionHandler:^(QLFRendezvousActivated *result,NSError *error) {
                         if (error){
                             QredoLogError(@"Error activating rendezvous %@",error);
                             
                             if (completionHandler) completionHandler(error);
                             
                             return;
                         }
                         
                         NSSet *expiresAt = [result expiresAt];
                         [self  updateRendezvousWithDuration:duration
                                                   expiresAt:expiresAt
                                           completionHandler:^(NSError *error) {
                                               QredoLogInfo(@"Rendezvous Activated");
                                               
                                               if (completionHandler) completionHandler(error);
                                           }];
                     }];
}


-(void)updateRendezvousWithDuration:(long)duration expiresAt:(NSSet *)expiresAt completionHandler:(void (^)(NSError *error))completionHandler {
    NSSet *durationSeconds = [self maybe:duration];
    
    //the response count will always be unlimited when we activate Rendezvous
    QLFRendezvousResponseCountLimit *responseCount = [QLFRendezvousResponseCountLimit rendezvousUnlimitedResponses];
    
    //create a new QLFRendezvousDescriptor with the updated duration and response count
    //the other values are unchanged
    QLFRendezvousDescriptor *newDescriptor =  [QLFRendezvousDescriptor rendezvousDescriptorWithTag:_tag
                                                                                         hashedTag:_hashedTag
                                                                                  conversationType:_descriptor.conversationType
                                                                                authenticationType:_descriptor.authenticationType
                                                                                   durationSeconds:durationSeconds
                                                                                         expiresAt:expiresAt
                                                                                responseCountLimit:responseCount
                                                                                  requesterKeyPair:_descriptor.requesterKeyPair
                                                                                  ownershipKeyPair:_descriptor.ownershipKeyPair];
    
    _descriptor = newDescriptor;
    
    
    //get the vault item metadata from the vaultitemdescriptor stored in the rendezvous ref
    [_client.systemVault
     getItemMetadataWithDescriptor:self.metadata.rendezvousRef.vaultItemDescriptor
     completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata,NSError *error) {
         if (error){
             if (completionHandler) completionHandler(error);
             
             return;
         }
         
         //serialize the updated rendezvous descriptor into a NSData object
         NSData *updatedRendezvousData = [QredoPrimitiveMarshallers  marshalObject:_descriptor
                                                                        marshaller:[QLFRendezvousDescriptor marshaller]];
         
         QredoVaultItemMetadata *metadataCopy = [vaultItemMetadata mutableCopy];
         
         //create a new vault item with the same metadata and updated rendezvous data
         QredoVaultItem *newVaultItem = [QredoVaultItem  vaultItemWithMetadata:metadataCopy
                                                                         value:updatedRendezvousData];
         
         //add the item to the Vault. This will be the same Rendezvous but will update the sequence value
         [_client.systemVault
          strictlyUpdateItem:newVaultItem
          completionHandler: ^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
              if (error){
                  if (completionHandler) completionHandler(error);
                  
                  return;
              }
              
              //the update will create new metadata so we need to update the rendezvous ref and metadata
              //the actual vault item data will be the same, with just a new sequence value
              if (newItemMetadata){
                  QredoRendezvousRef *rendezvousRef = [[QredoRendezvousRef alloc] initWithVaultItemDescriptor:newItemMetadata.descriptor
                                                                                                        vault:_client.systemVault];
                  self.metadata = [[QredoRendezvousMetadata alloc] initWithTag:self.tag
                                                            authenticationType:self.authenticationType
                                                                 rendezvousRef:rendezvousRef
                                                                 summaryValues:vaultItemMetadata.summaryValues];
                  
                  self.configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:_descriptor.conversationType
                                                                                      durationSeconds:duration
                                                                             isUnlimitedResponseCount:TRUE
                                                                                        summaryValues:metadataCopy.summaryValues
                                                                                            expiresAt:[expiresAt anyObject]];
              }
              
              if (completionHandler) completionHandler(error);
          }];
     }];
}


-(void)deactivateRendezvous:(void (^)(NSError *error))completionHandler {
    NSError *error = nil;
    
    NSData *payloadData = [QredoPrimitiveMarshallers marshalObject:nil
                                                        marshaller:^(id element,QredoWireFormatWriter *writer)
                           {
                               [writer writeQUID:_hashedTag];
                           }
                                                     includeHeader:NO];
    
    QLFOwnershipSignature *ownershipSignature =
    [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoRSASinger alloc] initWithRSAKeyRef:_ownershipPrivateKey]
                                          operationType:[QLFOperationType operationDelete]
                                         marshalledData:payloadData
                                                  error:&error];
    
    if (error){
        if (completionHandler)completionHandler(error);
        
        return;
    }
    
    [_rendezvous deactivateWithHashedTag:_hashedTag
                               signature:ownershipSignature
                       completionHandler:^(QLFRendezvousDeactivated *result,NSError *error)
     {
         if (completionHandler) completionHandler(error);
     }
     ];
}


@end

@implementation QredoRendezvous


+(NSString *)readableToTag:(NSString *)readableText {
    NSData *key = [QredoUtils eng2Key:readableText];
    
    return [QredoUtils dataToHexString:key];
}


+(NSString *)tagToReadable:(NSString *)tag {
    NSData *dataTag = [NSData dataWithHexString:tag];
    
    return [QredoUtils key2Eng:dataTag];
}


-(NSString *)conversationType {
    return self.configuration.conversationType;
}


-(long)duration {
    return self.configuration.durationSeconds;
}


-(BOOL)unlimitedResponses {
    return self.configuration.isUnlimitedResponseCount;
}


-(NSDate *)expiresAt {
    return self.configuration.expiresAt;
}


-(NSString *)tag {
    return _tag;
}


-(NSString *)readableTag {
    return [QredoRendezvous tagToReadable:[self tag]];
}


-(void)setTag:(NSString *)tag {
    _tag = tag;
}


-(NSSet *)maybe:(long)val {
    if (val == 0)return [NSSet new];
    
    return [NSSet setWithObject:[NSNumber numberWithLong:val]];
}


-(void)resetHighWatermark {
    _highWatermark = QredoRendezvousHighWatermarkOrigin;
}


-(void)deleteWithCompletionHandler:(void (^)(NSError *error))completionHandler {
    //TODO: implement later
}


-(void)addRendezvousObserver:(id<QredoRendezvousObserver>)observer {
    [_observers addObserver:observer];
    
    if (!_updateListener.isListening){
        [_updateListener startListening];
    }
}


-(void)removeRendezvousObserver:(id<QredoRendezvousObserver>)observer {
    [_observers removeObserver:observer];
    
    if ([_observers count] < 1 && _updateListener.isListening){
        [_updateListener stopListening];
    }
}


-(void)notifyObservers:(void (^)(id<QredoRendezvousObserver> observer))notificationBlock {
    [_observers notifyObservers:notificationBlock];
}


-(BOOL)processResponse:(QLFRendezvousResponse *)response
         sequenceValue:(QLFRendezvousSequenceValue)sequenceValue
             withBlock:(void (^)(QredoConversation *conversation))block
          errorHandler:(void (^)(NSError *))errorHandler {
    return YES;
}


-(void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *metadata,BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler {
    QredoVault *systemVault = _vault;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@" 1 == 1 "];
    
//CSM changed to use the INDEX!
    [systemVault enumerateIndexUsingPredicate:predicate withBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
//    [systemVault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stopVaultEnumeration) {
        
        
        if ([vaultItemMetadata.dataType
             isEqualToString:kQredoConversationVaultItemType]){
            QredoConversationMetadata *metadata = [[QredoConversationMetadata alloc] init];
            //TODO: DH - populate metadata.rendezvousMetadata
            metadata.conversationId = [vaultItemMetadata.summaryValues
                                       objectForKey:kQredoConversationVaultItemLabelId];
            metadata.amRendezvousOwner = [[vaultItemMetadata.summaryValues
                                           objectForKey:kQredoConversationVaultItemLabelAmOwner] boolValue];
            metadata.type = [vaultItemMetadata.summaryValues
                             objectForKey:kQredoConversationVaultItemLabelType];
            metadata.rendezvousTag = [vaultItemMetadata.summaryValues
                                      objectForKey:kQredoConversationVaultItemLabelTag];
            metadata.conversationRef = [[QredoConversationRef alloc]          initWithVaultItemDescriptor:vaultItemMetadata.descriptor
                                                                                                    vault:systemVault];
            
            
            //ignore any rendezvous which are not for this rendezvous's tag
            BOOL correctRendezvous      = [metadata.rendezvousTag
                                           isEqualToString:_tag];
            BOOL stopObjectEnumeration  = NO;//here we lose the feature when *stop == YES, then we are on the last object
            
            if (correctRendezvous){
                block(metadata,&stopObjectEnumeration);
            }
            
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    }
                             completionHandler:^(NSError *error) {
                                 QredoLogInfo(@"Enumermate Conversation Complete");
                                 
                                 if (completionHandler) completionHandler(error);
                             }];
}


-(void)enumerateConversationsWithBlock:(void (^)(QredoConversation *conversation,BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler
                                 since:(QredoRendezvousHighWatermark)sinceWatermark
                  highWatermarkHandler:(void (^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler {
    [self enumerateResponsesWithBlock:^(QLFRendezvousResponsesResult *rendezvousResponse,QredoConversation *conversation,BOOL *stop) {
        block(conversation,stop);
    }
                    completionHandler:^(NSError *error) {
                        QredoLogInfo(@"Enumerate Conversations complete");
                        
                        if (completionHandler) completionHandler(error);
                    }
                                since:sinceWatermark
                 highWatermarkHandler:highWatermarkHandler];
}


-(void)enumerateResponsesWithBlock:(void (^)(QLFRendezvousResponsesResult *rendezvousResponse,QredoConversation *conversation,BOOL *stop))block
                 completionHandler:(void (^)(NSError *error))completionHandler
                             since:(QredoRendezvousHighWatermark)sinceWatermark
              highWatermarkHandler:(void (^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler {
    NSError *error = nil;
    NSData *payloadData = [QredoPrimitiveMarshallers marshalObject:nil
                                                        marshaller:^(id element,QredoWireFormatWriter *writer)
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
    
    if (error){
        if (completionHandler)completionHandler(error);
        
        return;
    }
    
    [_rendezvous getResponsesWithHashedTag:_hashedTag
                                     after:sinceWatermark
                                 signature:ownershipSignature
                         completionHandler:^(QLFRendezvousResponsesResult *result,NSError *error)
     {
         if (error){
             if (completionHandler) completionHandler(error);
             
             return;
         }
         
         [self processRendezvousResponseResult:result
                                 responseIndex:0
                       rendezvousResponseBlock:block
                          highWatermarkHandler:highWatermarkHandler
                             completionHandler:completionHandler];
     }];
}


-(void)processRendezvousResponseResult:(QLFRendezvousResponsesResult *)result
                         responseIndex:(NSUInteger)responseIndex
               rendezvousResponseBlock:(void (^)(QLFRendezvousResponsesResult *rendezvousResponse,QredoConversation *conversation,BOOL *stop))rendezvousResponseBlock
                  highWatermarkHandler:(void (^)(QredoRendezvousHighWatermark newWatermark))highWatermarkHandler
                     completionHandler:(void (^)(NSError *error))completionHandler {
    void (^finishEnumeration)() = ^{
        if (result.sequenceValue && highWatermarkHandler){
            highWatermarkHandler(result.sequenceValue);
        }
        
        if (completionHandler)completionHandler(nil);
    };
    
    void (^continueToNextItem)() = ^{
        dispatch_async(_enumerationQueue,^{
            [self processRendezvousResponseResult:result
                                    responseIndex:responseIndex + 1
                          rendezvousResponseBlock:rendezvousResponseBlock
                             highWatermarkHandler:highWatermarkHandler
                                completionHandler:completionHandler];
        });
    };
    
    if (responseIndex >= result.responses.count){
        finishEnumeration();
        return;
    }
    
    QLFRendezvousResponse *response = [result.responses objectAtIndex:responseIndex];
    
    [self createConversationAndStoreKeysForResponse:response
                                  completionHandler:^(QredoConversation *conversation,NSError *error)
     {
         if (error && error.code == QredoErrorCodeVaultItemNotFound){
             continueToNextItem();
             return;
         }
         
         BOOL stop = result.responses.lastObject == response;
         
         if (!conversation && !error){
             //Might need to ignore the error, because there is not way for the client application to continue enumeration after this point
             error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousUnknownResponse
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Could not create conversation from response" }];
         }
         
         if (error){
             if (completionHandler) completionHandler(error);
             
             return;
         }
         
         rendezvousResponseBlock(result,conversation,&stop);
         
         if (stop){
             finishEnumeration();
             return;
         }
         
         continueToNextItem();
     }];
}


-(void)createConversationAndStoreKeysForResponse:(QLFRendezvousResponse *)response
                               completionHandler:(void (^)(QredoConversation *conversation,NSError *error))completionHandler {
    QredoConversation *conversation = [[QredoConversation alloc] initWithClient:_client
                                                             authenticationType:_lfAuthType
                                                                  rendezvousTag:_tag
                                                                converationType:_configuration.conversationType];
    
    QredoDhPublicKey *responderPublicKey = [[QredoDhPublicKey alloc] initWithData:response.responderPublicKey];
    
    [conversation generateAndStoreKeysWithPrivateKey:_requesterPrivateKey
                                           publicKey:responderPublicKey
                                         myPublicKey:_requesterPublicKey
                                     rendezvousOwner:YES
                                   completionHandler:^(NSError *error) {
                                       if (error){
                                           if (completionHandler) completionHandler(nil,error);
                                           
                                           return;
                                       }
                                       
                                       if (completionHandler) completionHandler(conversation,nil);
                                   }];
}


-(void)updateRendezvousWithSummaryValues:(NSDictionary *)summaryValues completionHandler:(void (^)(NSError *error))completionHandler {
    //this updates the vault item version of the rendezvous with new summaryValues
    
    //get the vault item metadata from the vaultitemdescriptor stored in the rendezvous ref
    [_client.systemVault
     getItemMetadataWithDescriptor:self.metadata.rendezvousRef.vaultItemDescriptor
     completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata,NSError *error) {
         if (error){
             if (completionHandler) completionHandler(error);
             
             return;
         }
         
         //serialize the updated rendezvous descriptor into a NSData object
         NSData *updatedRendezvousData = [QredoPrimitiveMarshallers  marshalObject:_descriptor
                                                                        marshaller:[QLFRendezvousDescriptor marshaller]];
         
         QredoVaultItemMetadata *metadataCopy = [vaultItemMetadata mutableCopy];
         
         NSDictionary *originalSummaryValues = metadataCopy.summaryValues;
         
         
         NSMutableDictionary *updatedValues = [[NSMutableDictionary alloc] init];
         [updatedValues addEntriesFromDictionary:summaryValues];
         
         //force in the essential metadata
         [updatedValues  setObject:self.tag
                            forKey:kQredoRendezvousVaultItemLabelTag];
         [updatedValues  setObject:[NSNumber numberWithInt:self.authenticationType]
                            forKey:kQredoRendezvousVaultItemLabelAuthenticationType];
         [updatedValues  setObject:[originalSummaryValues objectForKey:@"_created"]
                            forKey:@"_created"];
         [updatedValues  setObject:[NSDate date]
                            forKey:@"_updated"];
         
         metadataCopy.summaryValues = updatedValues;
         
         
         //create a new vault item with the same metadata and updated rendezvous data
         QredoVaultItem *newVaultItem = [QredoVaultItem  vaultItemWithMetadata:metadataCopy
                                                                         value:updatedRendezvousData];
         
         //add the item to the Vault. This will be the same Rendezvous but will update the sequence value
         [_client.systemVault
          strictlyUpdateItem:newVaultItem
          completionHandler: ^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
              if (error){
                  if (completionHandler) completionHandler(error);
                  
                  return;
              }
              
              //the update will create new metadata so we need to update the rendezvous ref and metadata
              //the actual vault item data will be the same, with just a new sequence value
              if (newItemMetadata){
                  QredoRendezvousRef *rendezvousRef = [[QredoRendezvousRef alloc] initWithVaultItemDescriptor:newItemMetadata.descriptor
                                                                                                        vault:_client.systemVault];
                  self.metadata = [[QredoRendezvousMetadata alloc] initWithTag:self.tag
                                                            authenticationType:self.authenticationType
                                                                 rendezvousRef:rendezvousRef
                                                                 summaryValues:updatedValues];
                  
                  self.configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:_descriptor.conversationType
                                                                                      durationSeconds:self.duration
                                                                             isUnlimitedResponseCount:TRUE
                                                                                        summaryValues:updatedValues
                                                                                            expiresAt:self.expiresAt];
              }
              
              if (completionHandler) completionHandler(error);
          }];
     }];
}


#pragma mark -
#pragma mark Qredo Update Listener - Data Source
-(BOOL)qredoUpdateListenerDoesSupportMultiResponseQuery:(QredoUpdateListener *)updateListener {
    return _client.serviceInvoker.supportsMultiResponse;
}


-(void)qredoUpdateListener:(QredoUpdateListener *)updateListener pollWithCompletionHandler:(void (^)(NSError *))completionHandler {
    [self enumerateResponsesWithBlock:^(QLFRendezvousResponsesResult *rendezvousResponse,QredoConversation *conversation,BOOL *stop) {
        [_updateListener       processSingleItem:conversation
                                   sequenceValue:@(rendezvousResponse.sequenceValue)];
    }
                    completionHandler:completionHandler
                                since:self.highWatermark
                 highWatermarkHandler:^(QredoRendezvousHighWatermark newWatermark) {
                     self->_highWatermark = newWatermark;
                     [self saveHWM];
                 }];
}


-(void)qredoUpdateListener:(QredoUpdateListener *)updateListener subscribeWithCompletionHandler:(void (^)(NSError *))completionHandler {
    NSAssert([_observers count] > 0,@"There shoud be 1 or more rendezvous observers before starting listening for the updates");
    
    NSAssert(_subscriptionCorrelationId == nil,@"Already subscribed");
    
    //TODO: DH - look at blocks holding strong reference to self, and whether that's causing
    //Subscribe to conversations newer than our highwatermark
    
    NSData *payloadData = [QredoPrimitiveMarshallers marshalObject:_hashedTag
                                                        marshaller:[QredoPrimitiveMarshallers quidMarshaller]
                                                     includeHeader:NO];
    NSError *error = nil;
    
    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoRSASinger alloc] initWithRSAKeyRef:_ownershipPrivateKey]
                                            operationType:[QLFOperationType operationList]
                                           marshalledData:payloadData
                                                    error:&error];
    
    if (error){
        if (completionHandler)completionHandler(error);
        
        return;
    }
    
    [_rendezvous subscribeToResponsesWithHashedTag:_hashedTag
                                         signature:ownershipSignature
                                 completionHandler:^(QLFRendezvousResponseWithSequenceValue *result,NSError *error) {
                                     if (error){
                                         [_updateListener didTerminateSubscriptionWithError:error];
                                         
                                         if (completionHandler) completionHandler(error);
                                         
                                         return;
                                     }
                                     
                                     [self  createConversationAndStoreKeysForResponse:result.response
                                                                    completionHandler:^(QredoConversation *conversation,NSError *creationError) {
                                                                        if (creationError){
                                                                            if (completionHandler) completionHandler(error);
                                                                            
                                                                            return;
                                                                        }
                                                                        
                                                                        [_updateListener  processSingleItem:conversation
                                                                                              sequenceValue:@(result.sequenceValue)];
                                                                    }];
                                     self->_highWatermark = result.sequenceValue;
                                     [self saveHWM];
                                 }];
}


-(void)qredoUpdateListener:(QredoUpdateListener *)updateListener unsubscribeWithCompletionHandler:(void (^)(NSError *))completionHandler {
    //TODO: ownership
    //[_rendezvous unsubscribeWithCorrelationId:_subscriptionCorrelationId completionHandler:^(NSError *error) {
    //_subscriptionCorrelationId = nil;
    //if (completionHandler)completionHandler(error);
    //}];
    
    [[NSNotificationCenter defaultCenter] removeObserver:updateListener name:@"resubscribe" object:nil];
    //updateListener = nil;
}


#pragma mark Qredo Update Listener - Delegate

-(void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item {
    QredoConversation *conversation = (QredoConversation *)item;
    
    [self notifyObservers:^(id < QredoRendezvousObserver > observer) {
        if ([observer respondsToSelector:@selector(qredoRendezvous:didReceiveReponse:)]){
            [observer   qredoRendezvous:self
                     didReceiveReponse :conversation];
        }
    }];
}


@end
