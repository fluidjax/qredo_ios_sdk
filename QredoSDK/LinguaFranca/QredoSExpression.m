/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoSExpression.h"

#pragma mark - Qredo S-expression reader implementation




@interface QredoSExpressionReader ()
@property (readwrite) QredoToken lastToken;
@property (readwrite) QredoAtom *lastAtom;
@property (readwrite) NSInputStream *inputStream;
@end


@implementation QredoSExpressionReader
{
    uint8_t _lookAhead;
}

+(instancetype)sexpressionReaderForInputStream:(NSInputStream *)inputStream {
    return [[self alloc] initWithInputStream:inputStream];
}


-(instancetype)initWithInputStream:(NSInputStream *)inputStream {
    self = [super init];
    if (self){
        _lookAhead   = 0;
        _inputStream = inputStream;
    }
    return self;
}


-(bool)isExhausted {
    return ![self.inputStream hasBytesAvailable];
}


-(QredoToken)lookAhead {
    if (![self.inputStream hasBytesAvailable]){
        return QredoTokenEnd;
    } else {
        [self.inputStream read:&_lookAhead maxLength:1];
        switch (_lookAhead){
            case '(':
                return QredoTokenLParen;
                
            case ')':
                return QredoTokenRParen;
                
            default:
                return QredoTokenAtom;
        }
    }
}


-(QredoAtom *)readAtom {
    if (_lookAhead != 0){
        if (![self.inputStream hasBytesAvailable]){
            self.lastToken = QredoTokenEnd;
            @throw [NSException exceptionWithName:@"QredoEOFException"
                                           reason:@"Expected atom, but got EOF."
                                         userInfo:nil];
        }
    }
    
    //get and parse size
    NSData *sizeBytes = [self.inputStream readUntilByte:':'];
    
    if (sizeBytes == nil){
        self.lastToken = QredoTokenEnd;
        @throw [NSException exceptionWithName:@"QredoEOFException"
                                       reason:@"Expected atom size, but got EOF."
                                     userInfo:nil];
    }
    
    //glue the lookahead token at the beginning, if it exists
    NSMutableData *newBytes;
    
    if (_lookAhead != 0){
        newBytes = [NSMutableData dataWithBytes:&_lookAhead length:1];
        [newBytes appendData:sizeBytes];
    } else {
        newBytes = [sizeBytes mutableCopy];
    }
    
    NSInteger length = [[NSString stringWithUTF8String:newBytes.bytes] integerValue];
    
    //now read the given data size
    NSData *data = [self.inputStream readExactLength:length];
    
    //finally return the data
    self.lastToken = QredoTokenAtom;
    self.lastAtom  = data;
    
    return data;
}


-(void)readLeftParen {
    switch (_lookAhead){
        case '(':
            _lookAhead = 0;
            break;
            
        case 0:
            [self expectByte:'('];
            break;
            
        default:
            @throw [NSException exceptionWithName:@"QredoExpectedLeftParen"
                                           reason:[NSString stringWithFormat:@"Expected LPAREN, but got '%c'.",_lookAhead]
                                         userInfo:nil];
    }
    self.lastToken = QredoTokenLParen;
}


-(void)readRightParen {
    switch (_lookAhead){
        case ')':
            _lookAhead = 0;
            break;
            
        case 0:
            [self expectByte:')'];
            break;
            
        default:
            @throw [NSException exceptionWithName:@"QredoExpectedRightParen"
                                           reason:[NSString stringWithFormat:@"Expected RPAREN, but got '%c'.",_lookAhead]
                                         userInfo:nil];
    }
    self.lastToken = QredoTokenRParen;
}


-(void)expectByte:(uint8_t)expectedByte {
    uint8_t inputByte;
    NSInteger bytesRead = [self.inputStream read:&inputByte maxLength:1];
    
    if (bytesRead != 1){
        self.lastToken = QredoTokenEnd;
        @throw [NSException exceptionWithName:@"QredoUnexpectedTokenException"
                                       reason:[NSString stringWithFormat:@"Expected 1 byte, got %d.",(unsigned int)bytesRead]
                                     userInfo:nil];
    }
    
    if (inputByte != expectedByte){
        @throw [NSException exceptionWithName:@"QredoUnexpectedTokenException"
                                       reason:[NSString stringWithFormat:@"Expected byte '%c' (0x%02X), got '%c' (0x%02X). Bytes read = %lu.",expectedByte,expectedByte,inputByte,inputByte,(unsigned long)bytesRead]
                                     userInfo:nil];
    }
}


@end

#pragma mark - Qredo S-expression writer implementation

@implementation QredoSExpressionWriter

+(instancetype)sexpressionWriterForOutputStream:(NSOutputStream *)outputStream {
    return [[self alloc] initWithOutputStream:outputStream];
}


-(instancetype)initWithOutputStream:(NSOutputStream *)outputStream {
    self = [super init];
    if (self){
        _outputStream = outputStream;
    }
    return self;
}


-(void)writeAtom:(NSData *)atom {
    //This nasty code turns a data length into a non-null-terminated ASCII string.
    NSString *lengthString = [NSString stringWithFormat:@"%d",(unsigned int)[atom length]];
    const char *lengthCString = [lengthString cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *lengthBytes = [NSData dataWithBytes:lengthCString length:[lengthString length]];
    
    [self.outputStream write:lengthBytes.bytes maxLength:[lengthBytes length]];
    [self.outputStream writeByte:':'];
    [self.outputStream write:(uint8_t *)atom.bytes maxLength:[atom length]];
}


-(void)writeLeftParen {
    [self.outputStream writeByte:'('];
}


-(void)writeRightParen {
    [self.outputStream writeByte:')'];
}


@end
