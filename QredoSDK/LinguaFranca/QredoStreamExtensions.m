#import "QredoStreamExtensions.h"

@implementation NSInputStream (QredoReaderExtensions)

- (NSData *)readUntilByte:(uint8_t)delimiter {
    
    NSMutableData *buffer = [NSMutableData new];
    uint8_t nextByte;
    NSInteger result;
    while (((result = [self read:&nextByte maxLength:1]) > 0) &&
           (nextByte != delimiter)) {
        [buffer appendBytes:&nextByte length:1];
    }
    if (result == 0) {
        return nil;
    } else if (result == -1) {
        return nil;
    }
    // HACK: add null terminator
    [buffer appendBytes:"" length:1];
    return [buffer copy];
    
}

- (NSData *)readExactLength:(NSUInteger)length {
    
    // Allocate a C-style buffer.
    uint8_t *bytes = calloc(length, sizeof(uint8_t));
    // Read from the stream into this buffer.
    NSInteger bytesRead = [self read:bytes maxLength:length];
    // Now turn it into something objective-c friendly.
    NSData *data = [NSData dataWithBytes:bytes length:length];
    // Clean up the C-style buffer.
    free(bytes);
    // Handle the case where we don’t read what was expected.
    if (bytesRead < length) {
        return nil;
    }
    return data;
    
}

@end

@implementation NSOutputStream (QredoWriterExtensions)

- (void)writeByte:(uint8_t)byte {
    uint8_t buf[1];
    buf[0] = byte;
    long bytesWritten = [self write:buf maxLength:1];
    if (bytesWritten != 1) {
        @throw [NSException exceptionWithName:@"QredoCouldntWriteByteException"
                                       reason:[NSString stringWithFormat:@"Tried to write 1 byte to stream, but got a return of %ld.", bytesWritten]
                                     userInfo:nil];
    }
}

@end