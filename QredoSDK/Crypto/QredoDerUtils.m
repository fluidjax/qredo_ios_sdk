/* HEADER GOES HERE */

#import "QredoDerUtils.h"
#import "QredoLoggerPrivate.h"

@implementation QredoDerUtils

uint8_t rsaIdentifierArray[] = { 0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x01 };

+(NSData *)getRsaIdentifier {
    return [NSData dataWithBytes:rsaIdentifierArray length:sizeof(rsaIdentifierArray) / sizeof(uint8_t)];
}

+(BOOL)findOffsetOfDataWithExpectedTag:(uint8_t)expectedTag atOffset:(int)offset withinData:(NSData *)data offsetOfData:(int *)offsetOfData lengthOfData:(int *)lengthOfData {
    BOOL dataIsValid = YES;
    
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    if (!offsetOfData){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"OffsetOfData pointer argument is nil"]
                                     userInfo:nil];
    }
    
    if (!lengthOfData){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"LengthOfData pointer argument is nil"]
                                     userInfo:nil];
    }
    
    if (offset > data.length){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Offset exceeds length of data"]
                                     userInfo:nil];
    }
    
    const unsigned char *dataBytes = data.bytes;
    
    int lengthByteCount = 0;
    int length = 0;
    
    //Process the tag
    if (dataBytes[offset] != expectedTag){
        dataIsValid = NO;
    } else {
        //Move past the tag
        offset++;
        
        //Get the number of length bytes, and the length encoded in them
        if ([self getLengthOfData:data atOffset:offset lengthByteCount:&lengthByteCount length:&length]){
            //Length byte(s) appear valid, confirm data length is consistent (note, possible additional data present after this tag/data, so can't enforce absoulte length
            if ((offset + lengthByteCount + length) > data.length){
                dataIsValid = NO;
            } else {
                //Move past the length bytes to the start of the data
                offset += lengthByteCount;
            }
        }
    }
    
    if (dataIsValid){
        //Return the offset to where the data starts
        *offsetOfData = offset;
        *lengthOfData = length;
    }
    
    return dataIsValid;
}

+(BOOL)getLengthOfData:(NSData *)data atOffset:(int)offset lengthByteCount:(int *)lengthByteCount length:(int *)length {
    *lengthByteCount = 0;
    *length = 0;
    
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    if (!lengthByteCount){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"LengthByteCount pointer argument is nil"]
                                     userInfo:nil];
    }
    
    if (!length){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Length pointer argument is nil"]
                                     userInfo:nil];
    }
    
    if (offset > data.length){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Offset exceeds length of data"]
                                     userInfo:nil];
    }
    
    const unsigned char *dataBytes = data.bytes;
    
    /*
     * Check the first byte in the input data to determine how many bytes the
     * length is encoded on. If the first byte has its most significant bit set
     * then the remaining 7 bits contain the number of subsequent bytes.
     */
    if ((dataBytes[offset] & 0x80) == 0x80){
        //The least significant 7 bits contain the number of subsequent bytes
        *lengthByteCount = (unsigned char)((dataBytes[offset] & 0x7F) + 1);
        
        //Only cater for lengths in the range 1 - 65535 i.e. lengthSize <= 3
        if (*lengthByteCount > 3){
            QredoLogError(@"Length size (%d) exceeds currently supported length of 3 bytes.",*lengthByteCount);
            return NO;
        } else {
            if (*lengthByteCount == 2){
                //2 byte length. 1st byte is number of length bytes, 2nd byte is actual length of data
                *length = dataBytes[offset + 1] & 0x00FF;
            } else if (*lengthByteCount == 3){
                //3 byte length. 1st byte is number of length bytes, next 2 bytes are actual length of data
                *length = (((int)dataBytes[offset + 1] << 8) & 0xFF00) + dataBytes[offset + 2];
            }
        }
    } else {
        //The length is encoded on a single byte
        *lengthByteCount = 1;
        *length = dataBytes[offset] & 0x00FF;
    }
    
    return YES;
}

