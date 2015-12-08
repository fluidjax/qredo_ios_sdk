// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVault.h instead.

@import CoreData;

extern const struct QredoIndexVaultAttributes {
	__unsafe_unretained NSString *highWaterMark;
	__unsafe_unretained NSString *vaultId;
} QredoIndexVaultAttributes;

extern const struct QredoIndexVaultRelationships {
	__unsafe_unretained NSString *vaultItems;
} QredoIndexVaultRelationships;

@class QredoIndexVaultItem;

@interface QredoIndexVaultID : NSManagedObjectID {}
@end

@interface _QredoIndexVault : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultID* objectID;

@property (nonatomic, strong) NSData* highWaterMark;

//- (BOOL)validateHighWaterMark:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* vaultId;

//- (BOOL)validateVaultId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *vaultItems;

- (NSMutableSet*)vaultItemsSet;

@end

@interface _QredoIndexVault (VaultItemsCoreDataGeneratedAccessors)
- (void)addVaultItems:(NSSet*)value_;
- (void)removeVaultItems:(NSSet*)value_;
- (void)addVaultItemsObject:(QredoIndexVaultItem*)value_;
- (void)removeVaultItemsObject:(QredoIndexVaultItem*)value_;

@end

@interface _QredoIndexVault (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveHighWaterMark;
- (void)setPrimitiveHighWaterMark:(NSData*)value;

- (NSData*)primitiveVaultId;
- (void)setPrimitiveVaultId:(NSData*)value;

- (NSMutableSet*)primitiveVaultItems;
- (void)setPrimitiveVaultItems:(NSMutableSet*)value;

@end
