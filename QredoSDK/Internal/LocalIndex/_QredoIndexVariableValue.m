// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVariableValue.m instead.

#import "_QredoIndexVariableValue.h"

const struct QredoIndexVariableValueAttributes QredoIndexVariableValueAttributes = {
	.date = @"date",
	.number = @"number",
	.qredoQUID = @"qredoQUID",
	.string = @"string",
};

const struct QredoIndexVariableValueRelationships QredoIndexVariableValueRelationships = {
	.summaryValue = @"summaryValue",
};

@implementation QredoIndexVariableValueID
@end

@implementation _QredoIndexVariableValue

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVariableValue" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVariableValue";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVariableValue" inManagedObjectContext:moc_];
}

- (QredoIndexVariableValueID*)objectID {
	return (QredoIndexVariableValueID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"numberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"number"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic date;

@dynamic number;

- (int64_t)numberValue {
	NSNumber *result = [self number];
	return [result longLongValue];
}

- (void)setNumberValue:(int64_t)value_ {
	[self setNumber:@(value_)];
}

- (int64_t)primitiveNumberValue {
	NSNumber *result = [self primitiveNumber];
	return [result longLongValue];
}

- (void)setPrimitiveNumberValue:(int64_t)value_ {
	[self setPrimitiveNumber:@(value_)];
}

@dynamic qredoQUID;

@dynamic string;

@dynamic summaryValue;

@end

