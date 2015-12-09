#import "_QredoIndexVaultItemMetaData.h"

@class QredoVaultItemMetadata;
@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemMetadata : _QredoIndexVaultItemMetadata {}

+(instancetype)createWithMetadata:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
-(QredoVaultItemMetadata *)buildQredoVaultItemMetadata;
-(BOOL)isSameVersion:(QredoVaultItemMetadata*)metadata;

@end
