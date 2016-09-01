/* HEADER GOES HERE */
#import "_QredoIndexVaultItemDescriptor.h"

@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemDescriptor :_QredoIndexVaultItemDescriptor {}

+(instancetype)createWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(instancetype)searchForDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

-(QredoVaultItemDescriptor *)buildQredoVaultItemDescriptor;

@end
