#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoRendezvousPrivate.h"
#import "QredoConversationPrivate.h"

#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"
#import "QredoServiceInvoker.h"
#import "QredoLogging.h"

#import "QredoKeychain.h"
#import "QredoKeychainArchiver.h"
#import "QredoKeychainSender.h"
#import "QredoKeychainReceiver.h"
#import "NSData+QredoRandomData.h"
#import "QredoManagerAppRootViewController.h"


#import <UIKit/UIKit.h>

NSString *const QredoClientOptionCreateNewSystemVault = @"com.qredo.option.create.new.system.vault";
NSString *const QredoClientOptionServiceURL = @"com.qredo.option.serviceUrl";

static NSString *const QredoClientDefaultServiceURL = @"http://alpha01.qredo.me:8080/services";
static NSString *const QredoClientMQTTServiceURL = @"tcp://alpha01.qredo.me:1883";

NSString *const QredoRendezvousURIProtocol = @"qrp:";


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
    // TODO: DH - Update to display the QredoClientOptions contents, now it's no longer a dictionary
    LogDebug(@"Authorising client for conversation types: %@. VaultDataTypes: %@. Options: %@.", conversationTypes, vaultDataTypes, options);

    NSURL *serviceURL = [NSURL URLWithString:QredoClientDefaultServiceURL];

    if (options.useMQTT) {
        serviceURL = [NSURL URLWithString:QredoClientMQTTServiceURL];
    }


    __block NSError *error = nil;
    
    __block QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL];
    
    void(^completeAuthorization)() = ^() {
        
        if (error) {
            if (completionHandler) completionHandler(nil, error);
        } else {
            // This assert is very important!!!
            NSAssert(client.defaultVault, @"No QredoClient without a system vault must be passed to the client code.");
            if (completionHandler) completionHandler(client, error);
        }
        
    };
    
    
    if (options.resetData) {
        
        [client createSystemVault];
        [client saveStateWithError:&error];
        
        completeAuthorization();
        return;
        
    }
    
    
    if (![client loadStateWithError:&error]) {
        
        if ([error.domain isEqualToString:QredoErrorDomain] && error.code == QredoErrorCodeKeychainCouldNotBeFound) {
            
            // TODO [GR]: Show new device screen insted of creating the vault starit away.
            error = nil;
            [client createSystemVault];
            [client saveStateWithError:&error];
            
            completeAuthorization();
            
        } else {
            
            // TODO [GR]: Show alert for corrupted keychain instead of the placeholder below.
            // Also implement a way of recovering a keychian here.
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertController *alertController
                = [UIAlertController
                   alertControllerWithTitle:@"Keychain is corrupted"
                   message:@"The system vault keychain seems to be corrupted."
                   preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction
                                            actionWithTitle:@"Try later"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                
                                                completeAuthorization();
                                                
                                            }]];
                
                [alertController addAction:[UIAlertAction
                                            actionWithTitle:@"Remove keychain"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                                
                                                [client createSystemVault];
                                                [client saveStateWithError:&error];

                                                completeAuthorization();
                                                
                                            }]];
                
                [[UIApplication sharedApplication].keyWindow.rootViewController
                 presentViewController:alertController animated:YES completion:nil];
            });
            
        }
        
        return;
        
    }
    
    completeAuthorization();
    
}

+ (void)completeAuthorizationWithClient:(QredoClient *)client error:(NSError *)error completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler {
    
}

+ (void)openSettings {
    QredoManagerAppRootViewController *managerAppRootViewController = [[QredoManagerAppRootViewController alloc] init];
    [managerAppRootViewController show];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
{
    self = [self init];
    if (!self) return nil;

    _serviceURL = serviceURL;
    if (_serviceURL) {
        _serviceInvoker = [[QredoServiceInvoker alloc] initWithServiceURL:_serviceURL];
    }

    _rendezvousQueue = dispatch_queue_create("com.qredo.rendezvous", nil);

    return self;
}

- (BOOL)isClosed
{
    return _serviceInvoker.isTerminated;
}

- (BOOL)isAuthenticated
{
    // rev 1 doesn't have authentication
    return YES;
}

- (void)authenticateWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    completionHandler(nil);
}

