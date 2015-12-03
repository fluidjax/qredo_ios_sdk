// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexSummaryValues.m instead.

#import "_QredoIndexSummaryValues.h"

const struct QredoIndexSummaryValuesAttributes QredoIndexSummaryValuesAttributes = {
	.key = @"key",
	.value = @"value",
};

const struct QredoIndexSummaryValuesRelationships QredoIndexSummaryValuesRelationships = {
	.vaultMetadata = @"vaultMetadata",
};

@implementation QredoIndexSummaryValuesID
@end

@implementation _QredoIndexSummaryValues

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexSummaryValues" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexSummaryValues";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexSummaryValues" inManagedObjectContext:moc_];
}

- (QredoIndexSummaryValuesID*)objectID {
	return (QredoIndexSummaryValuesID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic key;

@dynamic value;

@dynamic vaultMetadata;

@end

