#import "Qredo.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoRendezvousPrivate.h"
#import "QredoConversationPrivate.h"

#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"

NSString *const QredoClientOptionVaultID = @"com.qredo.vault.id";

// Private stuff
@interface QredoClient ()
{
    QredoQUID *_vaultId;

    QredoVault *_defaultVault;

    dispatch_queue_t _rendezvousQueue;
}

@end

@implementation QredoClient (Private)

- (QredoVault*)systemVault
{
    // For rev1 we have only one vault
    // Keeping this method as a placeholder and it is used in Rendezvous and Conversations
    return _defaultVault;
}

@end

@implementation QredoClient

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
{
    return [self initWithServiceURL:serviceURL options:nil];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL options:(NSDictionary*)options
{
    self = [self init];
    if (!self) return nil;

    _serviceURL = serviceURL;

    _rendezvousQueue = dispatch_queue_create("com.qredo.rendezvous", nil);

    [self loadState];
    
    id vaultId = [options objectForKey:QredoClientOptionVaultID];

    if (vaultId) {
        if ([vaultId isKindOfClass:[NSString class]]) {
            _vaultId = [[QredoQUID alloc] initWithQUIDString:vaultId];
        } else if ([vaultId isKindOfClass:[QredoQUID class]]) {
            _vaultId = vaultId;
        } else {
            [NSException raise:NSInvalidArgumentException
                        format:@"%@ should be of type NSString or QredoQUID. It is %@",
             QredoClientOptionVaultID, [[vaultId class] description]];
        }
    }

    if (!_vaultId) {
        _vaultId = [QredoQUID QUID];
        [self saveState];
    }

    _defaultVault = [[QredoVault alloc] initWithClient:self vaultId:_vaultId];

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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[_vaultId data] forKey:QredoClientOptionVaultID];
}

- (void)loadState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *vaultIdData = [defaults objectForKey:QredoClientOptionVaultID];

    if (vaultIdData) _vaultId = [[QredoQUID alloc] initWithQUIDData:vaultIdData];
}


@end