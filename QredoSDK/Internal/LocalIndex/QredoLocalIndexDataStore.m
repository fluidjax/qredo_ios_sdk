//
//  QredoLocalIndexDataStore.m
//  QredoSDK
//
//  Created by Christopher Morris on 09/12/2015.
//  A singleton that handles the Coredata LocalIndex initialization and persisentent store.
//
//

#import "QredoLocalIndexDataStore.h"
@import CoreData;

@interface QredoLocalIndexDataStore ()
@property (strong) NSManagedObjectContext *privateContext;
@end

@implementation QredoLocalIndexDataStore


+(id)sharedQredoLocalIndexDataStore {
	static QredoLocalIndexDataStore *sharedLocalIndexDataStore = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedLocalIndexDataStore = [[self alloc] init];

	});
	return sharedLocalIndexDataStore;
}


-(void)saveContext:(BOOL)wait {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObjectContext *privateContext = [self privateContext];
	if (!moc) return;
	if ([moc hasChanges]) {
		[moc performBlockAndWait:^{
		         NSError *error = nil;
		         [moc save:&error];
		         NSAssert(error==nil, @"MetadataIndex: Error saving MOC :%@\n%@",[error localizedDescription],[error userInfo]);
		 }];
	}

	void (^savePrivate) (void) = ^{
		NSError *error = nil;
		NSAssert([privateContext save:&error], @"MetadataIndex: Error saving Private MOC :%@\n%@",[error localizedDescription],[error userInfo]);
	};

	if ([privateContext hasChanges]) {
		if (wait) {
			[privateContext performBlockAndWait:savePrivate];
		}else{
			[privateContext performBlock:savePrivate];
		}
	}
}


-(instancetype)init {
	self = [super init];
	if (self) {
		//Model
		NSAssert([NSThread isMainThread], @"Metadata Index - Initialization must be on main thread");

		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];
		NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

		//Persistent Store Coordinator
		NSPersistentStoreCoordinator *psc = nil;
		psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
		NSAssert(psc, @"MetadataIndex: Failed to initialize NSPersistentStoreCoordinator");

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

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"QredoLocalIndex.sqlite"];
		NSError *error = nil;
		[psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
		NSAssert(psc,@"MetadataIndex: Failed to initialize NSPersistentStoreCoordinator: %@\n%@", [error localizedDescription], [error userInfo]);

		NSManagedObjectContext *moc = nil;
		moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[moc setParentContext:privateMoc];

		[self setPrivateContext:privateMoc];
		[self setManagedObjectContext:moc];

		//NSLog(@"Store URL %@",storeURL);
		//NSLog(@"Model URL %@",modelURL);
	}
	return self;
}


@end
