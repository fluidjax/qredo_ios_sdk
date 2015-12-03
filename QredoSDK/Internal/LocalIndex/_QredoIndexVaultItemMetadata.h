// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemMetadata.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemMetadataAttributes {
	__unsafe_unretained NSString *accessLevel;
	__unsafe_unretained NSString *created;
	__unsafe_unretained NSString *dataType;
} QredoIndexVaultItemMetadataAttributes;

extern const struct QredoIndexVaultItemMetadataRelationships {
	__unsafe_unretained NSString *descriptor;
	__unsafe_unretained NSString *summaryValues;
	__unsafe_unretained NSString *vaultItem;
} QredoIndexVaultItemMetadataRelationships;

@class QredoIndexVaultItemDescriptor;
@class QredoIndexSummaryValues;
@class QredoIndexVaultItem;

@interface QredoIndexVaultItemMetadataID : NSManagedObjectID {}
@end

@interface _QredoIndexVaultItemMetadata : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultItemMetadataID* objectID;

@property (nonatomic, strong) NSNumber* accessLevel;

@property (atomic) int16_t accessLevelValue;
- (int16_t)accessLevelValue;
- (void)setAccessLevelValue:(int16_t)value_;

//- (BOOL)validateAccessLevel:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* created;

//- (BOOL)validateCreated:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* dataType;

//- (BOOL)validateDataType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItemDescriptor *descriptor;

//- (BOOL)validateDescriptor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *summaryValues;

- (NSMutableSet*)summaryValuesSet;

@property (nonatomic, strong) QredoIndexVaultItem *vaultItem;

//- (BOOL)validateVaultItem:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItemMetadata (SummaryValuesCoreDataGeneratedAccessors)
- (void)addSummaryValues:(NSSet*)value_;
- (void)removeSummaryValues:(NSSet*)value_;
- (void)addSummaryValuesObject:(QredoIndexSummaryValues*)value_;
- (void)removeSummaryValuesObject:(QredoIndexSummaryValues*)value_;

@end

@interface _QredoIndexVaultItemMetadata (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveAccessLevel;
- (void)setPrimitiveAccessLevel:(NSNumber*)value;

- (int16_t)primitiveAccessLevelValue;
- (void)setPrimitiveAccessLevelValue:(int16_t)value_;

- (NSDate*)primitiveCreated;
- (void)setPrimitiveCreated:(NSDate*)value;

- (NSString*)primitiveDataType;
- (void)setPrimitiveDataType:(NSString*)value;

- (QredoIndexVaultItemDescriptor*)primitiveDescriptor;
- (void)setPrimitiveDescriptor:(QredoIndexVaultItemDescriptor*)value;

- (NSMutableSet*)primitiveSummaryValues;
- (void)setPrimitiveSummaryValues:(NSMutableSet*)value;

- (QredoIndexVaultItem*)primitiveVaultItem;
- (void)setPrimitiveVaultItem:(QredoIndexVaultItem*)value;

@end
