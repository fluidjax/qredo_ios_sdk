// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemDescriptor.m instead.

#import "_QredoIndexVaultItemDescriptor.h"

const struct QredoIndexVaultItemDescriptorAttributes QredoIndexVaultItemDescriptorAttributes = {
	.itemId = @"itemId",
	.sequenceId = @"sequenceId",
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

	return keyPaths;
}

@dynamic itemId;

@dynamic sequenceId;

@dynamic metataData;

@end

