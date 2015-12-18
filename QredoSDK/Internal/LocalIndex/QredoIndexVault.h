#import "_QredoIndexVault.h"
@class QredoVault;

@interface QredoIndexVault : _QredoIndexVault {}

+(QredoIndexVault *)fetchOrCreateWith:(QredoVault *)vault inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;


@end
