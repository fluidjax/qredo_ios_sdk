/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoWireFormat.h"

typedef void(^QredoMarshaller)(id element, QredoWireFormatWriter *writer);
typedef id(^QredoUnmarshaller)(QredoWireFormatReader *reader);

@protocol QredoMarshallable;

@interface QredoPrimitiveMarshallers : NSObject

+ (QredoMarshaller)booleanMarshaller;
+ (QredoUnmarshaller)booleanUnmarshaller;
+ (QredoMarshaller)byteSequenceMarshaller;
+ (QredoUnmarshaller)byteSequenceUnmarshaller;
+ (QredoMarshaller)int32Marshaller;
+ (QredoUnmarshaller)int32Unmarshaller;
+ (QredoMarshaller)int64Marshaller;
+ (QredoUnmarshaller)int64Unmarshaller;
+ (QredoMarshaller)stringMarshaller;
+ (QredoUnmarshaller)stringUnmarshaller;
+ (QredoMarshaller)quidMarshaller;
+ (QredoUnmarshaller)quidUnmarshaller;
+ (QredoMarshaller)dateMarshaller;
+ (QredoUnmarshaller)dateUnmarshaller;
+ (QredoMarshaller)timeMarshaller;
+ (QredoUnmarshaller)timeUnmarshaller;
+ (QredoMarshaller)genericDateTimeMarshaller;
+ (QredoUnmarshaller)genericDateTimeUnmarshaller;
+ (QredoMarshaller)localDateTimeMarshaller;
+ (QredoUnmarshaller)localDateTimeUnmarshaller;
+ (QredoMarshaller)utcDateTimeMarshaller;
+ (QredoUnmarshaller)utcDateTimeUnmarshaller;

+ (QredoMarshaller)sequenceMarshallerWithElementMarshaller:(QredoMarshaller)elementMarshaller;
+ (QredoUnmarshaller)sequenceUnmarshallerWithElementUnmarshaller:(QredoUnmarshaller)elementUnmarshaller;
+ (QredoMarshaller)setMarshallerWithElementMarshaller:(QredoMarshaller)elementMarshaller;
+ (QredoUnmarshaller)setUnmarshallerWithElementUnmarshaller:(QredoUnmarshaller)elementUnmarshaller;

// includes header by default
+ (NSData *)marshalObject:(id<QredoMarshallable>)object;
+ (NSData *)marshalObject:(id<QredoMarshallable>)object includeHeader:(BOOL)includeHeader;
+ (NSData *)marshalObject:(id)object marshaller:(QredoMarshaller)marshaller;
+ (NSData *)marshalObject:(id)object marshaller:(QredoMarshaller)marshaller includeHeader:(BOOL)includeHeader;
+ (id)unmarshalObject:(NSData *)data unmarshaller:(QredoUnmarshaller)unmarshaller;
+ (id)unmarshalObject:(NSData *)data unmarshaller:(QredoUnmarshaller)unmarshaller parseHeader:(BOOL)parseHeader;

@end