/// <summary>
/// Gets the length bytes to BER-TLV encode a particular length of data.
/// </summary>
/// <param name="dataLength">Length of the data.</param>
/// <returns>The length bytes, as an NSData, to encode the length of data provided.</returns>
+(NSData *)getLengthBytesForDataLength:(NSUInteger)dataLength {
    NSData *lengthBytes = nil;
    
    //Code only support 3 length bytes (which supports 65535 bytes of data)
    if (dataLength > 65535){
        NSString *message = [NSString stringWithFormat:@"Length of data (%lu) exceeds max value of 65535 bytes.",(unsigned long)dataLength];
        QredoLogError(@"%@",message);
        
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:message
                                     userInfo:nil];
    }
    
    if (dataLength <= 127){
        //Single byte length handles 0 to 127 bytes of outputLength
        unsigned char arrayLength = 1;
        unsigned char lengthBytesArray[arrayLength];
        lengthBytesArray[0] = (unsigned char)dataLength;
        
        lengthBytes = [[NSData alloc] initWithBytes:lengthBytesArray length:arrayLength];
    } else if (dataLength <= 255){
        //Double byte length handles 0 to 255 bytes of outputLength
        unsigned char arrayLength = 2;
        unsigned char lengthBytesArray[arrayLength];
        lengthBytesArray[0] = 0x81;
        lengthBytesArray[1] = (unsigned char)dataLength;
        
        lengthBytes = [[NSData alloc] initWithBytes:lengthBytesArray length:arrayLength];
    } else if (dataLength <= 65535){
        //Triple byte length handles 0 to 65535 bytes of outputLength
        unsigned char arrayLength = 3;
        unsigned char lengthBytesArray[arrayLength];
        lengthBytesArray[0] = 0x82;
        lengthBytesArray[1] = (unsigned char)((dataLength & 0xFF00) >> 8);
        lengthBytesArray[2] = (unsigned char)(dataLength & 0x00FF);
        
        lengthBytes = [[NSData alloc] initWithBytes:lengthBytesArray length:arrayLength];
    }
    
    return lengthBytes;
}

+(QredoAsn1ObjectIdentifier)getIdentifierFromData:(NSData *)objectIdentifierData {
    QredoAsn1ObjectIdentifier identifier = QredoAsn1ObjectIdentifierUnknown;
    
    NSData *rsaIdentifier = [self getRsaIdentifier];
    
    if ([objectIdentifierData isEqualToData:rsaIdentifier]){
        identifier = QredoAsn1ObjectIdentifierRsa;
    }
    
    return identifier;
}

+(NSData *)wrapData:(NSData *)data withTagData:(NSData *)tagData {
    //Providing nil data isn't an error (may want to wrap empty data)
    
    if (!tagData){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Tag Data argument is nil"]
                                     userInfo:nil];
    }
    
    NSMutableData *wrappedData = [[NSMutableData alloc] init];
    
    //Set the Tag
    [wrappedData appendData:tagData];
    
    //Set the Length (note, data could be nil)
    NSUInteger dataLength = 0;
    
    if (data){
        dataLength = data.length;
    }
    
    [wrappedData appendData:[self getLengthBytesForDataLength:dataLength]];
    
    //Set the Value
    [wrappedData appendData:data];
    
    return wrappedData;
}

+(NSData *)wrapData:(NSData *)data withTag:(uint8_t)tag {
    //Providing nil data isn't an error (may want to wrap empty data)
    
    return [self wrapData:data withTagData:[NSData dataWithBytes:&tag length:sizeof(tag)]];
}

+(NSData *)wrapByte:(uint8_t)byte withTag:(uint8_t)tag {
    return [self wrapData:[NSData dataWithBytes:&byte length:1] withTagData:[NSData dataWithBytes:&tag length:sizeof(tag)]];
}

+(NSData *)getObjectIdentifierDataForIdentifier:(QredoAsn1ObjectIdentifier)identifier {
    NSData *objectIdentifier = nil;
    
    switch (identifier){
        case QredoAsn1ObjectIdentifierRsa:
            objectIdentifier = [self getRsaIdentifier];
            break;
            
        default:
            QredoLogError(@"Unhandled identifier path. Value = %d",identifier);
            break;
    }
    
    return objectIdentifier;
}

@end
