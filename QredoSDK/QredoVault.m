/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "Qredo.h"
#import "QredoPrivate.h"

#import "NSDictionary+QUIDSerialization.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoVaultCrypto.h"
#import "QredoVaultSequenceCache.h"
#import "QredoCrypto.h"
#import "QredoLogging.h"
#import "QredoKeychain.h"

#import "QredoUpdateListener.h"

#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"


NSString *const QredoVaultOptionSequenceId = @"com.qredo.vault.sequence.id.";
NSString *const QredoVaultOptionHighWatermark = @"com.qredo.vault.hwm";

static NSString *const QredoVaultItemMetadataItemDateCreated = @"_created";
static NSString *const QredoVaultItemMetadataItemDateModified = @"_modified";
static NSString *const QredoVaultItemMetadataItemVersion = @"_v";

static NSString *const QredoVaultItemMetadataItemTypeTombstone = @"\u220E"; // U+220E END OF PROOF, https://github.com/Qredo/design-docs/wiki/Vault-Item-Tombstone
static NSString *const QredoVaultItemMetadataItemTypeRendezvous = @"com.qredo.rendezvous";
static NSString *const QredoVaultItemMetadataItemTypeConversation = @"com.qredo.conversation";

static const double kQredoVaultUpdateInterval = 1.0; // seconds
QredoVaultHighWatermark *const QredoVaultHighWatermarkOrigin = nil;

// Opaque Class. Keeping interface only here
@interface QredoVaultHighWatermark()
// key: SequenceId (QredoQUID*), value: SequenceValue (NSNumber*)
// TODO: WARNING NSNumber on 32-bit systems can keep maximum 32-bit integers, but we need 64. Kept NSNumber because in the LF code we use NSNumber right now
@property NSMutableDictionary *sequenceState;
- (NSSet*)vaultSequenceState;
+ (instancetype)watermarkWithSequenceState:(NSDictionary *)sequenceState;
@end

@implementation QredoVaultHighWatermark

+ (instancetype)watermarkWithSequenceState:(NSDictionary *)sequenceState
{
    QredoVaultHighWatermark *watermark = [[QredoVaultHighWatermark alloc] init];
    watermark.sequenceState = [sequenceState mutableCopy];
    return watermark;
}

