/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
@import CoreData;
@class QredoVault;
@class QredoUserCredentials;

@interface QredoLocalIndexDataStore :NSObject

@property (strong,readonly) NSManagedObjectContext *managedObjectContext;

-(instancetype)initWithVault:(QredoVault *)vault;
-(void)saveContext:(BOOL)wait;
-(long)persistentStoreFileSize;

/** Delete the coredata sqllite database, and rebuild the coredata stack
 This ensures a clean start point, useful for errors and tests
 Use before any QredoClients are created
 */
//- (void)deleteStore:(QredoVault *)vault;

+(NSURL *)storeURL:(QredoUserCredentials *)userCredentials vault:(QredoVault*)vault;
//+(void)deleteStore:(QredoUserCredentials *)userCredentials;
//+(void)renameStoreFrom:(QredoUserCredentials *)fromUserCredentials to:(QredoUserCredentials *)toUserCredentials;
@end
