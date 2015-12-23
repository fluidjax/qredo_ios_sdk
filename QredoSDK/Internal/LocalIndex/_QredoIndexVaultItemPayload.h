// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemPayload.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemPayloadAttributes {
	__unsafe_unretained NSString *value;
} QredoIndexVaultItemPayloadAttributes;

extern const struct QredoIndexVaultItemPayloadRelationships {
	__unsafe_unretained NSString *vaultItem;
} QredoIndexVaultItemPayloadRelationships;

@class QredoIndexVaultItem;

@interface QredoIndexVaultItemPayloadID : NSManagedObjectID {}
@end

@interface _QredoIndexVaultItemPayload : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultItemPayloadID* objectID;

@property (nonatomic, strong) NSData* value;

//- (BOOL)validateValue:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItem *vaultItem;

//- (BOOL)validateVaultItem:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItemPayload (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveValue;
- (void)setPrimitiveValue:(NSData*)value;

- (QredoIndexVaultItem*)primitiveVaultItem;
- (void)setPrimitiveVaultItem:(QredoIndexVaultItem*)value;

@end
