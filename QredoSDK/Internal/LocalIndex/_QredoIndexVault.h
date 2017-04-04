//DO NOT EDIT. This file is machine-generated and constantly overwritten.
//Make changes to QredoIndexVault.h instead.

@import CoreData;

extern const struct QredoIndexVaultAttributes {
    __unsafe_unretained NSString *highWaterMark;
    __unsafe_unretained NSString *metadataTotalSize;
    __unsafe_unretained NSString *valueTotalSize;
    __unsafe_unretained NSString *vaultId;
} QredoIndexVaultAttributes;

extern const struct QredoIndexVaultRelationships {
    __unsafe_unretained NSString *vaultItems;
} QredoIndexVaultRelationships;

@class QredoIndexVaultItem;

@interface QredoIndexVaultID :NSManagedObjectID {}
@end

@interface _QredoIndexVault :NSManagedObject {}
+(id)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+(NSString *)entityName;
+(NSEntityDescription *)entityInManagedObjectContext:(NSManagedObjectContext *)moc_;
@property (nonatomic,readonly,strong) QredoIndexVaultID *objectID;

@property (nonatomic,strong) NSData *highWaterMark;

//- (BOOL)validateHighWaterMark:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSNumber *metadataTotalSize;

@property (atomic) int64_t metadataTotalSizeValue;
-(int64_t)metadataTotalSizeValue;
-(void)setMetadataTotalSizeValue:(int64_t)value_;

//- (BOOL)validateMetadataTotalSize:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSNumber *valueTotalSize;

@property (atomic) int64_t valueTotalSizeValue;
-(int64_t)valueTotalSizeValue;
-(void)setValueTotalSizeValue:(int64_t)value_;

//- (BOOL)validateValueTotalSize:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSData *vaultId;

//- (BOOL)validateVaultId:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSSet *vaultItems;

-(NSMutableSet *)vaultItemsSet;

@end

@interface _QredoIndexVault (VaultItemsCoreDataGeneratedAccessors)
-(void)addVaultItems:(NSSet *)value_;
-(void)removeVaultItems:(NSSet *)value_;
-(void)addVaultItemsObject:(QredoIndexVaultItem *)value_;
-(void)removeVaultItemsObject:(QredoIndexVaultItem *)value_;

@end

@interface _QredoIndexVault (CoreDataGeneratedPrimitiveAccessors)

-(NSData *)primitiveHighWaterMark;
-(void)setPrimitiveHighWaterMark:(NSData *)value;

-(NSNumber *)primitiveMetadataTotalSize;
-(void)setPrimitiveMetadataTotalSize:(NSNumber *)value;

-(int64_t)primitiveMetadataTotalSizeValue;
-(void)setPrimitiveMetadataTotalSizeValue:(int64_t)value_;

-(NSNumber *)primitiveValueTotalSize;
-(void)setPrimitiveValueTotalSize:(NSNumber *)value;

-(int64_t)primitiveValueTotalSizeValue;
-(void)setPrimitiveValueTotalSizeValue:(int64_t)value_;

-(NSData *)primitiveVaultId;
-(void)setPrimitiveVaultId:(NSData *)value;

-(NSMutableSet *)primitiveVaultItems;
-(void)setPrimitiveVaultItems:(NSMutableSet *)value;

@end
