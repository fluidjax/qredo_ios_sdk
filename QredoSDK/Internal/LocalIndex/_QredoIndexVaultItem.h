//DO NOT EDIT. This file is machine-generated and constantly overwritten.
//Make changes to QredoIndexVaultItem.h instead.

@import CoreData;

extern const struct QredoIndexVaultItemAttributes {
    __unsafe_unretained NSString *hasValue;
    __unsafe_unretained NSString *itemId;
    __unsafe_unretained NSString *metadataSize;
    __unsafe_unretained NSString *onServer;
    __unsafe_unretained NSString *valueSize;
} QredoIndexVaultItemAttributes;

extern const struct QredoIndexVaultItemRelationships {
    __unsafe_unretained NSString *latest;
    __unsafe_unretained NSString *payload;
    __unsafe_unretained NSString *vault;
} QredoIndexVaultItemRelationships;

@class QredoIndexVaultItemMetadata;
@class QredoIndexVaultItemPayload;
@class QredoIndexVault;

@interface QredoIndexVaultItemID :NSManagedObjectID {}
@end

@interface _QredoIndexVaultItem :NSManagedObject {}
+(id)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+(NSString *)entityName;
+(NSEntityDescription *)entityInManagedObjectContext:(NSManagedObjectContext *)moc_;
@property (nonatomic,readonly,strong) QredoIndexVaultItemID *objectID;

@property (nonatomic,strong) NSNumber *hasValue;

@property (atomic) BOOL hasValueValue;
-(BOOL)hasValueValue;
-(void)setHasValueValue:(BOOL)value_;

//- (BOOL)validateHasValue:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSData *itemId;

//- (BOOL)validateItemId:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSNumber *metadataSize;

@property (atomic) int64_t metadataSizeValue;
-(int64_t)metadataSizeValue;
-(void)setMetadataSizeValue:(int64_t)value_;

//- (BOOL)validateMetadataSize:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSNumber *onServer;

@property (atomic) BOOL onServerValue;
-(BOOL)onServerValue;
-(void)setOnServerValue:(BOOL)value_;

//- (BOOL)validateOnServer:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) NSNumber *valueSize;

@property (atomic) int64_t valueSizeValue;
-(int64_t)valueSizeValue;
-(void)setValueSizeValue:(int64_t)value_;

//- (BOOL)validateValueSize:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) QredoIndexVaultItemMetadata *latest;

//- (BOOL)validateLatest:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) QredoIndexVaultItemPayload *payload;

//- (BOOL)validatePayload:(id*)value_ error:(NSError**)error_;

@property (nonatomic,strong) QredoIndexVault *vault;

//- (BOOL)validateVault:(id*)value_ error:(NSError**)error_;

@end

@interface _QredoIndexVaultItem (CoreDataGeneratedPrimitiveAccessors)

-(NSNumber *)primitiveHasValue;
-(void)setPrimitiveHasValue:(NSNumber *)value;

-(BOOL)primitiveHasValueValue;
-(void)setPrimitiveHasValueValue:(BOOL)value_;

-(NSData *)primitiveItemId;
-(void)setPrimitiveItemId:(NSData *)value;

-(NSNumber *)primitiveMetadataSize;
-(void)setPrimitiveMetadataSize:(NSNumber *)value;

-(int64_t)primitiveMetadataSizeValue;
-(void)setPrimitiveMetadataSizeValue:(int64_t)value_;

-(NSNumber *)primitiveOnServer;
-(void)setPrimitiveOnServer:(NSNumber *)value;

-(BOOL)primitiveOnServerValue;
-(void)setPrimitiveOnServerValue:(BOOL)value_;

-(NSNumber *)primitiveValueSize;
-(void)setPrimitiveValueSize:(NSNumber *)value;

-(int64_t)primitiveValueSizeValue;
-(void)setPrimitiveValueSizeValue:(int64_t)value_;

-(QredoIndexVaultItemMetadata *)primitiveLatest;
-(void)setPrimitiveLatest:(QredoIndexVaultItemMetadata *)value;

-(QredoIndexVaultItemPayload *)primitivePayload;
-(void)setPrimitivePayload:(QredoIndexVaultItemPayload *)value;

-(QredoIndexVault *)primitiveVault;
-(void)setPrimitiveVault:(QredoIndexVault *)value;

@end
