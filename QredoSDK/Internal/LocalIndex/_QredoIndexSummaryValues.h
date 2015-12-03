// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexSummaryValues.h instead.

@import CoreData;

extern const struct QredoIndexSummaryValuesAttributes {
	__unsafe_unretained NSString *key;
	__unsafe_unretained NSString *value;
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

@property (nonatomic, strong) NSData* key;

//- (BOOL)validateKey:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* value;

//- (BOOL)validateValue:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItemMetadata *vaultMetadata;

//- (BOOL)validateVaultMetadata:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexSummaryValues (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveKey;
- (void)setPrimitiveKey:(NSData*)value;

- (NSData*)primitiveValue;
- (void)setPrimitiveValue:(NSData*)value;

- (QredoIndexVaultItemMetadata*)primitiveVaultMetadata;
- (void)setPrimitiveVaultMetadata:(QredoIndexVaultItemMetadata*)value;

@end
