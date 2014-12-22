/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"

static NSString *const QredoVaultItemTypeKeychain = @"com.qredo.keychain.device-name";
static NSString *const QredoVaultItemTypeKeychainAttempt = @"com.qredo.keychain.transfer-attempt";
static NSString *const QredoVaultItemSummaryKeyDeviceName = @"device-name";

@class QredoKeychainReceiver, QredoKeychainSender, QredoKeychain;

@interface QredoClient ()

- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;

- (void)createSystemVault;
- (BOOL)saveStateWithError:(NSError **)error;

- (BOOL)setKeychain:(QredoKeychain *)keychain error:(NSError **)error;
- (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error;
- (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error;

+ (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error;
+ (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error;

@end


#endif
