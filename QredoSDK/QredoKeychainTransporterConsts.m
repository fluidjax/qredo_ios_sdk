/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainTransporterConsts.h"

// TODO put the values from the design diagram

NSString *const QredoKeychainTransporterConversationType = @"com.qredo.keychainrequest~";
NSUInteger QredoKeychainTransporterRendezvousDuration = 600;
NSInteger QredoKeychainTransporterFingerprintLength = 5;

NSString *const QredoKeychainTransporterMessageTypeDeviceInfo = @"com.qredo.keychain.device-name";
NSString *const QredoKeychainTransporterMessageTypeKeychain = @"com.qredo.keychain";
NSString *const QredoKeychainTransporterMessageTypeConfirmReceiving = @"com.qredo.keychain.received";
NSString *const QredoKeychainTransporterMessageTypeCancelReceiving = @"com.qredo.keychain.cancel";
NSString *const QredoKeychainTransporterMessageKeyDeviceName = @"device-name";
