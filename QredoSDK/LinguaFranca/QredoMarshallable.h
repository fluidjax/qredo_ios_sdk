/* HEADER GOES HERE */
#import "QredoPrimitiveMarshallers.h"

@protocol QredoMarshallable <NSObject>

+(QredoMarshaller)marshaller;
+(QredoUnmarshaller)unmarshaller;

@end
