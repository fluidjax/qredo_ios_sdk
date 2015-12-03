#import "_QredoIndexVaultItemMetaData.h"

@class QredoVaultItemMetadata;
@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemMetadata : _QredoIndexVaultItemMetadata {}


+(instancetype)createOrUpdateWith:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(QredoVaultItemMetadata*)get:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end
