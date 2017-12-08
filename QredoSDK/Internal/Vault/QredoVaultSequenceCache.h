/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoVaultSequenceCache :NSObject

+(instancetype)instance;

-(void)clear;
-(QLFVaultSequenceValue)nextSequenceValue;
-(void)saveSequenceValue:(QLFVaultSequenceValue)sequenceValue;
-(QLFVaultSequenceId *)sequenceIdForItem:(QLFVaultItemId *)itemId;
-(QLFVaultSequenceValue)sequenceValueForItem:(QLFVaultItemId *)itemId;
-(void)setItemSequence:(QLFVaultItemId *)itemId
            sequenceId:(QLFVaultSequenceId *)sequenceId
         sequenceValue:(QLFVaultSequenceValue)sequenceValue;
@end
