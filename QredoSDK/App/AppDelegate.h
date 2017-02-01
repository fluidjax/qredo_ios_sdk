//
//  AppDelegate.h
//  TestHost
//
//  Created by Christopher Morris on 22/02/2016.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@import UserNotifications;

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(void)saveContext;
-(NSURL *)applicationDocumentsDirectory;
-(void)registerForAPNTokenWithCompletion:(void (^)(NSError *error, NSData *token))completionHandler;

@end

