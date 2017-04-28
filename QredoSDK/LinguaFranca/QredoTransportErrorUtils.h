/* HEADER GOES HERE */
#import "QredoTransport.h"

@interface QredoTransportErrorUtils :NSObject

+(NSString *)descriptionForErrorCode:(QredoTransportError)code;
+(NSError *)errorWithErrorCode:(QredoTransportError)code;
+(NSError *)errorWithErrorCode:(QredoTransportError)code description:(NSString *)description;

@end
