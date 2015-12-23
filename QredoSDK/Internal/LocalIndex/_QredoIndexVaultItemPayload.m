// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemPayload.m instead.

#import "_QredoIndexVaultItemPayload.h"

const struct QredoIndexVaultItemPayloadAttributes QredoIndexVaultItemPayloadAttributes = {
	.value = @"value",
};

const struct QredoIndexVaultItemPayloadRelationships QredoIndexVaultItemPayloadRelationships = {
	.vaultItem = @"vaultItem",
};

@implementation QredoIndexVaultItemPayloadID
@end

@implementation _QredoIndexVaultItemPayload

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVaultItemPayload" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVaultItemPayload";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVaultItemPayload" inManagedObjectContext:moc_];
}

- (QredoIndexVaultItemPayloadID*)objectID {
	return (QredoIndexVaultItemPayloadID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic value;

@dynamic vaultItem;

@end

