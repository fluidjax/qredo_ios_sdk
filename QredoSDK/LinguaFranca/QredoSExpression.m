#import "QredoSExpression.h"

#pragma mark - Qredo S-expression reader implementation

@implementation QredoSExpressionReader
{
    uint8_t _lookAhead;
}

+ (instancetype)sexpressionReaderForInputStream:(NSInputStream *)inputStream {
    return [[self alloc] initWithInputStream:inputStream];
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream {
    self = [super init];
    _lookAhead   = 0;
    _inputStream = inputStream;
    return self;
}

- (bool)isExhausted {
    return ![_inputStream hasBytesAvailable];
}

- (QredoToken)lookAhead {
    if (![_inputStream hasBytesAvailable]) {
        return QredoTokenEnd;
    } else {
        [_inputStream read:&_lookAhead maxLength:1];
        switch (_lookAhead) {
            case '(':
                return QredoTokenLParen;
            case ')':
                return QredoTokenRParen;
            default:
                return QredoTokenAtom;
        }
    }
}

- (QredoAtom *)readAtom {
    
    if (_lookAhead != 0) {
        if (![_inputStream hasBytesAvailable]) {
            _lastToken = QredoTokenEnd;
            @throw [NSException exceptionWithName:@"QredoEOFException"
                                           reason:@"Expected atom, but got EOF."
                                         userInfo:nil];
        }
    }
    
    // get and parse size
    NSData *sizeBytes = [_inputStream readUntilByte:':'];
    if (sizeBytes == nil) {
        _lastToken = QredoTokenEnd;
        @throw [NSException exceptionWithName:@"QredoEOFException"
                                       reason:@"Expected atom size, but got EOF."
                                     userInfo:nil];
    }
    
    // glue the lookahead token at the beginning, if it exists
    NSMutableData *newBytes;
    if (_lookAhead != 0) {
        newBytes = [NSMutableData dataWithBytes:&_lookAhead length:1];
        [newBytes appendData:sizeBytes];
    } else {
        newBytes = [sizeBytes mutableCopy];
    }
    NSInteger length = [[NSString stringWithUTF8String:[newBytes bytes]] integerValue];
    
    // now read the given data size
    NSData *data = [_inputStream readExactLength:length];
    
    // finally return the data
    _lastToken = QredoTokenAtom;
    _lastAtom  = data;
    
    return data;
    
}

- (void)readLeftParen {
    switch (_lookAhead) {
        case '(':
            _lookAhead = 0;
            break;
        case 0:
            [self expectByte:'('];
            break;
        default:
            @throw [NSException exceptionWithName:@"QredoExpectedLeftParen"
                                           reason:[NSString stringWithFormat:@"Expected LPAREN, but got '%c'.", _lookAhead]
                                         userInfo:nil];
    }
    _lastToken = QredoTokenLParen;
}

- (void)readRightParen {
    switch (_lookAhead) {
        case ')':
            _lookAhead = 0;
            break;
        case 0:
            [self expectByte:')'];
            break;
        default:
            @throw [NSException exceptionWithName:@"QredoExpectedRightParen"
                                           reason:[NSString stringWithFormat:@"Expected RPAREN, but got '%c'.", _lookAhead]
                                         userInfo:nil];
    }
    _lastToken = QredoTokenRParen;
}

- (void)expectByte:(uint8_t)expectedByte {
    uint8_t inputByte;
    NSInteger bytesRead = [_inputStream read:&inputByte maxLength:1];
    if (bytesRead != 1) {
        _lastToken = QredoTokenEnd;
        @throw [NSException exceptionWithName:@"QredoUnexpectedTokenException"
                                       reason:[NSString stringWithFormat:@"Expected 1 byte, got %d.", (unsigned int)bytesRead]
                                     userInfo:nil];
    }
    if (inputByte != expectedByte) {
        @throw [NSException exceptionWithName:@"QredoUnexpectedTokenException"
                                       reason:[NSString stringWithFormat:@"Expected byte '%c' (0x%02X), got '%c' (0x%02X). Bytes read = %lu.", expectedByte, expectedByte, inputByte, inputByte, (unsigned long)bytesRead]
                                     userInfo:nil];
    }
}

@end

#pragma mark - Qredo S-expression writer implementation

@implementation QredoSExpressionWriter

+ (instancetype)sexpressionWriterForOutputStream:(NSOutputStream *)outputStream {
    return [[self alloc] initWithOutputStream:outputStream];
}

- (instancetype)initWithOutputStream:(NSOutputStream *)outputStream {
    self = [super init];
    _outputStream = outputStream;
    return self;
}

- (void)writeAtom:(NSData *)atom {
    // This nasty code turns a data length into a non-null-terminated ASCII string.
    NSString *lengthString = [NSString stringWithFormat:@"%d", (unsigned int)[atom length]];
    const char *lengthCString = [lengthString cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *lengthBytes = [NSData dataWithBytes:lengthCString length:[lengthString length]];
    [_outputStream write:[lengthBytes bytes] maxLength:[lengthBytes length]];
    [_outputStream writeByte:':'];
    [_outputStream write:(uint8_t *)[atom bytes] maxLength:[atom length]];
}

- (void)writeLeftParen {
    [_outputStream writeByte:'('];
}

- (void)writeRightParen {
    [_outputStream writeByte:')'];
}

@end
