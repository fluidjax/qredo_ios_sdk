/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoPrimitiveMarshallers.h"

@protocol QredoMarshallable <NSObject>

+(QredoMarshaller)marshaller;
+(QredoUnmarshaller)unmarshaller;

@end
