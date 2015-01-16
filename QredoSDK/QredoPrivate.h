/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"

extern NSString *const QredoVaultItemTypeKeychain;
extern NSString *const QredoVaultItemTypeKeychainAttempt;
extern NSString *const QredoVaultItemSummaryKeyDeviceName;

@class QredoKeychainReceiver, QredoKeychainSender, QredoKeychain;

@interface QredoClient ()

- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;

- (void)createSystemVaultWithCompletionHandler:(void(^)(NSError *error))completionHandler;
- (BOOL)saveStateWithError:(NSError **)error;

- (BOOL)setKeychain:(QredoKeychain *)keychain error:(NSError **)error;
- (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error;
- (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error;

+ (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error;
+ (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error;

@end


#endif