- (NSSet*)vaultSequenceState
{
    NSMutableSet *sequenceStates = [NSMutableSet set];

    NSArray *sortedKeys = [[self.sequenceState allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (QredoQUID* sequenceId in sortedKeys) {
        QLFVaultSequenceState *state = [QLFVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId
                                                                                 sequenceValue:[[self.sequenceState objectForKey:sequenceId] longLongValue]];

        [sequenceStates addObject:state];
    }
    return [sequenceStates copy]; // immutable copy
}
@end

@implementation QredoVaultItemDescriptor

+ (instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId itemId:(QredoQUID *)itemId
{
    return [[QredoVaultItemDescriptor alloc] initWithSequenceId:sequenceId itemId:itemId];
}

- (instancetype)initWithSequenceId:(QredoQUID *)sequenceId itemId:(QredoQUID *)itemId
{
    self = [super init];
    if (!self) return nil;

    _sequenceId = sequenceId;
    _itemId = itemId;

    return self;
}

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;

    if ([object isKindOfClass:[QredoVaultItemDescriptor class]]) {
        QredoVaultItemDescriptor *other = (QredoVaultItemDescriptor*)object;
        return ([self.sequenceId isEqual:other.sequenceId] || self.sequenceId == other.sequenceId) &&
            ([self.itemId isEqual:other.itemId] || self.itemId == other.itemId) &&
            (self.sequenceValue == other.sequenceValue);
    } else return [super isEqual:object];
}

- (NSUInteger)hash
{
    return [_itemId hash] ^ [_sequenceId hash] ^ _sequenceValue;
}

// For private use only.
+ (instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QredoQUID *)itemId
{
    return [[self alloc] initWithSequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId];
}

// For private use only.
- (instancetype)initWithSequenceId:(QredoQUID *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QredoQUID *)itemId
{
    self = [self initWithSequenceId:sequenceId itemId:itemId];
    if (!self) return nil;
    
    _sequenceValue = sequenceValue;
    
    return self;
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end

@interface QredoVault () <QredoUpdateListenerDataSource, QredoUpdateListenerDelegate>
{
    QredoClient *_client;
    QredoKeychain *_qredoKeychan;
    QredoQUID *_vaultId;
    QredoQUID *_sequenceId;

    QredoVaultHighWatermark *_highwatermark;

    QLFVault *_vault;
    QredoVaultCrypto *_vaultCrypto;
    QredoVaultSequenceCache *_vaultSequenceCache;

    QredoED25519SigningKey *_signingKey;

    dispatch_queue_t _queue;

    QredoUpdateListener *_updateListener;
}

- (void)saveState;
- (void)loadState;

@end

@implementation QredoVault (Private)

- (QredoQUID *)sequenceId {
    return _sequenceId;
}

- (QredoKeychain *)qredoKeychain {
    return _qredoKeychan;
}

- (instancetype)initWithClient:(QredoClient *)client qredoKeychain:(QredoKeychain *)qredoKeychan
{
    if (!qredoKeychan) return nil;

    return [self initWithClient:client qredoKeychain:qredoKeychan vaultId:qredoKeychan.vaultId];

}

- (instancetype)initWithClient:(QredoClient *)client qredoKeychain:(QredoKeychain *)qredoKeychan vaultId:(QredoQUID*)vaultId
{
    if (!client || !vaultId) return nil;
    self = [super init];
    if (!self) return nil;

    _client = client;
    _qredoKeychan = qredoKeychan;
    _vaultId = vaultId;
    _highwatermark = QredoVaultHighWatermarkOrigin;

    _signingKey = qredoKeychan.vaultSigningKey;

    _queue = dispatch_queue_create("com.qredo.vault.updates", nil);

    [self loadState];

    if (!_sequenceId) {
        _sequenceId = [QredoQUID QUID];
        [self saveState];
    }

    _updateListener = [[QredoUpdateListener alloc] init];
    _updateListener.delegate = self;
    _updateListener.dataSource = self;
    _updateListener.pollInterval = kQredoVaultUpdateInterval;

    _vault = [QLFVault vaultWithServiceInvoker:_client.serviceInvoker];
    _vaultSequenceCache = [QredoVaultSequenceCache instance];
    
    QLFVaultKeyPair *keyPair = [qredoKeychan vaultKeys];

    _vaultCrypto = [QredoVaultCrypto vaultCryptoWithBulkKey:keyPair.encryptionKey
                                          authenticationKey:keyPair.authenticationKey];
    
    return self;
}

- (QredoQUID *)itemIdWithName:(NSString *)name type:(NSString *)type
{
    NSString *constructedName = [NSString stringWithFormat:@"%@.%@@%@", [self.vaultId QUIDString], name, type];
    NSData *hash = [QredoCrypto sha256:[constructedName dataUsingEncoding:NSUTF8StringEncoding]];
    return [[QredoQUID alloc] initWithQUIDData:hash];
}

- (QredoQUID *)itemIdWithQUID:(QredoQUID *)quid type:(NSString *)type
{
    return [self itemIdWithName:[quid QUIDString] type:type];
}


- (void)putUpdateOrDeleteItem:(QredoVaultItem *)vaultItem
                       itemId:(QredoQUID*)itemId dataType:(NSString *)dataType
                summaryValues:(NSDictionary *)summaryValues
            completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{

    QLFVaultSequenceValue newSequenceValue = [_vaultSequenceCache nextSequenceValue];

    QredoVaultItemMetadata *metadata = vaultItem.metadata;

    QLFVaultItemDescriptorLF *vaultItemDescriptor =
    [QLFVaultItemDescriptorLF vaultItemDescriptorLFWithVaultId:_vaultId
                                                    sequenceId:_sequenceId
                                                 sequenceValue:newSequenceValue
                                                        itemId:itemId];

    QLFVaultItemMetaDataLF *vaultItemMetaDataLF =
    [QLFVaultItemMetaDataLF vaultItemMetaDataLFWithDataType:dataType
                                                accessLevel:metadata.accessLevel
                                              summaryValues:[summaryValues indexableSet]];

    QLFVaultItemLF *vaultItemLF = [QLFVaultItemLF vaultItemLFWithMetadata:vaultItemMetaDataLF
                                                                    value:vaultItem.value];

    QLFEncryptedVaultItem *encryptedVaultItem = [_vaultCrypto encryptVaultItemLF:vaultItemLF
                                                                      descriptor:vaultItemDescriptor];


    NSError *error = nil;

    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithKey:_signingKey
                                         operationType:[QLFOperationType operationCreate]
                                                  data:encryptedVaultItem
                                                 error:&error];

    if (error) {
        completionHandler(nil, error);
        return;
    }
    
    [_vault putItemWithItem:encryptedVaultItem
                  signature:ownershipSignature
          completionHandler:^void(BOOL result, NSError *error)
     {
         if (result && !error) {
             [_vaultSequenceCache setItemSequence:itemId
                                       sequenceId:_sequenceId
                                    sequenceValue:newSequenceValue];
             
             
             QredoMutableVaultItemMetadata *newMetadata = [metadata mutableCopy];
             newMetadata.descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:_sequenceId
                                                                                    sequenceValue:newSequenceValue
                                                                                           itemId:itemId];
             
             completionHandler(newMetadata, nil);
             
         } else {
             
             completionHandler(nil, error);
             
         }
     }];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    QredoQUID *itemId = [QredoQUID QUID];
    [self strictlyPutNewItem:vaultItem itemId:itemId completionHandler:completionHandler];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem
                    itemId:(QredoQUID *)itemId
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = [NSDate date];
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                  summaryValues:newSummaryValues
              completionHandler:completionHandler];
}

