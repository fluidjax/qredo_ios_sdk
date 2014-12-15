#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoRendezvousPrivate.h"
#import "QredoConversationPrivate.h"

#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"
#import "QredoServiceInvoker.h"

#import "QredoKeychain.h"
#import "QredoKeychainArchiver.h"
#import "QredoKeychainArchiverForAppleKeychain.h"
#import "QredoKeychainSender.h"
#import "QredoKeychainReceiver.h"

NSString *const QredoClientOptionCreateNewSystemVault = @"com.qredo.option.create.new.system.vault";
NSString *const QredoClientOptionServiceURL = @"com.qredo.option.serviceUrl";

static NSString *const QredoClientDefaultServiceURL = @"http://dev.qredo.me:8080/services";
static NSString *const QredoClientMQTTServiceURL = @"tcp://dev.qredo.me:1883";


static NSString *const QredoKeychainOperatorName = @"Qredo Mock Operator";
static NSString *const QredoKeychainOperatorAccountId = @"1234567890";
static NSString *const QredoKeychainPassword = @"Password123";

@implementation QredoClientOptions

- (instancetype)initWithMQTT:(BOOL)useMQTT
{
    return [self initWithMQTT:useMQTT resetData:NO];
}

- (instancetype)initWithMQTT:(BOOL)useMQTT resetData:(BOOL)resetData
{
    self = [super init];
    self.useMQTT = useMQTT;
    self.resetData = resetData;
    return self;
}

- (instancetype)initWithResetData:(BOOL)resetData
{
    self = [super init];
    self.resetData = resetData;
    return self;
}
@end

// Private stuff
@interface QredoClient ()
{
    QredoQUID *_vaultId;

    QredoVault *_defaultVault;
    QredoServiceInvoker *_serviceInvoker;

    dispatch_queue_t _rendezvousQueue;
}

@property NSURL *serviceURL;

