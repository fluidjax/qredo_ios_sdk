// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItem.m instead.

#import "_QredoIndexVaultItem.h"

const struct QredoIndexVaultItemAttributes QredoIndexVaultItemAttributes = {
	.hasValue = @"hasValue",
	.itemId = @"itemId",
	.value = @"value",
};

const struct QredoIndexVaultItemRelationships QredoIndexVaultItemRelationships = {
	.latest = @"latest",
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

@dynamic value;

@dynamic latest;

@dynamic vault;

@end

