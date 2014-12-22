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


// TODO: Find a better way of keaping in memory the keychainReceiver and keychainSender,
// while sending and receiving the keychain.
@property (nonatomic) QredoKeychainReceiver *keychainReceiver;
@property (nonatomic) QredoKeychainSender *keychainSender;

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

@interface QredoClient (KeychainTransporter)

- (void)sendKeychainWithCompletionHandler:(void(^)(NSError *error))completionHandler;
- (void)receiveKeychainWithCompletionHandler:(void(^)(NSError *error))completionHandler;
- (void)deleteKeychainWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@end

#endif
