// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexSummaryValues.h instead.

@import CoreData;

extern const struct QredoIndexSummaryValuesAttributes {
	__unsafe_unretained NSString *key;
	__unsafe_unretained NSString *value.date;
	__unsafe_unretained NSString *value.string;
	__unsafe_unretained NSString *valueType;
} QredoIndexSummaryValuesAttributes;

extern const struct QredoIndexSummaryValuesRelationships {
	__unsafe_unretained NSString *vaultMetadata;
} QredoIndexSummaryValuesRelationships;

@class QredoIndexVaultItemMetadata;

@interface QredoIndexSummaryValuesID : NSManagedObjectID {}
@end

@interface _QredoIndexSummaryValues : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexSummaryValuesID* objectID;

@property (nonatomic, strong) NSString* key;

//- (BOOL)validateKey:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* value.date;

//- (BOOL)validateValue.date:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* value.string;

//- (BOOL)validateValue.string:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* valueType;

@property (atomic) int16_t valueTypeValue;
- (int16_t)valueTypeValue;
- (void)setValueTypeValue:(int16_t)value_;

//- (BOOL)validateValueType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItemMetadata *vaultMetadata;

//- (BOOL)validateVaultMetadata:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexSummaryValues (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveKey;
- (void)setPrimitiveKey:(NSString*)value;

- (NSDate*)primitiveValue.date;
- (void)setPrimitiveValue.date:(NSDate*)value;

- (NSString*)primitiveValue.string;
- (void)setPrimitiveValue.string:(NSString*)value;

- (NSNumber*)primitiveValueType;
- (void)setPrimitiveValueType:(NSNumber*)value;

- (int16_t)primitiveValueTypeValue;
- (void)setPrimitiveValueTypeValue:(int16_t)value_;

- (QredoIndexVaultItemMetadata*)primitiveVaultMetadata;
- (void)setPrimitiveVaultMetadata:(QredoIndexVaultItemMetadata*)value;

@end
