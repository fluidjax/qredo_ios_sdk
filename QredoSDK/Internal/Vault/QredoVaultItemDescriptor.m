/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"


@implementation QredoVaultItemDescriptor

+(instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId itemId:(QredoQUID *)itemId {
    return [[QredoVaultItemDescriptor alloc] initWithSequenceId:sequenceId itemId:itemId];
}


-(instancetype)initWithSequenceId:(QredoQUID *)sequenceId itemId:(QredoQUID *)itemId {
    self = [super init];
    
    if (!self)return nil;
    
    _sequenceId = sequenceId;
    _itemId = itemId;
    
    return self;
}


-(BOOL)isEqual:(id)object {
    if (object == self)return YES;
    
    if ([object isKindOfClass:[QredoVaultItemDescriptor class]]){
        QredoVaultItemDescriptor *other = (QredoVaultItemDescriptor *)object;
        return ([self.sequenceId isEqual:other.sequenceId] || self.sequenceId == other.sequenceId) &&
        ([self.itemId isEqual:other.itemId] || self.itemId == other.itemId) &&
        (self.sequenceValue == other.sequenceValue);
    } else return [super isEqual:object];
}


-(NSUInteger)hash {
    return [_itemId hash] ^ [_sequenceId hash] ^ (NSUInteger)_sequenceValue;
}


//For private use only.
+(instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId
                                   sequenceValue:(QLFVaultSequenceValue)sequenceValue
                                          itemId:(QredoQUID *)itemId {
    return [[self alloc] initWithSequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId];
}


//For private use only.
-(instancetype)initWithSequenceId:(QredoQUID *)sequenceId
                    sequenceValue:(QLFVaultSequenceValue)sequenceValue
                           itemId:(QredoQUID *)itemId {
    self = [self initWithSequenceId:sequenceId itemId:itemId];
    
    if (!self)return nil;
    
    _sequenceValue = sequenceValue;
    
    return self;
}


-(id)copyWithZone:(NSZone *)zone {
    return self;
}


-(NSString *)description {
    NSString *desc = [NSString stringWithFormat:@"ItemId:   %@ \n"
                      "Seq#  :   %lld \n"
                      "SeqId :   %@",self.itemId,self.sequenceValue,self.sequenceId];
    
    return desc;
}


@end
