/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "Qredo.h"

#import "NSDictionary+IndexableSet.h"
#import "QredoVaultCrypto.h"
#import "QredoVaultSequenceCache.h"
#import "QredoCrypto.h"


NSString *const QredoVaultOptionSequenceId = @"com.qredo.vault.sequence.id.";
NSString *const QredoVaultOptionHighWatermark = @"com.qredo.vault.hwm";

static NSString *const QredoVaultItemMetadataItemDateCreated = @"_created";
static NSString *const QredoVaultItemMetadataItemDateModified = @"_modified";
static NSString *const QredoVaultItemMetadataItemVersion = @"_v";



static const double kQredoVaultUpdateInterval = 1.0; // seconds

@interface NSDictionary (QUIDSerialization)
- (NSDictionary*)quidToStringDictionary;
- (NSDictionary*)stringToQuidDictionary;
@end



@implementation NSDictionary (QUIDSerialization)

- (NSDictionary* )quidToStringDictionary {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    NSArray *keys = [self allKeys];

    for (id key in keys) {
        id newKey = key;
        if ([key isKindOfClass:[QredoQUID class]]) {
            newKey = [key QUIDString];
        }

        [result setObject:[self objectForKey:key] forKey:newKey];
    }
    return [result copy];
}

- (NSDictionary *)stringToQuidDictionary
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *keys = [self allKeys];

    for (id key in keys) {
        QredoQUID *newKey = [[QredoQUID alloc] initWithQUIDString:key];

        [result setObject:[self objectForKey:key] forKey:newKey];
    }

    return [result copy];
}

@end


// Opaque Class. Keeping interface only here
@interface QredoVaultHighWatermark()
// key: SequenceId (QredoQUID*), value: SequenceValue (NSNumber*)
// TODO WARNING NSNumber on 32-bit systems can keep maximum 32-bit integers, but we need 64. Kept NSNumber because in the LF code we use NSNumber right now
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
        QredoVaultSequenceState *state = [QredoVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId sequenceValue:[self.sequenceState objectForKey:sequenceId]];

        [sequenceStates addObject:state];
    }
    return [sequenceStates copy]; // immutable copy
}
@end


@interface QredoVaultItemDescriptor()
@property (readonly) QredoVaultSequenceValue *sequenceValue;
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

