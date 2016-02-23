// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemMetadata.m instead.

#import "_QredoIndexVaultItemMetadata.h"

const struct QredoIndexVaultItemMetadataAttributes QredoIndexVaultItemMetadataAttributes = {
	.accessLevel = @"accessLevel",
	.created = @"created",
	.dataType = @"dataType",
	.lastAccessed = @"lastAccessed",
};

const struct QredoIndexVaultItemMetadataRelationships QredoIndexVaultItemMetadataRelationships = {
	.descriptor = @"descriptor",
	.summaryValues = @"summaryValues",
	.vaultItem = @"vaultItem",
};

@implementation QredoIndexVaultItemMetadataID
@end

@implementation _QredoIndexVaultItemMetadata

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVaultItemMetadata" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVaultItemMetadata";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVaultItemMetadata" inManagedObjectContext:moc_];
}

- (QredoIndexVaultItemMetadataID*)objectID {
	return (QredoIndexVaultItemMetadataID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"accessLevelValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"accessLevel"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic accessLevel;

- (int16_t)accessLevelValue {
	NSNumber *result = [self accessLevel];
	return [result shortValue];
}

- (void)setAccessLevelValue:(int16_t)value_ {
	[self setAccessLevel:@(value_)];
}

- (int16_t)primitiveAccessLevelValue {
	NSNumber *result = [self primitiveAccessLevel];
	return [result shortValue];
}

- (void)setPrimitiveAccessLevelValue:(int16_t)value_ {
	[self setPrimitiveAccessLevel:@(value_)];
}

@dynamic created;

@dynamic dataType;

@dynamic lastAccessed;

@dynamic descriptor;

@dynamic summaryValues;

- (NSMutableSet*)summaryValuesSet {
	[self willAccessValueForKey:@"summaryValues"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"summaryValues"];

	[self didAccessValueForKey:@"summaryValues"];
	return result;
}

@dynamic vaultItem;

@end

