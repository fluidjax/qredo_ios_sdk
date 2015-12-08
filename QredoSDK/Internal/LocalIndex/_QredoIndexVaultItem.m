// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItem.m instead.

#import "_QredoIndexVaultItem.h"

const struct QredoIndexVaultItemAttributes QredoIndexVaultItemAttributes = {
	.itemId = @"itemId",
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

	return keyPaths;
}

@dynamic itemId;

@dynamic latest;

@dynamic vault;

@end