// For private use only.
+ (instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId sequenceValue:(QredoVaultSequenceValue *)sequenceValue itemId:(QredoQUID *)itemId
{
    return [[self alloc] initWithSequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId];
}

// For private use only.
- (instancetype)initWithSequenceId:(QredoQUID *)sequenceId sequenceValue:(QredoVaultSequenceValue *)sequenceValue itemId:(QredoQUID *)itemId
{
    self = [self initWithSequenceId:sequenceId itemId:itemId];
    if (!self) return nil;
    
    _sequenceValue = sequenceValue;
    
    return self;
}

@end



QredoVaultHighWatermark *const QredoVaultHighWatermarkOrigin = nil;

@interface QredoVault ()
{
    QredoClient *_client;
    QredoQUID *_vaultId;
    QredoQUID *_sequenceId;

    QredoVaultHighWatermark *_highwatermark;

    QredoInternalVault *_vault;
    QredoVaultCrypto *_vaultCrypto;
    QredoVaultSequenceCache *_vaultSequenceCache;

    dispatch_queue_t _queue;
    dispatch_source_t _timer;

    int scheduled, responded;
}

- (void)saveState;
- (void)loadState;

@end

@implementation QredoVault (Private)

- (QredoQUID *)sequenceId {
    return _sequenceId;
}

- (instancetype)initWithClient:(QredoClient *)client vaultId:(QredoQUID *)vaultId
{
    self = [super init];
    if (!self) return nil;

    _client = client;
    _vaultId = vaultId;
    _highwatermark = QredoVaultHighWatermarkOrigin;

    _queue = dispatch_queue_create("com.qredo.vault.updates", nil);

    [self loadState];

    if (!_sequenceId) {
        _sequenceId = [QredoQUID QUID];
        [self saveState];
    }

    _vault              = [QredoInternalVault vaultWithServiceURL:client.serviceURL];
    _vaultSequenceCache = [QredoVaultSequenceCache instance];

    const uint8_t bulkKeyBytes[] = {'b','u','l','k','d','e','m','o','k','e','y'};
    const uint8_t authenticationKeyBytes[] = {'a','u','t','h','d','e','m','o','k','e','y'};

    NSData *bulkKey = [NSData dataWithBytes:bulkKeyBytes
                                     length:sizeof(bulkKeyBytes)];
    NSData *authenticationKey = [NSData dataWithBytes:authenticationKeyBytes
                                               length:sizeof(authenticationKeyBytes)];

    _vaultCrypto = [QredoVaultCrypto vaultCryptoWithBulkKey:bulkKey
                                          authenticationKey:authenticationKey];

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


- (void)putOrUpdateItem:(QredoVaultItem *)vaultItem itemId:(QredoQUID*)itemId summaryValues:(NSDictionary *)summaryValues completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{

    QredoVaultSequenceValue *newSequenceValue = [_vaultSequenceCache nextSequenceValue];

    QredoVaultItemMetadata *metadata = vaultItem.metadata;

    QredoInternalVaultItemDescriptor *vaultItemDescriptor =
    [QredoInternalVaultItemDescriptor vaultItemDescriptorWithVaultId:_vaultId
                                                          sequenceId:_sequenceId
                                                       sequenceValue:newSequenceValue
                                                              itemId:itemId];

    QredoVaultItemMetaDataLF *vaultItemMetaDataLF =
    [QredoVaultItemMetaDataLF vaultItemMetaDataLFWithDataType:metadata.dataType
                                                  accessLevel:@(metadata.accessLevel)
                                                summaryValues:[summaryValues indexableSet]];

    QredoVaultItemLF *vaultItemLF = [QredoVaultItemLF vaultItemLFWithMetadata:vaultItemMetaDataLF
                                                                        value:vaultItem.value];

    QredoEncryptedVaultItem *encryptedVaultItem = [_vaultCrypto encryptVaultItemLF:vaultItemLF
                                                                        descriptor:vaultItemDescriptor];

    [_vault putItemWithItem:encryptedVaultItem
          completionHandler:^void(NSNumber *result, NSError *error) {
              if ([result boolValue] && !error) {
                  [_vaultSequenceCache setItemSequence:itemId
                                            sequenceId:_sequenceId
                                         sequenceValue:newSequenceValue];
                  completionHandler([QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:_sequenceId sequenceValue:newSequenceValue itemId:itemId], nil);
              } else {
                  completionHandler(nil, error);
              }
          }];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{
    QredoQUID *itemId = [QredoQUID QUID];
    [self strictlyPutNewItem:vaultItem itemId:itemId completionHandler:completionHandler];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem itemId:(QredoQUID *)itemId completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = [NSDate date];
    [self putOrUpdateItem:vaultItem itemId:itemId summaryValues:newSummaryValues completionHandler:completionHandler];
}

- (void)strictlyUpdateItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = [NSDate date];
    newSummaryValues[QredoVaultItemMetadataItemVersion] = metadata.descriptor.sequenceValue;
    [self putOrUpdateItem:vaultItem itemId:itemId summaryValues:newSummaryValues completionHandler:completionHandler];
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

@implementation QredoVaultItemMetadata

+ (instancetype)vaultItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)descriptor dataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel summaryValues:(NSDictionary *)summaryValues
{
    return [[QredoVaultItemMetadata alloc] initWithDescriptor:descriptor dataType:dataType accessLevel:accessLevel summaryValues:summaryValues];
}


+ (instancetype)vaultItemMetadataWithDataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel summaryValues:(NSDictionary *)summaryValues
{
    return [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:nil dataType:dataType accessLevel:accessLevel summaryValues:summaryValues];
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
@end

@implementation QredoVault

- (QredoQUID *)vaultId
{
    return _vaultId;
}

- (void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
            completionHandler:(void(^)(QredoVaultItem *vaultItem, NSError *error))completionHandler
{

    QredoVaultSequenceId   *sequenceId    = itemDescriptor.sequenceId;
    NSNumber *sequenceValue = [_vaultSequenceCache sequenceValueForItem:itemDescriptor.itemId];

    [_vault getItemWithVaultId:_vaultId
                    sequenceId:sequenceId
                 sequenceValue:[NSSet setWithObjects:sequenceValue, nil]
                        itemId:itemDescriptor.itemId
             completionHandler:^(NSSet *result, NSError *error)
    {
         if (!error && [result count]) {
             QredoEncryptedVaultItem *encryptedVaultItem = [result allObjects][0];

             QredoVaultItemLF *vaultItemLF = [_vaultCrypto decryptEncryptedVaultItem:encryptedVaultItem];

             NSDictionary *summaryValues = [vaultItemLF.metadata.summaryValues dictionaryFromIndexableSet];

             QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:vaultItemLF.metadata.dataType
                                                                                          accessLevel:[vaultItemLF.metadata.accessLevel integerValue]
                                                                                        summaryValues:summaryValues];
             QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:vaultItemLF.value];

             completionHandler(vaultItem, nil);
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
    QredoVaultSequenceId *sequenceId = itemDescriptor.sequenceId;
    NSNumber *sequenceValue = [_vaultSequenceCache sequenceValueForItem:itemDescriptor.itemId];

    [_vault getItemMetaDataWithVaultId:_vaultId
                            sequenceId:sequenceId
                         sequenceValue:(sequenceValue ? [NSSet setWithObject:sequenceValue] : nil)
                                itemId:itemDescriptor.itemId
                     completionHandler:^(NSSet *result, NSError *error) {
                         if (!error && result.count) {

                             QredoEncryptedVaultItemMetaData *encryptedVaultItemMetaData = [result allObjects][0];

                             QredoVaultItemMetaDataLF *vaultItemMetadataLF = [_vaultCrypto decryptEncryptedVaultItemMetaData:encryptedVaultItemMetaData];

                             NSDictionary *summaryValues = [vaultItemMetadataLF.summaryValues dictionaryFromIndexableSet];

                             QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:vaultItemMetadataLF.dataType
                                                                                                          accessLevel:[vaultItemMetadataLF.accessLevel integerValue]
                                                                                                        summaryValues:summaryValues];

                             completionHandler(metadata, nil);
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
    NSAssert(_delegate, @"Delegate should be set before starting listening for the updates");
    // check that delegate != nil

    @synchronized (self) {
        if (_timer) return;

        scheduled = 0;
        responded = 0;

        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
        if (_timer)
        {
            dispatch_source_set_timer(_timer,
                                      dispatch_time(DISPATCH_TIME_NOW, kQredoVaultUpdateInterval * NSEC_PER_SEC), // start
                                      kQredoVaultUpdateInterval * NSEC_PER_SEC, // interval
                                      (1ull * NSEC_PER_SEC) / 10); // how much it can defer from the interval
            dispatch_source_set_event_handler(_timer, ^{
                if (scheduled != responded) {
                    return;
                }
                scheduled++;
                [self enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
                    if ([_delegate respondsToSelector:@selector(qredoVault:didReceiveVaultItemMetadata:)]) {
                        [_delegate qredoVault:self didReceiveVaultItemMetadata:vaultItemMetadata];
                    }
                } completionHandler:^(NSError *error) {
                    // we might stop the timer based on certain errors, but if it is a temporary connection error, then we just skip it

                    responded++;
                    if (error && [_delegate respondsToSelector:@selector(qredoVault:didFailWithError:)]) {
                        [_delegate qredoVault:self didFailWithError:error];
                    }

                } watermarkHandler:^(QredoVaultHighWatermark *watermark) {
                    self->_highwatermark = watermark;
                    [self saveState];
                } since:self.highWatermark];

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

- (void)resetWatermark
{
    _highwatermark = nil;
    [self saveState];
}

- (void)putItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
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
        [self enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:nil since:sinceWatermark];
    });
}

// this is private method that also returns highWatermark. Used in the polling data
- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                    completionHandler:(void(^)(NSError *error))completionHandler
                     watermarkHandler:(void(^)(QredoVaultHighWatermark*))watermarkHandler
                                since:(QredoVaultHighWatermark*)sinceWatermark
{
    NSAssert(block, @"block should not be nil");
    __block NSMutableSet *sequenceStates = [[sinceWatermark vaultSequenceState] mutableCopy];

    if (!sequenceStates) sequenceStates = [NSMutableSet set];
    NSLog(@"Watermark: %@", sinceWatermark.sequenceState);

    @try {
        // Sync sequence IDs...
        [_vault queryItemMetaDataWithVaultId:_vaultId
                              sequenceStates:sequenceStates
                           completionHandler:^void(QredoVaultItemMetaDataResults *vaultItemMetaDataResults, NSError *error)
        {
           if (error) {
               if (completionHandler) completionHandler(error);
               return;
           }

           NSSet *sequenceIds = [vaultItemMetaDataResults sequenceIds];

            NSMutableDictionary *newWatermarkDictionary = [sinceWatermark.sequenceState mutableCopy];
            if (!newWatermarkDictionary) newWatermarkDictionary = [NSMutableDictionary dictionary];

            // Get the unique item IDs, update our mappings.
            NSArray *results = [vaultItemMetaDataResults results];
            for (QredoEncryptedVaultItemMetaData *result in results) {

                QredoVaultItemMetaDataLF* decryptedItem = [_vaultCrypto decryptEncryptedVaultItemMetaData:result];

                QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:result.sequenceId sequenceValue:result.sequenceValue itemId:result.itemId];

                QredoVaultItemMetadata* externalItem = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                                      dataType:decryptedItem.dataType
                                                                                                   accessLevel:[decryptedItem.accessLevel integerValue]
                                                                                                 summaryValues:[decryptedItem.summaryValues dictionaryFromIndexableSet]];

                [newWatermarkDictionary setObject:result.sequenceValue forKey:result.sequenceId];

                __block BOOL stop = [results lastObject] == result;
                block(externalItem, &stop);
                if (stop) break;
            }

            BOOL discoveredNewSequence = NO;
            // We want items for all sequences...
            for (QredoVaultSequenceId *sequenceId in sequenceIds) {
               if ([newWatermarkDictionary objectForKey:sequenceId] != nil) continue;

               QredoVaultSequenceState *sequenceState =
               [QredoVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId
                                                           sequenceValue:@0];
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
                    [self enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:watermarkHandler since:newWatermark];
                });
            } else {
                completionHandler(nil);
            }
       }];

    }
    @catch (NSException *exception) {
        completionHandler([NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultUnknown userInfo:@{NSLocalizedDescriptionKey: exception.description}]);
    }
}

- (QredoVaultHighWatermark *)highWatermark
{
    return _highwatermark;
}

- (void)saveState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[_sequenceId data] forKey:[QredoVaultOptionSequenceId stringByAppendingString:[_vaultId QUIDString]]];
    if (_highwatermark) {
        [defaults setObject:[_highwatermark.sequenceState quidToStringDictionary] forKey:QredoVaultOptionHighWatermark];
    } else {
        [defaults removeObjectForKey:QredoVaultOptionHighWatermark];
    }
}

- (void)loadState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *sequenceIdData = [defaults objectForKey:[QredoVaultOptionSequenceId stringByAppendingString:[_vaultId QUIDString]]];

    if (sequenceIdData) _sequenceId = [[QredoQUID alloc] initWithQUIDData:sequenceIdData];

    NSDictionary* sequenceState = [defaults objectForKey:QredoVaultOptionHighWatermark];
    if (sequenceState) {
        _highwatermark = [QredoVaultHighWatermark watermarkWithSequenceState:[sequenceState stringToQuidDictionary]];
    } else {
        _highwatermark = nil;
    }
}

@end