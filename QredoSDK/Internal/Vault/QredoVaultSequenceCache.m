#import "QredoVaultSequenceCache.h"
#import "QredoLogging.h"

@implementation QredoVaultSequenceCache {
    NSMutableDictionary *_itemSequenceIds;
    NSMutableDictionary *_itemSequenceValues;
    QLFVaultSequenceValue _sequenceValue;
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

- (QLFVaultSequenceValue)nextSequenceValue {
    @synchronized(self) {
        _sequenceValue = _sequenceValue + 1;
        [self saveSequenceValue:_sequenceValue];
        return _sequenceValue;
    }
}

- (void)saveSequenceValue:(QLFVaultSequenceValue)sequenceValue {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setObject:@(_sequenceValue) forKey:@"QLFVaultSequenceValue"];
}

- (QLFVaultSequenceId *)sequenceIdForItem:(QLFVaultItemId *)itemId {
    NSString *quidString = _itemSequenceIds[[itemId QUIDString]];
    if (!quidString) return nil;
    return [[QredoQUID alloc] initWithQUIDString:quidString];
}

- (QLFVaultSequenceValue)sequenceValueForItem:(QLFVaultItemId *)itemId {
    return [_itemSequenceValues[[itemId QUIDString]] longLongValue];
}

- (void)setItemSequence:(QLFVaultItemId *)itemId
             sequenceId:(QLFVaultSequenceId *)sequenceId
          sequenceValue:(QLFVaultSequenceValue)sequenceValue {
    _itemSequenceIds[[itemId QUIDString]]    = [sequenceId QUIDString];
    _itemSequenceValues[[itemId QUIDString]] = @(sequenceValue);
    [self saveItemSequenceIds];
    [self saveItemSequenceValues];
}

///////////////////////////////////////////////////////////////////////////////
// Storage Helpers
///////////////////////////////////////////////////////////////////////////////

- (QLFVaultSequenceValue)loadSequenceValue {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSNumber *maybeSequenceValue = [userDefaults objectForKey:@"QLFVaultSequenceValue"];
    if (maybeSequenceValue == nil) {
        return 1;
    } else {
        return [maybeSequenceValue longLongValue];
    }
}

- (NSMutableDictionary *)loadItemSequenceIds {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSMutableDictionary *maybeItemSequenceIds = [userDefaults objectForKey:@"QredoVaultItemSequenceIds"];
    if (maybeItemSequenceIds == nil) {
        return [NSMutableDictionary new];
    } else {
        return [maybeItemSequenceIds mutableCopy];
    }
}

- (NSMutableDictionary *)loadItemSequenceValues {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSMutableDictionary *maybeItemSequenceValues = [userDefaults objectForKey:@"QredoVaultItemSequenceValues"];
    if (maybeItemSequenceValues == nil) {
        return [NSMutableDictionary new];
    } else {
        return [maybeItemSequenceValues mutableCopy];
    }
}

- (void)saveItemSequenceIds {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setObject:_itemSequenceIds forKey:@"QredoVaultItemSequenceIds"];
}

- (void)saveItemSequenceValues {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setObject:_itemSequenceValues forKey:@"QredoVaultItemSequenceValues"];
}

- (QLFVaultSequenceValue)sequenceValue {
    return _sequenceValue;
}

@end