- (void)strictlyUpdateItem:(QredoVaultItem *)vaultItem
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = [NSDate date];
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue);
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                  summaryValues:newSummaryValues
              completionHandler:completionHandler];
}


@end

@implementation QredoVaultItem
+ (instancetype)vaultItemWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value
{
    return [[QredoVaultItem alloc] initWithMetadata:metadata value:value];
}

- (instancetype)initWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value
{
    self = [super init];
    if (!self) return nil;
    _metadata = metadata;
    _value = value;

    return self;
}
@end

@interface QredoVaultItemMetadata ()
@property QredoVaultItemDescriptor *descriptor;
@property (copy) NSString *dataType;
@property QredoAccessLevel accessLevel;
@property (copy) NSDictionary *summaryValues; // string -> string | NSNumber | QredoQUID
@end

@implementation QredoVaultItemMetadata

+ (instancetype)vaultItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)descriptor dataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel summaryValues:(NSDictionary *)summaryValues
{
    return [[self alloc] initWithDescriptor:descriptor dataType:dataType accessLevel:accessLevel summaryValues:summaryValues];
}


+ (instancetype)vaultItemMetadataWithDataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel summaryValues:(NSDictionary *)summaryValues
{
    return [self vaultItemMetadataWithDescriptor:nil dataType:dataType accessLevel:accessLevel summaryValues:summaryValues];
}

