/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"

extern NSTimeInterval qtu_defaultTimeout;

@interface NSData (QredoTestUtils)

+ (NSData*)qtu_dataWithRandomBytesOfLength:(int)length;

@end

@interface QredoClientOptions(QredoTestUtils)

+ (instancetype)qtu_clientOptionsWithResetData:(BOOL)resetData;

+ (instancetype)qtu_clientOptionsWithTransportType:(QredoClientOptionsTransportType)transportType
                                         resetData:(BOOL)resetData;

@end

