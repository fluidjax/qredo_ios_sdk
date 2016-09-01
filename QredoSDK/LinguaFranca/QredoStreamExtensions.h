/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import <stdint.h>

@interface NSInputStream (QredoReaderExtensions)

- (NSData *)readUntilByte:(uint8_t)delimiter;
- (NSData *)readExactLength:(NSUInteger)length;

@end

@interface NSOutputStream (QredoWriterExtensions)

- (void)writeByte:(uint8_t)byte;

@end
