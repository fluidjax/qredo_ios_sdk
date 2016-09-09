/* HEADER GOES HERE */
#import "QredoPrimitiveMarshallers.h"
#import "QredoWireFormat.h"
#import "QredoMarshallable.h"
#import "QredoHelpers.h"

@implementation QredoPrimitiveMarshallers

+(QredoMarshaller)booleanMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeBoolean:element];
    };
}


+(QredoUnmarshaller)booleanUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readBoolean];
    };
}


+(QredoMarshaller)byteSequenceMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeByteSequence:element];
    };
}


+(QredoUnmarshaller)byteSequenceUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readByteSequence];
    };
}


+(QredoMarshaller)int32Marshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeInt32:element];
    };
}


+(QredoUnmarshaller)int32Unmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readInt32];
    };
}


+(QredoMarshaller)int64Marshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeInt64:element];
    };
}


+(QredoUnmarshaller)int64Unmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readInt64];
    };
}


+(QredoMarshaller)stringMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeString:element];
    };
}


+(QredoUnmarshaller)stringUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readString];
    };
}


+(QredoMarshaller)quidMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeQUID:element];
    };
}


+(QredoUnmarshaller)quidUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readQUID];
    };
}


+(QredoMarshaller)dateMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeDate:element];
    };
}


+(QredoUnmarshaller)dateUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readDate];
    };
}


+(QredoMarshaller)timeMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeTime:element];
    };
}


+(QredoUnmarshaller)timeUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readTime];
    };
}


+(QredoMarshaller)genericDateTimeMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeGenericDateTime:element];
    };
}


+(QredoUnmarshaller)genericDateTimeUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readGenericDateTime];
    };
}


+(QredoMarshaller)localDateTimeMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeLocalDateTime:element];
    };
}


+(QredoUnmarshaller)localDateTimeUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readLocalDateTime];
    };
}


+(QredoMarshaller)utcDateTimeMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        [writer writeUTCDateTime:element];
    };
}


+(QredoUnmarshaller)utcDateTimeUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        return [reader readUTCDateTime];
    };
}


+(QredoMarshaller)sequenceMarshallerWithElementMarshaller:(QredoMarshaller)elementMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        NSArray *sequence = element;
        [writer writeSequenceStart];
        [sequence enumerateObjectsUsingBlock:^void (id obj,NSUInteger idx,BOOL *stop) {
            elementMarshaller(obj,writer);
        }];
        [writer writeEnd];
    };
}


+(QredoUnmarshaller)sequenceUnmarshallerWithElementUnmarshaller:(QredoUnmarshaller)elementUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        [reader readSequenceStart];
        NSMutableArray *sequence = [NSMutableArray new];
        
        while (![reader atEnd])
            [sequence addObject:elementUnmarshaller(reader)];
        [reader readEnd];
        return sequence;
    };
}


+(QredoMarshaller)setMarshallerWithElementMarshaller:(QredoMarshaller)elementMarshaller {
    return ^(id element,QredoWireFormatWriter *writer) {
        NSArray *sequence = [[(NSSet *) element allObjects] sortedArrayUsingSelector:@selector(compare:)];
        [writer writeSetStart];
        [sequence enumerateObjectsUsingBlock:^void (id obj,NSUInteger idx,BOOL *stop) {
            elementMarshaller(obj,writer);
        }];
        [writer writeEnd];
    };
}


+(QredoUnmarshaller)setUnmarshallerWithElementUnmarshaller:(QredoUnmarshaller)elementUnmarshaller {
    return ^id (QredoWireFormatReader *reader) {
        [reader readSetStart];
        NSMutableSet *set = [NSMutableSet new];
        
        while (![reader atEnd])
            [set addObject:elementUnmarshaller(reader)];
        [reader readEnd];
        return set;
    };
}


+(NSData *)marshalObject:(id<QredoMarshallable>)object {
    return [self marshalObject:object includeHeader:YES];
}


+(NSData *)marshalObject:(id<QredoMarshallable>)object includeHeader:(BOOL)includeHeader;
{
    return [self marshalObject:object marshaller:[[object class] marshaller] includeHeader:includeHeader];
}

+(NSData *)marshalObject:(id)object marshaller:(QredoMarshaller)marshaller {
    return [self marshalObject:object marshaller:marshaller includeHeader:YES];
}


+(NSData *)marshalObject:(id)object marshaller:(QredoMarshaller)marshaller includeHeader:(BOOL)includeHeader {
    NSOutputStream *outputStream = [NSOutputStream outputStreamToMemory];
    
    [outputStream open];
    @try {
        QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:outputStream];
        
        if (includeHeader){
            [writer writeMessageHeader:[QredoMessageHeader messageHeaderWithProtocolVersion:[QredoVersion versionWithMajor:QREDO_MAJOR_PROTOCOL_VERSION
                                                                                                                     minor:QREDO_MINOR_PROTOCOL_VERSION
                                                                                                                     patch:QREDO_PATCH_PROTOCOL_VERSION]
                                                                             releaseVersion:[QredoVersion versionWithMajor:QREDO_MAJOR_RELEASE_VERSION
                                                                                                                     minor:QREDO_MINOR_RELEASE_VERSION
                                                                                                                     patch:QREDO_PATCH_RELEASE_VERSION]]];
        }
        
        marshaller(object,writer);
        
        if (includeHeader){
            [writer writeEnd];
        }
    } @finally {
        [outputStream close];
    }
    return [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}


+(id)unmarshalObject:(NSData *)data unmarshaller:(QredoUnmarshaller)unmarshaller {
    return [self unmarshalObject:data unmarshaller:unmarshaller parseHeader:YES];
}


+(id)unmarshalObject:(NSData *)data unmarshaller:(QredoUnmarshaller)unmarshaller parseHeader:(BOOL)parseHeader {
    NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
    
    [inputStream open];
    id object = nil;
    @try {
        QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:inputStream];
        
        if (parseHeader){
            [reader readMessageHeader];
        }
        
        object = unmarshaller(reader);
        
        if (parseHeader){
            [reader readEnd];
        }
    } @finally {
        [inputStream close];
    }
    return object;
}


@end