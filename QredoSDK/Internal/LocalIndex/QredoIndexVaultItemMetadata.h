#import "_QredoIndexVaultItemMetaData.h"

@class QredoVaultItemMetadata;

@interface QredoIndexVaultItemMetadata : _QredoIndexVaultItemMetadata {}


+(instancetype)createOrUpdateWith:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
