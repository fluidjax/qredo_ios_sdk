/* HEADER GOES HERE */

//A singleton that handles the Coredata LocalIndex initialization and persisentent store.
@import CoreData;
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoUserCredentials.h"
#import "QredoLoggerPrivate.h"



@interface QredoLocalIndexDataStore ()
@property (strong) NSManagedObjectContext *privateContext;
@property (strong) NSManagedObjectContext *managedObjectContext;
@property (strong) QredoUserCredentials *userCredentials;
@property (strong) QredoVault *vault;
@end

@implementation QredoLocalIndexDataStore

NSURL *_storeUrl;

static NSMutableDictionary *dataStoreDictionary;


+(void)initialize {
    //this is run just once when the class is first loaded
    dataStoreDictionary = [[NSMutableDictionary alloc] init];
}


-(instancetype)initWithVault:(QredoVault *)vault {
    //we cache the Datastores so if a new client requests an already loaded data store, it returns the existing one - otherwise we have two clients access the sqllite separately
    
    QredoUserCredentials *userCredentials = vault.userCredentials;
    self.vault = vault;
    
    NSString *uniqueIdentifier =  [NSString stringWithFormat:@"%@-%@",[userCredentials buildIndexName],vault.vaultId];

    QredoLocalIndexDataStore *existingDataStore = [dataStoreDictionary objectForKey:uniqueIdentifier];
    
    if (existingDataStore)return existingDataStore;
    
    self = [super init];
    
    if (self){
        _userCredentials = userCredentials;
        [self buildStack:vault];
        [dataStoreDictionary setObject:self forKey:uniqueIdentifier];
    }
    
    return self;
}



-(void)saveContext:(BOOL)wait {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectContext *privateContext = [self privateContext];
    
    if (!moc)return;
    
    if ([moc hasChanges]){
        [moc performBlockAndWait:^{
            NSError *error = nil;
            [moc save:&error];
            NSAssert(error == nil,@"MetadataIndex: Error saving MOC :%@\n%@",[error localizedDescription],[error userInfo]);
        }];
    }
    
    void (^savePrivate) (void) = ^{
        NSError *error = nil;
        NSAssert([privateContext save:&error],@"MetadataIndex: Error saving Private MOC :%@\n%@",[error localizedDescription],[error userInfo]);
    };
    
    if ([privateContext hasChanges]){
        if (wait){
            [privateContext performBlockAndWait:savePrivate];
        } else {
            [privateContext performBlock:savePrivate];
        }
    }
}


-(long)persistentStoreFileSize {
    long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [[QredoLocalIndexDataStore storeURL:self.userCredentials vault:self.vault] path];
    
    fileSize = (long)[[fileManager attributesOfItemAtPath:path error:nil] fileSize];
    return fileSize;
}


+(NSURL *)storeURL:(QredoUserCredentials *)userCredentials vault:(QredoVault*)vault{
    if (_storeUrl)return _storeUrl;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *subDirectory = @".qredo";
    
    //create directory
    NSURL *qredoDirectory = [documentsURL URLByAppendingPathComponent:subDirectory isDirectory:YES];
    
    BOOL isDir;
    
    if (![fileManager fileExistsAtPath:[qredoDirectory path] isDirectory:&isDir])
        if (![fileManager createDirectoryAtPath:[qredoDirectory path] withIntermediateDirectories:NO attributes:nil error:NULL])NSLog(@"Error: Create folder failed %@",qredoDirectory);
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    if (!bundleID || [bundleID isEqualToString:@""]){
        bundleID = @"com.qredo.sdk";
    }
    
    NSString *userPart = [userCredentials buildIndexName];
    NSString *vaultId = [vault.vaultId QUIDString];
    NSString *filename = [NSString stringWithFormat:@"%@.%@.%@.%@",bundleID,userPart,vaultId,@"QredoLocalIndex.sqlite"];
    
    NSURL *storeURL = [qredoDirectory URLByAppendingPathComponent:filename];
    _storeUrl = _storeUrl;
    
    return storeURL;
}


//+(void)renameStoreFrom:(QredoUserCredentials *)fromUserCredentials to:(QredoUserCredentials *)toUserCredentials {
//    NSURL *fromURL = [QredoLocalIndexDataStore storeURL:fromUserCredentials];
//    NSURL *toURL = [QredoLocalIndexDataStore storeURL:toUserCredentials];
//    
//    
//    //delete destination if it exists
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[toURL path]]){
//        [QredoLocalIndexDataStore deleteStore:toUserCredentials];
//    }
//    
//    NSError *error = nil;
//    
//    [[NSFileManager defaultManager] moveItemAtURL:fromURL toURL:toURL error:&error];
//    
//    if (error){
//        QredoLogError(@"Error renaming index during credentials change %@",error);
//    }
//}


//+(void)deleteStore:(QredoUserCredentials *)userCredentials {
//    NSError *error = nil;
//    
//    [[NSFileManager defaultManager] removeItemAtURL:[QredoLocalIndexDataStore storeURL:userCredentials] error:&error];
//    
//    if (error){
//        QredoLogError(@"Error deleting old index %@",error);
//    }
//}


-(void)buildStack:(QredoVault *)vault {
    //Model
    
    NSAssert([NSThread isMainThread],@"Metadata Index - Initialization must be on main thread");
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    //Persistent Store Coordinator
    NSPersistentStoreCoordinator *psc = nil;
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSAssert(psc,@"MetadataIndex: Failed to initialize NSPersistentStoreCoordinator");
    
    //Private ManagedObject Context
    NSManagedObjectContext *privateMoc = nil;
    privateMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateMoc setPersistentStoreCoordinator:psc];
    
    
    //Persistent Store
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
    options[NSInferMappingModelAutomaticallyOption] = @YES;
    options[NSSQLitePragmasOption] = @{ @"journal_mode":@"DELETE" };
    options[NSPersistentStoreFileProtectionKey] = NSFileProtectionComplete;
    
    NSURL *storeURL = [QredoLocalIndexDataStore storeURL:self.userCredentials vault:vault];
    
    NSError *error = nil;
    [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    NSAssert(psc,@"MetadataIndex: Failed to initialize NSPersistentStoreCoordinator: %@\n%@",[error localizedDescription],[error userInfo]);
    
    NSManagedObjectContext *moc = nil;
    moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [moc setParentContext:privateMoc];
    
    [self setPrivateContext:privateMoc];
    [self setManagedObjectContext:moc];
    
    
#if (TARGET_OS_SIMULATOR)
    NSLog(@"Store URL: %@",storeURL);
    NSLog(@"Model URL: %@",modelURL);
#endif
}



@end