/** Creates instance of qredo client
 @param serviceURL Root URL for Qredo services
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL;

/**
 @param serviceURL serviceURL Root URL for Qredo services
 @param options qredo options.
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL options:(NSDictionary*)options;

@end

@implementation QredoClient

- (QredoVault*)systemVault
{
    // For rev1 we have only one vault
    // Keeping this method as a placeholder and it is used in Rendezvous and Conversations
    return _defaultVault;
}

- (QredoServiceInvoker*)serviceInvoker {
    return _serviceInvoker;
}

+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes vaultDataTypes:(NSArray*)vaultDataTypes completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler
{
    [self authorizeWithConversationTypes:conversationTypes vaultDataTypes:vaultDataTypes options:nil completionHandler:completionHandler];
}

+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes vaultDataTypes:(NSArray*)vaultDataTypes options:(QredoClientOptions*)options completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler
{
    NSURL *serviceURL = [NSURL URLWithString:QredoClientDefaultServiceURL];
    NSDictionary *vaultOptions = nil;

    if (options) {
        if (options.useMQTT) {
            serviceURL = [NSURL URLWithString:QredoClientMQTTServiceURL];
        }

        if (options.resetData) {
            vaultOptions = [NSDictionary dictionaryWithObject:@YES forKey:QredoClientOptionCreateNewSystemVault];
        }
    }

    QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL options:vaultOptions];

    completionHandler(client, nil);
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
{
    return [self initWithServiceURL:serviceURL options:nil];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL options:(NSDictionary*)options
{
    self = [self init];
    if (!self) return nil;

    _serviceURL = serviceURL;
    _serviceInvoker = [[QredoServiceInvoker alloc] initWithServiceURL:_serviceURL];

    _rendezvousQueue = dispatch_queue_create("com.qredo.rendezvous", nil);

    [self loadState];
    
    BOOL systemVaultKeychainNeesSaving = NO;
    
    id shouldCreateNewVault = [options objectForKey:QredoClientOptionCreateNewSystemVault];
    if ([shouldCreateNewVault boolValue] == YES || !_defaultVault) {
        QredoKeychain *systemVaultKeychain = [self createDefaultKeychain];
        _defaultVault = [[QredoVault alloc] initWithClient:self qredoKeychain:systemVaultKeychain];
        systemVaultKeychainNeesSaving = YES;
    }
    
    if (systemVaultKeychainNeesSaving) {
        [self saveState];
    }

    return self;
}

- (BOOL)isAuthenticated
{
    // rev 1 doens't have authentication
    return YES;
}

- (void)authenticateWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    completionHandler(nil);
}

- (void)closeSession
{
    // Do nothing in rev 1
}

- (QredoVault*) defaultVault
{
    return _defaultVault;
}

#pragma mark -
#pragma mark Rendezvous

- (void)createRendezvousWithTag:(NSString *)tag configuration:(QredoRendezvousConfiguration *)configuration completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    // although createRendezvousWithTag is asynchronous, it generates keys synchronously, which may cause a lag
    dispatch_async(_rendezvousQueue, ^{
        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithClient:self];
        [rendezvous createRendezvousWithTag:tag configuration:configuration completionHandler:^(NSError *error) {
            if (error) {
                completionHandler(nil, error);
            } else {
                completionHandler(rendezvous, error);
            }
        }];
    });
}

- (QredoRendezvous*)rendezvousFromVaultItem:(QredoVaultItem*)vaultItem error:(NSError**)error {
    @try {
        QredoRendezvousDescriptor *descriptor = [QredoPrimitiveMarshallers unmarshalObject:vaultItem.value
                                                                              unmarshaller:[QredoClientMarshallers rendezvousDescriptorUnmarshaller]];

        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithClient:self fromLFDescriptor:descriptor];
        rendezvous.configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:descriptor.conversationType
                                                                                  durationSeconds:[descriptor.durationSeconds anyObject]
                                                                                 maxResponseCount:[descriptor.maxResponseCount anyObject]];
        return rendezvous;
    }
    @catch (NSException *e) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey:@"Failed to extract rendezvous from the vault item",
                                                NSUnderlyingErrorKey: e
                                                }];
        }
        return nil;
    }
}

- (QredoConversation*)conversationFromVaultItem:(QredoVaultItem*)vaultItem error:(NSError**)error {
    @try {
        QredoConversationDescriptor *descriptor = [QredoPrimitiveMarshallers unmarshalObject:vaultItem.value
                                                                              unmarshaller:[QredoClientMarshallers conversationDescriptorUnmarshaller]];

        QredoConversation *conversation = [[QredoConversation alloc] initWithClient:self fromLFDescriptor:descriptor];
        return conversation;
    }
    @catch (NSException *e) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversatioinInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey:@"Failed to extract rendezvous from the vault item",
                                                NSUnderlyingErrorKey: e
                                                }];
        }
        return nil;
    }
}

- (void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];

    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
        if ([vaultItemMetadata.dataType isEqualToString:kQredoRendezvousVaultItemType]) {

            NSString *tag = [vaultItemMetadata.summaryValues objectForKey:kQredoRendezvousVaultItemLabelTag];
            QredoRendezvousMetadata *metadata = [[QredoRendezvousMetadata alloc] initWithTag:tag vaultItemDescriptor:vaultItemMetadata.descriptor];

            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        completionHandler(error);
    }];
}

- (void)fetchRendezvousWithTag:(NSString *)tag completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];
    QredoQUID *vaultItemId = [vault itemIdWithName:tag type:kQredoRendezvousVaultItemType];

    QredoVaultItemDescriptor *itemDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:vaultItemId];
    [self fetchRendezvousWithVaultItemDescriptor:itemDescriptor completionHandler:completionHandler];
}

- (void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    [self fetchRendezvousWithVaultItemDescriptor:metadata.vaultItemDescriptor completionHandler:completionHandler];
}


// private method
- (void)fetchRendezvousWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];

    [vault getItemWithDescriptor:vaultItemDescriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return ;
        }

        NSError *parsingError = nil;
        QredoRendezvous *rendezvous = [self rendezvousFromVaultItem:vaultItem error:&parsingError];

        completionHandler(rendezvous, parsingError);
    }];
}

- (void)respondWithTag:(NSString *)tag completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler
{
    dispatch_async(_rendezvousQueue, ^{
        QredoConversation *conversation = [[QredoConversation alloc] initWithClient:self];
        [conversation respondToRendezvousWithTag:tag completionHandler:^(NSError *error) {
            if (error) {
                completionHandler(nil, error);
            } else {
                completionHandler(conversation, nil);
            }
        }];
    });
}

- (void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block completionHandler:(void (^)(NSError *))completionHandler
{
    QredoVault *vault = [self systemVault];

    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
        if ([vaultItemMetadata.dataType isEqualToString:kQredoConversationVaultItemType]) {
            QredoConversationMetadata *metadata = [[QredoConversationMetadata alloc] init];
            metadata.conversationId = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelId];
            metadata.amRendezvousOwner = [[vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelAmOwner] boolValue];
            metadata.type = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelType];
            metadata.rendezvousTag = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelTag];

            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        completionHandler(error);
    }];
}

- (void)fetchConversationWithId:(QredoQUID*)conversationId completionHandler:(void(^)(QredoConversation* conversation, NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];

    QredoVaultId *vaultItemId = [vault itemIdWithQUID:conversationId type:kQredoConversationVaultItemType];
    QredoVaultItemDescriptor *vaultItemDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:vaultItemId];
    [vault getItemWithDescriptor:vaultItemDescriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return ;
        }

        NSError *parsingError = nil;
        QredoConversation *conversation = [self conversationFromVaultItem:vaultItem error:&parsingError];
        completionHandler(conversation, parsingError);
    }];
}


#pragma mark -
#pragma mark Private Methods

- (void)saveState
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    [self saveSystemVaultKeychain:_defaultVault.qredoKeychain withKeychainWithKeychainArchiver:keychainArchiver error:nil];
}

- (void)loadState
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    QredoKeychain *systemVaultKeychain = [self loadSystemVaultKeychainWithKeychainArchiver:keychainArchiver error:nil];
    if (systemVaultKeychain) {
        _defaultVault = [[QredoVault alloc] initWithClient:self qredoKeychain:systemVaultKeychain];
    }
}

- (id<QredoKeychainArchiver>)qredoKeychainArchiver
{
    return [[QredoKeychainArchiverForAppleKeychain alloc] init];
}

- (QredoKeychain *)createDefaultKeychain {
    
    QredoOperatorInfo *operatorInfo = [QredoOperatorInfo operatorInfoWithName:QredoKeychainOperatorName
                                                                   serviceUri:self.serviceURL.absoluteString
                                                                    accountID:QredoKeychainOperatorAccountId
                                                         currentServiceAccess:[NSSet set]
                                                            nextServiceAccess:[NSSet set]];
    
    QredoQUID *vaultId = [QredoQUID QUID];
    
    const uint8_t bulkKeyBytes[] = {'b','u','l','k','d','e','m','o','k','e','y'};
    const uint8_t authenticationKeyBytes[] = {'a','u','t','h','d','e','m','o','k','e','y'};
    
    NSData *bulkKey = [NSData dataWithBytes:bulkKeyBytes
                                     length:sizeof(bulkKeyBytes)];
    NSData *authenticationKey = [NSData dataWithBytes:authenticationKeyBytes
                                               length:sizeof(authenticationKeyBytes)];
    
    return [[QredoKeychain alloc]
            initWithOperatorInfo:operatorInfo
            vaultId:vaultId
            authenticationKey:authenticationKey
            bulkKey:bulkKey];
    
}

NSString *systemVaultKeychainArchiveKey = @"com.qredo.system.vault.key";

- (QredoKeychain *)loadSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver error:(NSError **)error {
    return [keychainArchiver loadQredoKeychainForKey:systemVaultKeychainArchiveKey error:error];
}

- (BOOL)saveSystemVaultKeychain:(QredoKeychain *)keychain withKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver error:(NSError **)error {
    return [keychainArchiver saveQredoKeychain:keychain forKey:systemVaultKeychainArchiveKey error:error];
}

- (void)setKeychain:(QredoKeychain *)keychain
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    [self saveSystemVaultKeychain:keychain withKeychainWithKeychainArchiver:keychainArchiver error:nil];
}


@end