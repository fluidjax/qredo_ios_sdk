#import "_QredoIndexVaultItem.h"

@class QredoVaultItemMetadata;
@class QredoVaultItemDescriptor;
@class QredoIndexVaultIndex;
@class QredoVaultItem;

@interface QredoIndexVaultItem : _QredoIndexVaultItem {}



-(QredoVaultItem *)buildQredoVaultItem;
+(QredoIndexVaultItem *)searchForIndexByItemIdWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
-(void)addNewVersion:(QredoVaultItemMetadata *)metadata;
+(QredoIndexVaultItem *)create:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
-(void)setVaultValue:(NSData *)data hasVaultItemValue:(BOOL)hasVaultItemValue;
@end
