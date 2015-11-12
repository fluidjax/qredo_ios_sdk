/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"
#import "QredoUserInitialization.h"

extern NSString *const QredoVaultItemTypeKeychain;
extern NSString *const QredoVaultItemTypeKeychainAttempt;
extern NSString *const QredoVaultItemSummaryKeyDeviceName;

@class QredoKeychainReceiver, QredoKeychainSender, QredoKeychain;

@interface QredoClient ()

- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;
- (QredoKeychain *)keychain;

- (void)createSystemVaultWithUserInitialization:(QredoUserInitialization*)userInitialization  completionHandler:(void(^)(NSError *error))completionHandler;
- (BOOL)saveStateWithError:(NSError **)error;

+ (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error;

- (BOOL)deleteCurrentDataWithError:(NSError **)error;
@end


#endif
