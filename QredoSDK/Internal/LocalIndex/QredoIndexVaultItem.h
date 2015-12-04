#import "_QredoIndexVaultItem.h"

@class QredoVaultItemMetadata;
@class QredoIndexVaultIndex;

@interface QredoIndexVaultItem : _QredoIndexVaultItem {}


+(QredoIndexVaultItem *)searchForIndexWithMetata:(QredoVaultItemMetadata *)metadata  inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
-(void)addVersion:(QredoVaultItemMetadata *)metadata;
+(QredoIndexVaultItem *)create:(QredoVaultItemMetadata *)metadata  inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;


@end
