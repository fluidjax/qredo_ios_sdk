// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultIndex.h instead.

@import CoreData;

extern const struct QredoIndexVaultIndexAttributes {
	__unsafe_unretained NSString *vaultId;
} QredoIndexVaultIndexAttributes;

extern const struct QredoIndexVaultIndexRelationships {
	__unsafe_unretained NSString *latest;
	__unsafe_unretained NSString *previous;
} QredoIndexVaultIndexRelationships;

@class QredoIndexVaultItem;
@class QredoIndexVaultItem;

@interface QredoIndexVaultIndexID : NSManagedObjectID {}
@end

@interface _QredoIndexVaultIndex : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultIndexID* objectID;

@property (nonatomic, strong) NSData* vaultId;

//- (BOOL)validateVaultId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItem *latest;

//- (BOOL)validateLatest:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *previous;

- (NSMutableSet*)previousSet;

@end

@interface _QredoIndexVaultIndex (PreviousCoreDataGeneratedAccessors)
- (void)addPrevious:(NSSet*)value_;
- (void)removePrevious:(NSSet*)value_;
- (void)addPreviousObject:(QredoIndexVaultItem*)value_;
- (void)removePreviousObject:(QredoIndexVaultItem*)value_;

@end

@interface _QredoIndexVaultIndex (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveVaultId;
- (void)setPrimitiveVaultId:(NSData*)value;

- (QredoIndexVaultItem*)primitiveLatest;
- (void)setPrimitiveLatest:(QredoIndexVaultItem*)value;

- (NSMutableSet*)primitivePrevious;
- (void)setPrimitivePrevious:(NSMutableSet*)value;

@end
