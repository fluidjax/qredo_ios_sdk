/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"
#import "QredoUserCredentials.h"

extern NSString *const QredoVaultItemTypeKeychain;
extern NSString *const QredoVaultItemTypeKeychainAttempt;
extern NSString *const QredoVaultItemSummaryKeyDeviceName;

@class QredoKeychainReceiver, QredoKeychainSender, QredoKeychain;

@interface QredoClient ()

- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;
- (QredoKeychain *)keychain;

- (void)createSystemVaultWithUserCredentials:(QredoUserCredentials*)userCredentials  completionHandler:(void(^)(NSError *error))completionHandler;
- (BOOL)saveStateWithError:(NSError **)error;
- (BOOL)deleteCurrentDataWithError:(NSError **)error;
@end

#endif
