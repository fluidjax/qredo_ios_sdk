/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>


extern NSString *QredoBase58ErrorDomain;

typedef NS_ENUM (NSUInteger,QredoBase58Error) {
    QredoBase58ErrorUnknown = 0,
    QredoBase58ErrorUnrecognizedSymbol,
};

@interface QredoBase58 :NSObject
+(NSString *)encodeData:(NSData *)data;
+(NSData *)decodeData:(NSString *)string error:(NSError **)error;
@end