- (void)closeSession
{
    LogDebug(@"Closing client session.  Will need to re-initialise/authorise client before further use.");

    // Need to terminate transport, which ends associated threads and subsriptions etc.
    [_serviceInvoker terminate];

    // TODO: DH - somehow indicate that the client has been closed and therefore cannot be used again.
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

- (NSString *)deviceName {
    NSString *name = [[UIDevice currentDevice] name];
    return (!name) ? @"iOS device" : name;
}

- (void)addDeviceToVaultWithCompletionHandler:(void(^)(NSError *error))completionHandler {
    QredoVault *systemVault = [self systemVault];

    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:QredoVaultItemTypeKeychain
                                                                                 accessLevel:0
                                                                               summaryValues:@{QredoVaultItemSummaryKeyDeviceName : [self deviceName]}];
    QredoVaultItem *deviceInfoItem = [QredoVaultItem vaultItemWithMetadata:metadata value:nil];


    [systemVault putItem:deviceInfoItem completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
        if (completionHandler) completionHandler(error);
    }];
}

- (BOOL)saveStateWithError:(NSError **)error
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self saveSystemVaultKeychain:_defaultVault.qredoKeychain withKeychainWithKeychainArchiver:keychainArchiver error:error];
}

- (BOOL)loadStateWithError:(NSError **)error
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    QredoKeychain *systemVaultKeychain = [self loadSystemVaultKeychainWithKeychainArchiver:keychainArchiver error:error];
    if (systemVaultKeychain) {
        _defaultVault = [[QredoVault alloc] initWithClient:self qredoKeychain:systemVaultKeychain];
        return YES;
    }
    
    return NO;
}

- (void)createSystemVault {
    QredoKeychain *systemVaultKeychain = [self createDefaultKeychain];
    _defaultVault = [[QredoVault alloc] initWithClient:self qredoKeychain:systemVaultKeychain];

    [self addDeviceToVaultWithCompletionHandler:nil]; // TODO createSystemVault should be async operation with a completion handler
}

- (id<QredoKeychainArchiver>)qredoKeychainArchiver
{
    return [QredoKeychainArchivers defaultQredoKeychainArchiver];
}

- (QredoKeychain *)createDefaultKeychain {
    QredoOperatorInfo *operatorInfo = [QredoOperatorInfo operatorInfoWithName:QredoKeychainOperatorName
                                                                   serviceUri:self.serviceURL.absoluteString
                                                                    accountID:QredoKeychainOperatorAccountId
                                                         currentServiceAccess:[NSSet set]
                                                            nextServiceAccess:[NSSet set]];
    
    QredoKeychain *keychain = [[QredoKeychain alloc] initWithOperatorInfo:operatorInfo];
    [keychain generateNewKeys];
    return keychain;
}

NSString *systemVaultKeychainArchiveIdentifier = @"com.qredo.system.vault.key";

- (QredoKeychain *)loadSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver error:(NSError **)error {
    return [keychainArchiver loadQredoKeychainWithIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}

- (BOOL)saveSystemVaultKeychain:(QredoKeychain *)keychain withKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver error:(NSError **)error {
    return [keychainArchiver saveQredoKeychain:keychain withIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}

- (BOOL)hasSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver error:(NSError **)error {
    return [keychainArchiver hasQredoKeychainWithIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}

- (BOOL)setKeychain:(QredoKeychain *)keychain error:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    BOOL result = [self saveSystemVaultKeychain:keychain withKeychainWithKeychainArchiver:keychainArchiver error:error];

    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:keychain.operatorInfo.serviceUri]];
    [newClient loadStateWithError:error];
    [newClient addDeviceToVaultWithCompletionHandler:nil];

    return result;
}

- (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self saveSystemVaultKeychain:nil withKeychainWithKeychainArchiver:keychainArchiver error:error];
}

- (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self hasSystemVaultKeychainWithKeychainArchiver:keychainArchiver error:error];
}


+ (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error {
    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:nil]];
    return [newClient deleteDefaultVaultKeychainWithError:error];
}

+ (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error {
    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:nil]];
    return [newClient hasDefaultVaultKeychainWithError:error];
}


@end