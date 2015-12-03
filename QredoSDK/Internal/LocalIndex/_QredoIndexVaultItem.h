// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItem.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemAttributes {
	__unsafe_unretained NSString *value;
} QredoIndexVaultItemAttributes;

extern const struct QredoIndexVaultItemRelationships {
	__unsafe_unretained NSString *metadata;
} QredoIndexVaultItemRelationships;

@class QredoIndexVaultItemMetadata;

@interface QredoIndexVaultItemID : NSManagedObjectID {}
@end

@interface _QredoIndexVaultItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultItemID* objectID;

@property (nonatomic, strong) NSData* value;

//- (BOOL)validateValue:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItemMetadata *metadata;

//- (BOOL)validateMetadata:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItem (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveValue;
- (void)setPrimitiveValue:(NSData*)value;

- (QredoIndexVaultItemMetadata*)primitiveMetadata;
- (void)setPrimitiveMetadata:(QredoIndexVaultItemMetadata*)value;

@end
