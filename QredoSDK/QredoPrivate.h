/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"

@class QredoKeychainReceiver, QredoKeychainSender;

@interface QredoClient ()


// TODO: Find a better way of keaping in memory the keychainReceiver and keychainSender,
// while sending and receiving the keychain.
@property (nonatomic) QredoKeychainReceiver *keychainReceiver;
@property (nonatomic) QredoKeychainSender *keychainSender;

- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;

- (NSData *)keychainData;

@end

#endif
