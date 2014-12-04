/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainTransporterConsts.h"

// TODO put the values from the design diagram

NSString *const QredoKeychainTransporterConversationType = @"com.qredo.keychain";
NSUInteger QredoKeychainTransporterRendezvousDuration = 600;

NSString *const QredoKeychainTransporterMessageTypeDeviceInfo = @"com.qredo.keychain.device-info";
NSString *const QredoKeychainTransporterMessageTypeKeychain = @"com.qredo.keychain.keychain";
NSString *const QredoKeychainTransporterMessageTypeConfirmReceiving = @"com.qredo.keychain.confirm";
NSString *const QredoKeychainTransporterMessageTypeCancelReceiving = @"com.qredo.keychain.cancel";
NSString *const QredoKeychainTransporterMessageKeyDeviceName = @"deviceName";
