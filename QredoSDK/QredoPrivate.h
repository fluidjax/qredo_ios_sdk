/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
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





typedef NS_ENUM (NSUInteger, QredoClientOptionsTransportType) {
    QredoClientOptionsTransportTypeHTTP,
    QredoClientOptionsTransportTypeMQTT,
    QredoClientOptionsTransportTypeWebSockets,
};

extern NSString *const QredoClientOptionServiceURL;
extern NSString *const QredoRendezvousURIProtocol;
extern NSString *const QredoVaultItemTypeKeychain;
extern NSString *const QredoVaultItemTypeKeychainAttempt;
extern NSString *const QredoVaultItemSummaryKeyDeviceName;
static long long QREDO_DEFAULT_INDEX_CACHE_SIZE = 250000000; //in bytes 250Meg

@class QredoKeychainReceiver, QredoKeychainSender, QredoKeychain;



@interface QredoClientOptions :NSObject

@property (nonatomic) QredoClientOptionsTransportType transportType;
@property BOOL resetData;
@property BOOL disableMetadataIndex;


-(instancetype)initWithDefaultTrustedRoots;
-(instancetype)initDefaultPinnnedCertificate;
-(instancetype)initWithPinnedCertificate:(QredoCertificate *)certificate;

@end

@interface QredoClient ()


+(void)initializeWithAppSecret:(NSString*)appSecret
                        userId:(NSString*)userId
                    userSecret:(NSString*)userSecret
                       options:(QredoClientOptions*)options
             completionHandler:(void (^)(QredoClient *client, NSError *error))completionHandler;



- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;
- (QredoKeychain *)keychain;

- (void)createSystemVaultWithUserCredentials:(QredoUserCredentials*)userCredentials  completionHandler:(void(^)(NSError *error))completionHandler;
- (BOOL)saveStateWithError:(NSError **)error;
- (BOOL)deleteCurrentDataWithError:(NSError **)error;
@end

#endif
