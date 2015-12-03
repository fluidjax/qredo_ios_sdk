
#import "_QredoIndexVaultItemDescriptor.h"

@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemDescriptor : _QredoIndexVaultItemDescriptor {}



+(instancetype)createWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(instancetype)objectForDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end
