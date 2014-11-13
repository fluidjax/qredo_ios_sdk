#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoVaultSequenceCache : NSObject

+ (instancetype)instance;

- (void)clear;
- (QredoVaultSequenceValue *)nextSequenceValue;
- (void)saveSequenceValue:(NSNumber *)sequenceValue;
- (QredoVaultSequenceId *)sequenceIdForItem:(QredoVaultItemId *)itemId;
- (QredoVaultSequenceValue *)sequenceValueForItem:(QredoVaultItemId *)itemId;
- (void)setItemSequence:(QredoVaultItemId *)itemId
             sequenceId:(QredoVaultSequenceId *)sequenceId
          sequenceValue:(QredoVaultSequenceValue *)sequenceValue;

@end