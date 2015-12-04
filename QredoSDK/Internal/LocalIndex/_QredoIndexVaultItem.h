// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItem.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemAttributes {
	__unsafe_unretained NSString *itemId;
} QredoIndexVaultItemAttributes;

extern const struct QredoIndexVaultItemRelationships {
	__unsafe_unretained NSString *allVersions;
	__unsafe_unretained NSString *latest;
} QredoIndexVaultItemRelationships;

@class QredoIndexVaultItemMetadata;
@class QredoIndexVaultItemMetadata;

@interface QredoIndexVaultItemID : NSManagedObjectID {}
@end

@interface _QredoIndexVaultItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultItemID* objectID;

@property (nonatomic, strong) NSData* itemId;

//- (BOOL)validateItemId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *allVersions;

- (NSMutableSet*)allVersionsSet;

@property (nonatomic, strong) QredoIndexVaultItemMetadata *latest;

//- (BOOL)validateLatest:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItem (AllVersionsCoreDataGeneratedAccessors)
- (void)addAllVersions:(NSSet*)value_;
- (void)removeAllVersions:(NSSet*)value_;
- (void)addAllVersionsObject:(QredoIndexVaultItemMetadata*)value_;
- (void)removeAllVersionsObject:(QredoIndexVaultItemMetadata*)value_;

@end

@interface _QredoIndexVaultItem (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveItemId;
- (void)setPrimitiveItemId:(NSData*)value;

- (NSMutableSet*)primitiveAllVersions;
- (void)setPrimitiveAllVersions:(NSMutableSet*)value;

- (QredoIndexVaultItemMetadata*)primitiveLatest;
- (void)setPrimitiveLatest:(QredoIndexVaultItemMetadata*)value;

@end
