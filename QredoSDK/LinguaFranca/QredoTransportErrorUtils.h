/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTransport.h"

@interface QredoTransportErrorUtils : NSObject

+ (NSString *)descriptionForErrorCode:(QredoTransportError)code;
+ (NSError *)errorWithErrorCode:(QredoTransportError)code;
+ (NSError *)errorWithErrorCode:(QredoTransportError)code description:(NSString*)description;

@end