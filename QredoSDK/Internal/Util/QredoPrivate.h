/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"
#import "QredoUserCredentials.h"
#import "QredoTypesPrivate.h"
#import "QredoVaultPrivate.h"
#import "QredoLoggerPrivate.h"
#import "QredoRendezvousPrivate.h"
#import "QredoConversationMessagePrivate.h"
#import "QredoConversationPrivate.h"


extern NSString *const QredoClientOptionServiceURL;
extern NSString *const QredoRendezvousURIProtocol;
extern NSString *const QredoVaultItemTypeKeychain;
extern NSString *const QredoVaultItemTypeKeychainAttempt;
extern NSString *const QredoVaultItemSummaryKeyDeviceName;
static long long QREDO_DEFAULT_INDEX_CACHE_SIZE = 250000000; //in bytes 250Meg
static NSString* _testAppSecret = nil;

@class QredoKeychainReceiver,QredoKeychainSender,QredoKeychain;

@interface QredoClient ()

-(QredoServiceInvoker *)serviceInvoker;
-(QredoVault *)systemVault;
-(QredoUserCredentials *)userCredentials;
-(QredoAppCredentials *)appCredentials;
+(NSDictionary*)retrieveCredentialsUserDefaultsAppGroup:(NSString*)appGroup;
-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                               duration:(long)duration
                     unlimitedResponses:(BOOL)unlimitedResponses
                          summaryValues:summaryValues
                      completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler;
-(void)createSystemVaultWithUserCredentials:(QredoUserCredentials *)userCredentials completionHandler:(void (^)(NSError *error))completionHandler;
-(BOOL)saveStateWithError:(NSError **)error;
-(BOOL)deleteCurrentDataWithError:(NSError **)error;

@end

#endif //ifndef QredoSDK_QredoPrivate_h