- (instancetype)initWithDescriptor:(QredoVaultItemDescriptor *)descriptor dataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel summaryValues:(NSDictionary *)summaryValues
{
    self = [super init];
    if (!self) return nil;

    _descriptor = descriptor;
    _dataType = dataType;
    _accessLevel = accessLevel;
    _summaryValues = summaryValues;

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[QredoVaultItemMetadata allocWithZone:zone] initWithDescriptor:self.descriptor
                                                                  dataType:self.dataType
                                                               accessLevel:self.accessLevel
                                                             summaryValues:self.summaryValues];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[QredoMutableVaultItemMetadata allocWithZone:zone] initWithDescriptor:self.descriptor
                                                                         dataType:self.dataType
                                                                      accessLevel:self.accessLevel
                                                                    summaryValues:self.summaryValues];
}

@end


@implementation QredoMutableVaultItemMetadata

@dynamic descriptor, dataType, accessLevel, summaryValues;

- (void)setSummaryValue:(id)value forKey:(NSString *)key
{
    NSMutableDictionary *mutableSummaryValues = [self.summaryValues mutableCopy];
    if (!mutableSummaryValues) {
        if (value) {
            self.summaryValues = [NSDictionary dictionaryWithObject:value forKey:key];
        }
    }
    else {
        [mutableSummaryValues setObject:value forKey:key];
        self.summaryValues = mutableSummaryValues;
    }
}

@end

@implementation QredoVault

- (QredoQUID *)vaultId
{
    return _vaultId;
}

- (void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
            completionHandler:(void(^)(QredoVaultItem *vaultItem, NSError *error))completionHandler
{

    QLFVaultSequenceId   *sequenceId    = itemDescriptor.sequenceId;
    QLFVaultSequenceValue sequenceValue = [_vaultSequenceCache sequenceValueForItem:itemDescriptor.itemId];

    NSError *error = nil;

    QLFVaultSequenceState *sequenceState = [QLFVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId sequenceValue:sequenceValue];

    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithKey:_signingKey
                                         operationType:[QLFOperationType operationGet]
                                                  data:sequenceState
                                                 error:&error];

    if (error) {
        completionHandler(nil, error);
        return;
    }

    [_vault getItemWithVaultId:_vaultId
                    sequenceId:sequenceId
                 sequenceValue:[NSSet setWithObjects:@(sequenceValue), nil]
                        itemId:itemDescriptor.itemId
                     signature:ownershipSignature
             completionHandler:^(NSSet *result, NSError *error)
    {
         if (!error && [result count]) {
             QLFEncryptedVaultItem *encryptedVaultItem = [result allObjects][0];

             QLFVaultItemLF *vaultItemLF = [_vaultCrypto decryptEncryptedVaultItem:encryptedVaultItem];

             NSDictionary *summaryValues = [vaultItemLF.metadata.summaryValues dictionaryFromIndexableSet];

             QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:encryptedVaultItem.meta.sequenceId
                                                                                                  sequenceValue:encryptedVaultItem.meta.sequenceValue
                                                                                                         itemId:encryptedVaultItem.meta.itemId];

             QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                               dataType:vaultItemLF.metadata.dataType
                                                                                            accessLevel:vaultItemLF.metadata.accessLevel
                                                                                          summaryValues:summaryValues];
             
             if ([metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]) {
                 error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemHasBeenDeleted userInfo:nil];
                 completionHandler(nil, error);
             }
             else {
                 QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:vaultItemLF.value];
                 completionHandler(vaultItem, nil);
             }

         } else {
             if (!error) {
                 error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemNotFound userInfo:nil];
             }
             completionHandler(nil, error);
         }
    }];
}

