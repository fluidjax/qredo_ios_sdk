// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItem.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemAttributes {
	__unsafe_unretained NSString *hasValue;
	__unsafe_unretained NSString *itemId;
	__unsafe_unretained NSString *value;
} QredoIndexVaultItemAttributes;

extern const struct QredoIndexVaultItemRelationships {
	__unsafe_unretained NSString *latest;
	__unsafe_unretained NSString *vault;
} QredoIndexVaultItemRelationships;

@class QredoIndexVaultItemMetadata;
@class QredoIndexVault;

@interface QredoIndexVaultItemID : NSManagedObjectID {}
@end

@interface _QredoIndexVaultItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultItemID* objectID;

@property (nonatomic, strong) NSNumber* hasValue;

@property (atomic) BOOL hasValueValue;
- (BOOL)hasValueValue;
- (void)setHasValueValue:(BOOL)value_;

//- (BOOL)validateHasValue:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* itemId;

//- (BOOL)validateItemId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* value;

//- (BOOL)validateValue:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItemMetadata *latest;

//- (BOOL)validateLatest:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVault *vault;

//- (BOOL)validateVault:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItem (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveHasValue;
- (void)setPrimitiveHasValue:(NSNumber*)value;

- (BOOL)primitiveHasValueValue;
- (void)setPrimitiveHasValueValue:(BOOL)value_;

- (NSData*)primitiveItemId;
- (void)setPrimitiveItemId:(NSData*)value;

- (NSData*)primitiveValue;
- (void)setPrimitiveValue:(NSData*)value;

- (QredoIndexVaultItemMetadata*)primitiveLatest;
- (void)setPrimitiveLatest:(QredoIndexVaultItemMetadata*)value;

- (QredoIndexVault*)primitiveVault;
- (void)setPrimitiveVault:(QredoIndexVault*)value;

@end
