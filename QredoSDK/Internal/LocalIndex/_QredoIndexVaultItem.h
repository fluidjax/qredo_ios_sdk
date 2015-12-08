// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItem.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemAttributes {
	__unsafe_unretained NSString *itemId;
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

@property (nonatomic, strong) NSData* itemId;

//- (BOOL)validateItemId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItemMetadata *latest;

//- (BOOL)validateLatest:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVault *vault;

//- (BOOL)validateVault:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItem (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveItemId;
- (void)setPrimitiveItemId:(NSData*)value;

- (QredoIndexVaultItemMetadata*)primitiveLatest;
- (void)setPrimitiveLatest:(QredoIndexVaultItemMetadata*)value;

- (QredoIndexVault*)primitiveVault;
- (void)setPrimitiveVault:(QredoIndexVault*)value;

@end