- (void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                    completionHandler:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler
{
    QLFVaultSequenceId *sequenceId = itemDescriptor.sequenceId;
    QLFVaultSequenceValue sequenceValue = [_vaultSequenceCache sequenceValueForItem:itemDescriptor.itemId];

    NSError *error = nil;

    QLFVaultSequenceState *sequenceState = [QLFVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId sequenceValue:sequenceValue];

    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithKey:_signingKey
                                         operationType:[QLFOperationType operationGet]
                                                  data:sequenceState
                                                 error:&error];

    if (error) {
        completionHandler(nil, error);
        return;
    }


    [_vault getItemMetaDataWithVaultId:_vaultId
                            sequenceId:sequenceId
                         sequenceValue:(sequenceValue ? [NSSet setWithObject:@(sequenceValue)] : nil)
                                itemId:itemDescriptor.itemId
                             signature:ownershipSignature
                     completionHandler:^(NSSet *result, NSError *error)
     {
         if (!error && result.count) {

             QLFEncryptedVaultItemMetaData *encryptedVaultItemMetaData = [result allObjects][0];

             QLFVaultItemMetaDataLF *vaultItemMetadataLF = [_vaultCrypto decryptEncryptedVaultItemMetaData:encryptedVaultItemMetaData];

             NSDictionary *summaryValues = [vaultItemMetadataLF.summaryValues dictionaryFromIndexableSet];

             QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:encryptedVaultItemMetaData.sequenceId
                                                                                                  sequenceValue:encryptedVaultItemMetaData.sequenceValue
                                                                                                         itemId:encryptedVaultItemMetaData.itemId];

             QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                               dataType:vaultItemMetadataLF.dataType
                                                                                            accessLevel:vaultItemMetadataLF.accessLevel
                                                                                          summaryValues:summaryValues];
             if ([metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]) {
                 error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemHasBeenDeleted userInfo:nil];
                 completionHandler(nil, error);
             }
             else {
                 completionHandler(metadata, nil);
             }

         } else {
             if (!error) {
                 error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeVaultItemNotFound
                                         userInfo:@{NSLocalizedDescriptionKey: @"Vault item not found"}];
             }
             completionHandler(nil, error);
         }

     }];
}

- (void)startListening
{
    [_updateListener startListening];
}

- (void)stopListening
{
    [_updateListener stopListening];
}

- (void)resetWatermark
{
    _highwatermark = nil;
    [self saveState];
}

- (void)putItem:(QredoVaultItem *)vaultItem
completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    BOOL isNewItemFromDateCreated = vaultItem.metadata.summaryValues[QredoVaultItemMetadataItemDateCreated] == nil;
    BOOL isNewItemFromDescriptor = vaultItem.metadata.descriptor == nil;
    
    NSAssert(isNewItemFromDateCreated == isNewItemFromDescriptor, @"Can not determine whether the item is newely created or not.");
    
    if (isNewItemFromDateCreated) {
        [self strictlyPutNewItem:vaultItem completionHandler:completionHandler];
    }
    else {
        [self strictlyUpdateItem:vaultItem completionHandler:completionHandler];
    }
}

- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                       completionHandler:(void(^)(NSError *error))completionHandler
{
    [self enumerateVaultItemsUsingBlock:block since:QredoVaultHighWatermarkOrigin completionHandler:completionHandler];
}

- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                                since:(QredoVaultHighWatermark*)sinceWatermark
                    completionHandler:(void(^)(NSError *error))completionHandler
{
    dispatch_async(_queue, ^{
        [self enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:nil since:sinceWatermark consolidatingResults:YES];
    });
}

