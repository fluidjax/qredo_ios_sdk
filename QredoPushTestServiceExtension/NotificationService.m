//
//  NotificationService.m
//  QredoPushTestServiceExtension
//
//  Created by Christopher Morris on 08/02/2017.
//
//

#import "NotificationService.h"
#import "MasterConfig.h"
#import "Qredo.h"
#import "QredoPrivate.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *modifiedContent;

@end

@implementation NotificationService



-(QredoClientOptions*)configureClientOptions{
    QredoClientOptions *options = [[QredoClientOptions alloc] init];
    options.serverURL   = TEST_SERVER_URL;
    options.pushToken   = nil;
    options.appGroup    = TEST_APP_GROUP;
    options.keyChainGroup = TEST_KEYCHAIN_GROUP;
    return options;
}




- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.modifiedContent = [request.content mutableCopy];
    
    //constants set in MasterConfig.h
    //NSUserDefaults *userDefaults;
    //NSDictionary *queueIDConversationLookup;
    
    //fails
//    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"9W2U485A5G.group.com.qredo.ChrisPush1"];
//    NSDictionary *queueIDConversationLookup = [userDefaults objectForKey:@"ConversationQueueIDLookup"];
//    NSLog(@"1: %@", queueIDConversationLookup);
   
    
//    //this one Works!!!
//    userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.qredo.ChrisPush1"];
//    queueIDConversationLookup = [userDefaults objectForKey:@"ConversationQueueIDLookup"];
//    NSLog(@"2: %@", queueIDConversationLookup);
    
    //fails
//    userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.qredo.ChrisPush1"];
//    queueIDConversationLookup = [userDefaults objectForKey:@"ConversationQueueIDLookup"];
//    NSLog(@"3: %@", queueIDConversationLookup);
    
    
    
    [QredoClient initializeWithAppId:TEST_SERVER_APPID
                           appSecret:TEST_SERVER_APPSECRET
                              userId:TEST_SERVER_USERID
                          userSecret:TEST_SERVER_USERSECRET
                             options:[self configureClientOptions]
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       
                       
                       NSLog(@"QREDO: System Vault is %@", clientArg.systemVault.vaultId);
                       
                       [QredoPushMessage initializeWithRemoteNotification:request.content.userInfo
                                                              qredoClient:clientArg completionHandler:^(QredoPushMessage *pushMessage, NSError *error) {
                           if (error){
                               NSLog(@"QREDO: Error- %@ building Push Message %@", error, pushMessage);
                           }else{
                               //Successfully parsed incoming Push Message
                               self.modifiedContent.title = pushMessage.alert;
                               self.modifiedContent.body  = pushMessage.incomingMessageText;
                           }
                           NSLog(@"QREDO: Push Complete %@",pushMessage);
                           contentHandler(self.modifiedContent);
                       }];
      }];
}




- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.modifiedContent);
}

@end
