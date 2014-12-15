#import "QredoVaultSequenceCache.h"
#import "QredoLogging.h"

@implementation QredoVaultSequenceCache {
    NSMutableDictionary *_itemSequenceIds;
    NSMutableDictionary *_itemSequenceValues;
    QredoVaultSequenceValue *_sequenceValue;
}

///////////////////////////////////////////////////////////////////////////////
// Constructors
///////////////////////////////////////////////////////////////////////////////

- (instancetype)init {
    self = [super init];
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
    LogDebug(@"%s: Getting standardUserDefaults from NSUserDefaults", __PRETTY_FUNCTION__);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    LogDebug(@"%s: Setting QredoVaultSequenceValue in NSUserDefaults", __PRETTY_FUNCTION__);
    [userDefaults setObject:_sequenceValue forKey:@"QredoVaultSequenceValue"];
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
    LogDebug(@"%s: Getting standardUserDefaults from NSUserDefaults", __PRETTY_FUNCTION__);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    LogDebug(@"%s: Getting QredoVaultSequenceValue in NSUserDefaults", __PRETTY_FUNCTION__);
    NSNumber *maybeSequenceValue = [userDefaults objectForKey:@"QredoVaultSequenceValue"];
    if (maybeSequenceValue == nil) {
        LogDebug(@"%s: No object found for QredoVaultSequenceValue in NSUserDefaults", __PRETTY_FUNCTION__);
        return @1;
    } else {
        LogDebug(@"%s: Found object for QredoVaultSequenceValue in NSUserDefaults", __PRETTY_FUNCTION__);
        return maybeSequenceValue;
    }
}

- (NSMutableDictionary *)loadItemSequenceIds {
    LogDebug(@"%s: Getting standardUserDefaults from NSUserDefaults", __PRETTY_FUNCTION__);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    LogDebug(@"%s: Getting QredoVaultItemSequenceIds in NSUserDefaults", __PRETTY_FUNCTION__);
    NSMutableDictionary *maybeItemSequenceIds = [userDefaults objectForKey:@"QredoVaultItemSequenceIds"];
    if (maybeItemSequenceIds == nil) {
        LogDebug(@"%s: No object found for QredoVaultItemSequenceIds in NSUserDefaults", __PRETTY_FUNCTION__);
        return [NSMutableDictionary new];
    } else {
        LogDebug(@"%s: Found object for QredoVaultItemSequenceIds in NSUserDefaults", __PRETTY_FUNCTION__);
        return [maybeItemSequenceIds mutableCopy];
    }
}

- (NSMutableDictionary *)loadItemSequenceValues {
    LogDebug(@"%s: Getting standardUserDefaults from NSUserDefaults", __PRETTY_FUNCTION__);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    LogDebug(@"%s: Getting QredoVaultItemSequenceValues in NSUserDefaults", __PRETTY_FUNCTION__);
    NSMutableDictionary *maybeItemSequenceValues = [userDefaults objectForKey:@"QredoVaultItemSequenceValues"];
    if (maybeItemSequenceValues == nil) {
        LogDebug(@"%s: No object found for QredoVaultItemSequenceValues in NSUserDefaults", __PRETTY_FUNCTION__);
        return [NSMutableDictionary new];
    } else {
        LogDebug(@"%s: Found object for QredoVaultItemSequenceValues in NSUserDefaults", __PRETTY_FUNCTION__);
        return [maybeItemSequenceValues mutableCopy];
    }
}

- (void)saveItemSequenceIds {
    LogDebug(@"%s: Getting standardUserDefaults from NSUserDefaults", __PRETTY_FUNCTION__);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    LogDebug(@"%s: Setting QredoVaultItemSequenceIds in NSUserDefaults", __PRETTY_FUNCTION__);
    [userDefaults setObject:_itemSequenceIds forKey:@"QredoVaultItemSequenceIds"];
}

- (void)saveItemSequenceValues {
    LogDebug(@"%s: Getting standardUserDefaults from NSUserDefaults in NSUserDefaults", __PRETTY_FUNCTION__);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    LogDebug(@"%s: Setting QredoVaultItemSequenceValues in NSUserDefaults in NSUserDefaults", __PRETTY_FUNCTION__);
    [userDefaults setObject:_itemSequenceValues forKey:@"QredoVaultItemSequenceValues"];
}

- (NSNumber *)sequenceValue {
    return _sequenceValue;
}

@end