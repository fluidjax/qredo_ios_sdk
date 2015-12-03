//
//  QredoLocalIndex.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//
//
#import "Qredo.h"


#import "QredoIndexSummaryValues.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexVaultItemMetadata.h"


@import CoreData;


@interface QredoLocalIndex ()
@property (readwrite) NSManagedObjectContext *managedObjectContext;
@property NSManagedObjectContext *privateContext;

@end

@implementation QredoLocalIndex



+(id)sharedQredoLocalIndex {
    static QredoLocalIndex *sharedLocalIndex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocalIndex = [[self alloc] init];
        [sharedLocalIndex initializeCoreData];
    });
    return sharedLocalIndex;
}



//+(id)sharedQredoLocalIndexTEST:(NSURL*)url {
//    static QredoLocalIndex *sharedLocalIndex = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        sharedLocalIndex = [[self alloc] init];
//        [sharedLocalIndex initializeCoreDataWithURL:url];
//    });
//    return sharedLocalIndex;
//}


//- (void)initializeCoreDataWithURL:(NSURL*)url{
//    
//    
//    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//    NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];
//    
//    if ([self managedObjectContext]) return;
//    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
//    NSAssert(mom, @"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
//    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
//    NSAssert(coordinator, @"Failed to initialize coordinator");
//    [self setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]];
//    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
//    [[self privateContext] setPersistentStoreCoordinator:coordinator];
//    [[self managedObjectContext] setParentContext:[self privateContext]];
//
//}


- (void)initializeCoreData{
    if ([self managedObjectContext]) return;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];

    
    //    NSManagedObjectModel *mom = [NSManagedObjectModel  mergedModelFromBundles:nil];
    
//        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//        NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    
    NSAssert(mom, @"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSAssert(coordinator, @"Failed to initialize coordinator");
    [self setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]];
    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
    [[self privateContext] setPersistentStoreCoordinator:coordinator];
    [[self managedObjectContext] setParentContext:[self privateContext]];
    
   
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
}


+ (BOOL)areWeBeingUnitTested {
    BOOL answer = NO;
    Class testProbeClass;
#if GTM_USING_XCTEST // you may need to change this to reflect which framework are you using
    testProbeClass = NSClassFromString(@"XCTestProbe");
#else
    testProbeClass = NSClassFromString(@"SenTestProbe");
#endif
    if (testProbeClass != Nil) {
        // Doing this little dance so we don't actually have to link
        // SenTestingKit in
        SEL selector = NSSelectorFromString(@"isTesting");
        NSMethodSignature *sig = [testProbeClass methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:testProbeClass];
        [invocation getReturnValue:&answer];
    }
    return answer;
}


-(void)putItem:(QredoVaultItem *)vaultItem{
}


-(void)putItemWithMetadata:(QredoVaultItemMetadata *)metadata{
    [self.managedObjectContext performBlockAndWait:^{
        [QredoIndexVaultItemMetadata createOrUpdateWith:metadata inManageObjectContext:self.managedObjectContext];
    }];

}


-(QredoVaultItemMetadata *)get:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    __block QredoVaultItemMetadata* retrievedMetadata = nil;
    [self.managedObjectContext performBlockAndWait:^{
        retrievedMetadata = [QredoIndexVaultItemMetadata get:vaultItemDescriptor inManageObjectContext:self.managedObjectContext];
        
    }];
    return retrievedMetadata;
}


-(void)delete:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    
}


-(void)find:(NSPredicate *)predicate withBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler{
    
}


@end