// this is private method that also returns highWatermark. Used in the polling data
- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                    completionHandler:(void(^)(NSError *error))completionHandler
                     watermarkHandler:(void(^)(QredoVaultHighWatermark*))watermarkHandler
                                since:(QredoVaultHighWatermark*)sinceWatermark
                  consolidatingResults:(BOOL)shouldConsolidateResults
{
    NSAssert(block, @"block should not be nil");
    __block NSMutableSet *sequenceStates = [[sinceWatermark vaultSequenceState] mutableCopy];

    if (!sequenceStates) {
        sequenceStates = [NSMutableSet set];
    }
    LogDebug(@"Watermark: %@", sinceWatermark.sequenceState);


    NSError *error = nil;

    QredoMarshaller dataMarshaller = [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFVaultSequenceState marshaller]];
    NSData *payloadData = [QredoPrimitiveMarshallers marshalObject:sequenceStates marshaller:dataMarshaller includeHeader:NO];

    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithKey:_signingKey
                                         operationType:[QLFOperationType operationList]
                                        marshalledData:payloadData
                                                 error:&error];

    if (error) {
        completionHandler(error);
        return;
    }

    // Sync sequence IDs...
    [_vault queryItemMetaDataWithVaultId:_vaultId
                          sequenceStates:sequenceStates
                               signature:ownershipSignature
                       completionHandler:^void(QLFVaultItemMetaDataResults *vaultItemMetaDataResults, NSError *error)
    {
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
            return;
        }

        NSSet *sequenceIds = [vaultItemMetaDataResults sequenceIds];

        NSMutableDictionary *newWatermarkDictionary = [sinceWatermark.sequenceState mutableCopy];
        if (!newWatermarkDictionary) {
            newWatermarkDictionary = [NSMutableDictionary dictionary];
        }
        
        
        typedef void(^EnumerateResultsWithHandler)(QredoVaultItemMetadata* vaultItemMetadata, BOOL *stop);
        NSArray *results = [vaultItemMetaDataResults results];
        void(^enumerateResultsWithHandler)(EnumerateResultsWithHandler) = ^(EnumerateResultsWithHandler handler) {
            
            BOOL stop = FALSE;
            for (QLFEncryptedVaultItemMetaData *result in results) {
                @try {
                    QLFVaultItemMetaDataLF* decryptedItem = [_vaultCrypto decryptEncryptedVaultItemMetaData:result];
                    
                    QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:result.sequenceId
                                                                                                         sequenceValue:result.sequenceValue
                                                                                                                itemId:result.itemId];
                    
                    QredoVaultItemMetadata* externalItem = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                                          dataType:decryptedItem.dataType
                                                                                                       accessLevel:decryptedItem.accessLevel
                                                                                                     summaryValues:[decryptedItem.summaryValues dictionaryFromIndexableSet]];
                    
                    if (handler) {
                        handler(externalItem, &stop);
                    }
                    
                    [newWatermarkDictionary setObject:@(externalItem.descriptor.sequenceValue) // TODO: not working for int64
                                               forKey:externalItem.descriptor.sequenceId];
                    
                    if (stop) {
                        break;
                    }
                } @catch (NSException *exception) {
                    NSLog(@"Failed to decrypt a vault item: %@", exception);
                }
            }

        };
        
        
        // Get the unique item IDs, update our mappings.
        if (shouldConsolidateResults) {
            
            NSMutableDictionary *latestMetadata = [NSMutableDictionary dictionary];
            enumerateResultsWithHandler(^(QredoVaultItemMetadata* vaultItemMetadata, BOOL *stop) {
                
                QredoVaultItemDescriptor *key = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vaultItemMetadata.descriptor.sequenceId itemId:vaultItemMetadata.descriptor.itemId];
                QredoVaultItemMetadata* existingMetadata = latestMetadata[key];
                if (!existingMetadata ||
                    existingMetadata.descriptor.sequenceValue > vaultItemMetadata.descriptor.sequenceValue) {
                    latestMetadata[key] = vaultItemMetadata;
                }
                

            });
            
            for (QredoVaultItemMetadata* metadata in [latestMetadata allValues]) {
                BOOL stop = NO;
                if (![metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]) {
                    block(metadata, &stop);
                    if (stop) {
                        break;
                    }
                }
            }
            
        }
        else {
            
            enumerateResultsWithHandler(^(QredoVaultItemMetadata* vaultItemMetadata, BOOL *stop) {
                block(vaultItemMetadata, stop);
            });
            
        }
        

        BOOL discoveredNewSequence = NO;
        // We want items for all sequences...
        for (QLFVaultSequenceId *sequenceId in sequenceIds) {
            if ([newWatermarkDictionary objectForKey:sequenceId] != nil) {
                continue;
            }
            
            QLFVaultSequenceState *sequenceState =
            [QLFVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId
                                                        sequenceValue:0];
            [sequenceStates addObject:sequenceState];

            [newWatermarkDictionary setObject:@0 forKey:sequenceId];
            discoveredNewSequence = YES;
        }

        QredoVaultHighWatermark *newWatermark = [QredoVaultHighWatermark watermarkWithSequenceState:newWatermarkDictionary];

        if (watermarkHandler) {
            watermarkHandler(newWatermark);
        }

        if (discoveredNewSequence) {
            dispatch_async(_queue, ^{
                [self enumerateVaultItemsUsingBlock:block
                                  completionHandler:completionHandler
                                   watermarkHandler:watermarkHandler
                                              since:newWatermark
                               consolidatingResults:shouldConsolidateResults];
            });
        } else {
            completionHandler(nil);
        }
   }];
}

