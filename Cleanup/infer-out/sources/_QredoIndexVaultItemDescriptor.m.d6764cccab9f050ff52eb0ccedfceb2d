// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemDescriptor.m instead.

#import "_QredoIndexVaultItemDescriptor.h"

const struct QredoIndexVaultItemDescriptorAttributes QredoIndexVaultItemDescriptorAttributes = {
	.itemId = @"itemId",
	.sequenceId = @"sequenceId",
	.sequenceValue = @"sequenceValue",
};

const struct QredoIndexVaultItemDescriptorRelationships QredoIndexVaultItemDescriptorRelationships = {
	.metataData = @"metataData",
};

@implementation QredoIndexVaultItemDescriptorID
@end

@implementation _QredoIndexVaultItemDescriptor

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVaultItemDescriptor" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVaultItemDescriptor";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVaultItemDescriptor" inManagedObjectContext:moc_];
}

- (QredoIndexVaultItemDescriptorID*)objectID {
	return (QredoIndexVaultItemDescriptorID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"sequenceValueValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sequenceValue"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic itemId;

@dynamic sequenceId;

@dynamic sequenceValue;

- (int64_t)sequenceValueValue {
	NSNumber *result = [self sequenceValue];
	return [result longLongValue];
}

- (void)setSequenceValueValue:(int64_t)value_ {
	[self setSequenceValue:@(value_)];
}

- (int64_t)primitiveSequenceValueValue {
	NSNumber *result = [self primitiveSequenceValue];
	return [result longLongValue];
}

- (void)setPrimitiveSequenceValueValue:(int64_t)value_ {
	[self setPrimitiveSequenceValue:@(value_)];
}

@dynamic metataData;

@end

