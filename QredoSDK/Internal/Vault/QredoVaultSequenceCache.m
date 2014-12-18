#import "QredoVaultSequenceCache.h"

@implementation QredoVaultSequenceCache {
    NSMutableDictionary *_itemSequenceIds;
    NSMutableDictionary *_itemSequenceValues;
    QredoVaultSequenceValue *_sequenceValue;

    dispatch_queue_t _dataQueue;
}

///////////////////////////////////////////////////////////////////////////////
// Constructors
///////////////////////////////////////////////////////////////////////////////

- (instancetype)init {
    self = [super init];
    _dataQueue = dispatch_queue_create("com.qredo.vault.sequencecache", 0);
    _itemSequenceIds    = [self loadItemSequenceIds];
    _itemSequenceValues = [self loadItemSequenceValues];
    _sequenceValue      = [self loadSequenceValue];
    return self;
}

+ (instancetype)instance {
    static QredoVaultSequenceCache *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

///////////////////////////////////////////////////////////////////////////////
// QredoVaultSequenceCache Interface
///////////////////////////////////////////////////////////////////////////////

- (void)clear {
    [_itemSequenceIds removeAllObjects];
    [_itemSequenceValues removeAllObjects];
}

- (QredoVaultSequenceValue *)nextSequenceValue {
    _sequenceValue = @([_sequenceValue unsignedIntValue] + 1);
    [self saveSequenceValue:_sequenceValue];
    return _sequenceValue;
}

- (void)saveSequenceValue:(NSNumber *)sequenceValue {
    dispatch_sync(_dataQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_sequenceValue forKey:@"QredoVaultSequenceValue"];
    });
}

- (QredoVaultSequenceId *)sequenceIdForItem:(QredoVaultItemId *)itemId {
    NSString *quidString = _itemSequenceIds[[itemId QUIDString]];
    if (!quidString) return nil;
    return [[QredoQUID alloc] initWithQUIDString:quidString];
}

- (QredoVaultSequenceValue *)sequenceValueForItem:(QredoVaultItemId *)itemId {
    return _itemSequenceValues[[itemId QUIDString]];
}

- (void)setItemSequence:(QredoVaultItemId *)itemId
             sequenceId:(QredoVaultSequenceId *)sequenceId
          sequenceValue:(QredoVaultSequenceValue *)sequenceValue {
    _itemSequenceIds[[itemId QUIDString]]    = [sequenceId QUIDString];
    _itemSequenceValues[[itemId QUIDString]] = sequenceValue;
    [self saveItemSequenceIds];
    [self saveItemSequenceValues];
}

///////////////////////////////////////////////////////////////////////////////
// Storage Helpers
///////////////////////////////////////////////////////////////////////////////

- (NSNumber *)loadSequenceValue {
    __block NSNumber *returnValue = nil;
    dispatch_sync(_dataQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSNumber *maybeSequenceValue = [userDefaults objectForKey:@"QredoVaultSequenceValue"];
        if (maybeSequenceValue == nil) {
            returnValue = @1;
        } else {
            returnValue = maybeSequenceValue;
        }
    });
    return returnValue;
}

- (NSMutableDictionary *)loadItemSequenceIds {
    __block NSMutableDictionary *result = nil;
    dispatch_sync(_dataQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *maybeItemSequenceIds = [userDefaults objectForKey:@"QredoVaultItemSequenceIds"];
        if (maybeItemSequenceIds == nil) {
            result = [NSMutableDictionary new];
        } else {
            result = [maybeItemSequenceIds mutableCopy];
        }
    });
    return result;
}

- (NSMutableDictionary *)loadItemSequenceValues {
    __block NSMutableDictionary *result = nil;
    dispatch_sync(_dataQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *maybeItemSequenceValues = [userDefaults objectForKey:@"QredoVaultItemSequenceValues"];
        if (maybeItemSequenceValues == nil) {
            result = [NSMutableDictionary new];
        } else {
            result = [maybeItemSequenceValues mutableCopy];
        }
    });
    return result;
}

- (void)saveItemSequenceIds {
    dispatch_sync(_dataQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_itemSequenceIds forKey:@"QredoVaultItemSequenceIds"];
    });
}

- (void)saveItemSequenceValues {
    dispatch_sync(_dataQueue, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_itemSequenceValues forKey:@"QredoVaultItemSequenceValues"];
    });
}

- (NSNumber *)sequenceValue {
    return _sequenceValue;
}

@end