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
+(NSURL *)storeURLWithVault:(QredoVault*)vault;
@end
