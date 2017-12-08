/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoTransport.h"

@interface QredoTransportErrorUtils :NSObject

+(NSString *)descriptionForErrorCode:(QredoTransportError)code;
+(NSError *)errorWithErrorCode:(QredoTransportError)code;
+(NSError *)errorWithErrorCode:(QredoTransportError)code description:(NSString *)description;

@end
