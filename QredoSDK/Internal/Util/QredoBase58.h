/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>


extern NSString *QredoBase58ErrorDomain;

typedef NS_ENUM(NSUInteger, QredoBase58Error) {
    QredoBase58ErrorUnknown = 0,
    QredoBase58ErrorUnrecognizedSymbol,
};

@interface QredoBase58 : NSObject
+ (NSString *)encodeData:(NSData *)data;
+ (NSData *)decodeData:(NSString *)string error:(NSError **)error;
@end
