#import "_QredoIndexVault.h"
@class QredoVault;

@interface QredoIndexVault : _QredoIndexVault {}

+(QredoIndexVault *)searchForVaultIndexWithId:(NSData *)vaultId inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(QredoIndexVault *)create:(QredoVault *)qredoVault inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;


@end
