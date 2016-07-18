/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoVault.h"
#import "QredoClient.h"
#import "QredoVaultPrivate.h"

QredoVaultHighWatermark *const QredoVaultHighWatermarkOrigin = nil;

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



-(NSString*)description{
    return self.sequenceState.description;
}

@end