- (void)deleteItem:(QredoVaultItemMetadata *)metadata completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{
    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionary];
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = metadata.summaryValues[QredoVaultItemMetadataItemDateCreated];
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = [NSDate date];
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue); // TODO: not working for int64
    [self putUpdateOrDeleteItem:[QredoVaultItem vaultItemWithMetadata:metadata value:[NSData data]]
                         itemId:itemId
                       dataType:QredoVaultItemMetadataItemTypeTombstone
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         completionHandler(newItemMetadata.descriptor, error);
     }];
}


- (QredoVaultHighWatermark *)highWatermark
{
    return _highwatermark;
}

- (void)saveState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[_sequenceId data] forKey:[QredoVaultOptionSequenceId stringByAppendingString:[_vaultId QUIDString]]];

    NSString *hwmKey = [QredoVaultOptionHighWatermark stringByAppendingString:[_vaultId QUIDString]];
    if (_highwatermark) {
        [defaults setObject:[_highwatermark.sequenceState quidToStringDictionary] forKey:hwmKey];
    } else {
        [defaults removeObjectForKey:hwmKey];
    }
}

- (void)loadState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSData *sequenceIdData = [defaults objectForKey:[QredoVaultOptionSequenceId stringByAppendingString:[_vaultId QUIDString]]];

    if (sequenceIdData) {
        _sequenceId = [[QredoQUID alloc] initWithQUIDData:sequenceIdData];
    }

    NSString *hwmKey = [QredoVaultOptionHighWatermark stringByAppendingString:[_vaultId QUIDString]];
    NSDictionary* sequenceState = [defaults objectForKey:hwmKey];
    if (sequenceState) {
        _highwatermark = [QredoVaultHighWatermark watermarkWithSequenceState:[sequenceState stringToQuidDictionary]];
    } else {
        _highwatermark = nil;
    }
}

#pragma mark -
#pragma mark Qredo Update Listener - Data Source

- (BOOL)qredoUpdateListenerDoesSupportMultiResponseQuery:(QredoUpdateListener *)updateListener
{
    return NO;
}

#pragma mark Qredo Update Listener - Delegate

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener pollWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    [self enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        [_updateListener processSingleItem:vaultItemMetadata sequenceValue:@(vaultItemMetadata.descriptor.sequenceValue)];
    } completionHandler:completionHandler
                       watermarkHandler:^(QredoVaultHighWatermark *watermark)
    {
        self->_highwatermark = watermark;
        [self saveState];
    } since:self.highWatermark consolidatingResults:NO];
}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item
{
    QredoVaultItemMetadata *vaultItemMetadata = (QredoVaultItemMetadata *)item;

    if ([_delegate respondsToSelector:@selector(qredoVault:didReceiveVaultItemMetadata:)]) {
        [_delegate qredoVault:self didReceiveVaultItemMetadata:vaultItemMetadata];
    }
}

@end
