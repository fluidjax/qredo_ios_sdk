// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItem.m instead.

#import "_QredoIndexVaultItem.h"

const struct QredoIndexVaultItemAttributes QredoIndexVaultItemAttributes = {
	.hasValue = @"hasValue",
	.itemId = @"itemId",
	.metadataSize = @"metadataSize",
	.onServer = @"onServer",
	.valueSize = @"valueSize",
};

const struct QredoIndexVaultItemRelationships QredoIndexVaultItemRelationships = {
	.latest = @"latest",
	.payload = @"payload",
	.vault = @"vault",
};

@implementation QredoIndexVaultItemID
@end

@implementation _QredoIndexVaultItem

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVaultItem" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVaultItem";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVaultItem" inManagedObjectContext:moc_];
}

- (QredoIndexVaultItemID*)objectID {
	return (QredoIndexVaultItemID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"hasValueValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"hasValue"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"metadataSizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"metadataSize"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"onServerValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"onServer"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"valueSizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"valueSize"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic hasValue;

- (BOOL)hasValueValue {
	NSNumber *result = [self hasValue];
	return [result boolValue];
}

- (void)setHasValueValue:(BOOL)value_ {
	[self setHasValue:@(value_)];
}

- (BOOL)primitiveHasValueValue {
	NSNumber *result = [self primitiveHasValue];
	return [result boolValue];
}

- (void)setPrimitiveHasValueValue:(BOOL)value_ {
	[self setPrimitiveHasValue:@(value_)];
}

@dynamic itemId;

@dynamic metadataSize;

- (int64_t)metadataSizeValue {
	NSNumber *result = [self metadataSize];
	return [result longLongValue];
}

- (void)setMetadataSizeValue:(int64_t)value_ {
	[self setMetadataSize:@(value_)];
}

- (int64_t)primitiveMetadataSizeValue {
	NSNumber *result = [self primitiveMetadataSize];
	return [result longLongValue];
}

- (void)setPrimitiveMetadataSizeValue:(int64_t)value_ {
	[self setPrimitiveMetadataSize:@(value_)];
}

@dynamic onServer;

- (BOOL)onServerValue {
	NSNumber *result = [self onServer];
	return [result boolValue];
}

- (void)setOnServerValue:(BOOL)value_ {
	[self setOnServer:@(value_)];
}

- (BOOL)primitiveOnServerValue {
	NSNumber *result = [self primitiveOnServer];
	return [result boolValue];
}

- (void)setPrimitiveOnServerValue:(BOOL)value_ {
	[self setPrimitiveOnServer:@(value_)];
}

@dynamic valueSize;

- (int64_t)valueSizeValue {
	NSNumber *result = [self valueSize];
	return [result longLongValue];
}

- (void)setValueSizeValue:(int64_t)value_ {
	[self setValueSize:@(value_)];
}

- (int64_t)primitiveValueSizeValue {
	NSNumber *result = [self primitiveValueSize];
	return [result longLongValue];
}

- (void)setPrimitiveValueSizeValue:(int64_t)value_ {
	[self setPrimitiveValueSize:@(value_)];
}

@dynamic latest;

@dynamic payload;

@dynamic vault;

@end

