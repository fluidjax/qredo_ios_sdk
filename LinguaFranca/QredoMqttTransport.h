/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoTransport.h"

@interface QredoMqttTransport : QredoTransport

@property (readonly, assign) BOOL connectedAndReady;

@end
