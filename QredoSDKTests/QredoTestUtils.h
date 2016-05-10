/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoPrivate.h"

extern NSTimeInterval qtu_defaultTimeout;

extern NSString *k_APPID;
extern NSString *k_APPSECRET;
extern NSString *k_USERID;


@interface NSData (QredoTestUtils)

+ (NSData*)qtu_dataWithRandomBytesOfLength:(int)length;

@end

@interface QredoClientOptions(QredoTestUtils)

+ (instancetype)qtu_clientOptionsWithResetData:(BOOL)resetData;

+ (instancetype)qtu_clientOptionsWithTransportType:(QredoClientOptionsTransportType)transportType
                                         resetData:(BOOL)resetData;


@end



