#import "_QredoIndexVaultItem.h"

@class QredoVaultItemMetadata;
@class QredoIndexVaultIndex;

@interface QredoIndexVaultItem : _QredoIndexVaultItem {}

+(QredoIndexVaultItem *)searchForIndexByItemIdWithMetadata:(QredoVaultItemMetadata *)metadata  inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
-(void)addNewVersion:(QredoVaultItemMetadata *)metadata;
+(QredoIndexVaultItem *)create:(QredoVaultItemMetadata *)metadata  inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
