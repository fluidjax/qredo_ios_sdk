// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemDescriptor.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemDescriptorAttributes {
	__unsafe_unretained NSString *itemId;
	__unsafe_unretained NSString *sequenceId;
} QredoIndexVaultItemDescriptorAttributes;

extern const struct QredoIndexVaultItemDescriptorRelationships {
	__unsafe_unretained NSString *metataData;
} QredoIndexVaultItemDescriptorRelationships;

@class QredoIndexVaultItemMetadata;

@interface QredoIndexVaultItemDescriptorID : NSManagedObjectID {}
@end

@interface _QredoIndexVaultItemDescriptor : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QredoIndexVaultItemDescriptorID* objectID;

@property (nonatomic, strong) NSData* itemId;

//- (BOOL)validateItemId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* sequenceId;

//- (BOOL)validateSequenceId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) QredoIndexVaultItemMetadata *metataData;

//- (BOOL)validateMetataData:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItemDescriptor (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveItemId;
- (void)setPrimitiveItemId:(NSData*)value;

- (NSData*)primitiveSequenceId;
- (void)setPrimitiveSequenceId:(NSData*)value;

- (QredoIndexVaultItemMetadata*)primitiveMetataData;
- (void)setPrimitiveMetataData:(QredoIndexVaultItemMetadata*)value;

@end
