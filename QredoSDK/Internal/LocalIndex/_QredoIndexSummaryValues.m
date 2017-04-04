//DO NOT EDIT. This file is machine-generated and constantly overwritten.
//Make changes to QredoIndexSummaryValues.m instead.

#import "_QredoIndexSummaryValues.h"

const struct QredoIndexSummaryValuesAttributes QredoIndexSummaryValuesAttributes = {
    .key       = @"key",
    .valueType = @"valueType",
};

const struct QredoIndexSummaryValuesRelationships QredoIndexSummaryValuesRelationships = {
    .value         = @"value",
    .vaultMetadata = @"vaultMetadata",
};

@implementation QredoIndexSummaryValuesID
@end

@implementation _QredoIndexSummaryValues

+(id)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
    NSParameterAssert(moc_);
    return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexSummaryValues" inManagedObjectContext:moc_];
}


+(NSString *)entityName {
    return @"QredoIndexSummaryValues";
}


+(NSEntityDescription *)entityInManagedObjectContext:(NSManagedObjectContext *)moc_ {
    NSParameterAssert(moc_);
    return [NSEntityDescription entityForName:@"QredoIndexSummaryValues" inManagedObjectContext:moc_];
}


-(QredoIndexSummaryValuesID *)objectID {
    return (QredoIndexSummaryValuesID *)[super objectID];
}


+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"valueTypeValue"]){
        NSSet *affectingKey = [NSSet setWithObject:@"valueType"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }
    
    return keyPaths;
}


@dynamic key;

@dynamic valueType;

-(int16_t)valueTypeValue {
    NSNumber *result = [self valueType];
    
    return [result shortValue];
}


-(void)setValueTypeValue:(int16_t)value_ {
    [self setValueType:@(value_)];
}


-(int16_t)primitiveValueTypeValue {
    NSNumber *result = [self primitiveValueType];
    
    return [result shortValue];
}


-(void)setPrimitiveValueTypeValue:(int16_t)value_ {
    [self setPrimitiveValueType:@(value_)];
}


@dynamic value;

@dynamic vaultMetadata;

@end
