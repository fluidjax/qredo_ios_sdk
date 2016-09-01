/* HEADER GOES HERE */
#import "_QredoIndexVaultItem.h"

@class QredoVaultItemMetadata;
@class QredoVaultItemDescriptor;
@class QredoIndexVaultIndex;
@class QredoVaultItem;

@interface QredoIndexVaultItem :_QredoIndexVaultItem {}

+(QredoIndexVaultItem *)searchForIndexByItemIdWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(QredoIndexVaultItem *)create:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
-(QredoVaultItem *)buildQredoVaultItem;
-(void)addNewVersion:(QredoVaultItemMetadata *)metadata;
-(void)setVaultValue:(NSData *)data hasVaultItemValue:(BOOL)hasVaultItemValue;

@end
