// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVault.m instead.

#import "_QredoIndexVault.h"

const struct QredoIndexVaultAttributes QredoIndexVaultAttributes = {
	.highWaterMark = @"highWaterMark",
	.metadataTotalSize = @"metadataTotalSize",
	.valueTotalSize = @"valueTotalSize",
	.vaultId = @"vaultId",
};

const struct QredoIndexVaultRelationships QredoIndexVaultRelationships = {
	.vaultItems = @"vaultItems",
};

@implementation QredoIndexVaultID
@end

@implementation _QredoIndexVault

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVault" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVault";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVault" inManagedObjectContext:moc_];
}

- (QredoIndexVaultID*)objectID {
	return (QredoIndexVaultID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"metadataTotalSizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"metadataTotalSize"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"valueTotalSizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"valueTotalSize"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic highWaterMark;

@dynamic metadataTotalSize;

- (int64_t)metadataTotalSizeValue {
	NSNumber *result = [self metadataTotalSize];
	return [result longLongValue];
}

- (void)setMetadataTotalSizeValue:(int64_t)value_ {
	[self setMetadataTotalSize:@(value_)];
}

- (int64_t)primitiveMetadataTotalSizeValue {
	NSNumber *result = [self primitiveMetadataTotalSize];
	return [result longLongValue];
}

- (void)setPrimitiveMetadataTotalSizeValue:(int64_t)value_ {
	[self setPrimitiveMetadataTotalSize:@(value_)];
}

@dynamic valueTotalSize;

- (int64_t)valueTotalSizeValue {
	NSNumber *result = [self valueTotalSize];
	return [result longLongValue];
}

- (void)setValueTotalSizeValue:(int64_t)value_ {
	[self setValueTotalSize:@(value_)];
}

- (int64_t)primitiveValueTotalSizeValue {
	NSNumber *result = [self primitiveValueTotalSize];
	return [result longLongValue];
}

- (void)setPrimitiveValueTotalSizeValue:(int64_t)value_ {
	[self setPrimitiveValueTotalSize:@(value_)];
}

@dynamic vaultId;

@dynamic vaultItems;

- (NSMutableSet*)vaultItemsSet {
	[self willAccessValueForKey:@"vaultItems"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"vaultItems"];

	[self didAccessValueForKey:@"vaultItems"];
	return result;
}

@end

