//
//  QredoLocalIndexDataStore.m
//  QredoSDK
//
//  Created by Christopher Morris on 09/12/2015.
//
//

#import "QredoLocalIndexDataStore.h"
@import CoreData;

@interface QredoLocalIndexDataStore ()
@property (strong) NSManagedObjectContext *privateContext;
@end

@implementation QredoLocalIndexDataStore


+(id)sharedQredoLocalIndexDataStore{
    static QredoLocalIndexDataStore *sharedLocalIndexDataStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocalIndexDataStore = [[self alloc] init];
        
    });
    return sharedLocalIndexDataStore;
}


-(BOOL)save{
    __block BOOL success = NO;
    if (![[self privateContext] hasChanges] && ![[self managedObjectContext] hasChanges]) return YES;
    [[self managedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        NSAssert([[self managedObjectContext] save:&error], @"Failed to save main context: %@\n%@", [error localizedDescription], [error userInfo]);
        [[self privateContext] performBlock:^{
            NSError *privateError = nil;
            NSAssert([[self privateContext] save:&privateError], @"Error saving private context: %@\n%@", [privateError localizedDescription], [privateError userInfo]);
        }];
        if (error==nil)success=YES;
    }];
    return  success;
}


-(instancetype)init{
    self = [super init];
    if (self) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];

        
//        NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"QredoLocalIndex" withExtension:@"momd"];
        
//        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"separate_bundle" ofType:@"bundle"];
//        NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"QredoLocalIndex" withExtension:@"mom"];

        
        
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSAssert(mom, @"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        
        
        NSAssert(coordinator, @"Failed to initialize coordinator");
        
        self.managedObjectContext=[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
        [[self privateContext] setPersistentStoreCoordinator:coordinator];
        [self.managedObjectContext setParentContext:[self privateContext]];
        NSPersistentStoreCoordinator *psc = [[self privateContext] persistentStoreCoordinator];
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
        options[NSInferMappingModelAutomaticallyOption] = @YES;
        options[NSSQLitePragmasOption] = @{ @"journal_mode":@"DELETE" };
        options[NSPersistentStoreFileProtectionKey] = NSFileProtectionComplete;

        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"DataModel.sqlite"];
        
        NSError *error = nil;
        NSAssert([psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error], @"Error initializing PSC: %@\n%@", [error localizedDescription], [error userInfo]);
        
        NSLog(@"Store URL %@",storeURL);
        NSLog(@"Model URL %@",modelURL);
    }
    return self;
        
}



@end
