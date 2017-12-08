/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoSExpression.h"
#import "QredoWireFormat.h"
#import "NSData+HexTools.h"
#import <CoreFoundation/CoreFoundation.h>

#pragma mark - Qredo marked atom implementation

@implementation QredoMarkedAtom

+(instancetype)markedAtomWithAtom:(QredoAtom *)atom {
    return [[QredoMarkedAtom alloc] initWithAtom:atom];
}


+(instancetype)markedAtomWithBoolean:(NSNumber *)boolean {
    return [[QredoMarkedAtom alloc] initWithBoolean:boolean];
}


+(instancetype)markedAtomWithByteSequence:(NSData *)data {
    return [[QredoMarkedAtom alloc] initWithByteSequence:data];
}


+(instancetype)markedAtomWithDate:(QredoDate *)date {
    return [[QredoMarkedAtom alloc] initWithDate:date];
}


+(instancetype)markedAtomWithGenericDateTime:(QredoDateTime *)dateTime {
    return [[QredoMarkedAtom alloc] initWithGenericDateTime:dateTime];
}


+(instancetype)markedAtomWithInt32:(NSNumber *)int32 {
    return [[QredoMarkedAtom alloc] initWithInt32:int32];
}


+(instancetype)markedAtomWithInt64:(NSNumber *)int64 {
    return [[QredoMarkedAtom alloc] initWithInt64:int64];
}


+(instancetype)markedAtomWithLocalDateTime:(QredoLocalDateTime *)localDateTime {
    return [[QredoMarkedAtom alloc] initWithLocalDateTime:localDateTime];
}


+(instancetype)markedAtomWithString:(NSString *)string {
    return [[QredoMarkedAtom alloc] initWithString:string];
}


+(instancetype)markedAtomWithSymbol:(NSString *)symbol {
    return [[QredoMarkedAtom alloc] initWithSymbol:symbol];
}


+(instancetype)markedAtomWithTime:(QredoTime *)time {
    return [[QredoMarkedAtom alloc] initWithTime:time];
}


+(instancetype)markedAtomWithQUID:(QredoQUID *)quid {
    return [[QredoMarkedAtom alloc] initWithQUID:quid];
}


+(instancetype)markedAtomWithUTCDateTime:(QredoUTCDateTime *)utcDateTime {
    return [[QredoMarkedAtom alloc] initWithUTCDateTime:utcDateTime];
}


-(instancetype)initWithAtom:(QredoAtom *)atom {
    self = [super init];
    if (self && atom){
        uint8_t *bytes = (uint8_t *)atom.bytes;
        _marker = (QredoMarker)bytes[0];
        _data   = [NSData dataWithBytes:bytes + 1 length:[atom length] - 1];
    }
    return self;
}


-(instancetype)initWithBoolean:(NSNumber *)boolean {
    self = [super init];
    if (self){
        _marker = [boolean boolValue] ? QredoMarkerBooleanTrue : QredoMarkerBooleanFalse;
        _data   = [NSData new];
    }
    return self;
}


-(instancetype)initWithByteSequence:(NSData *)data {
    self = [super init];
    if (self){
        _marker = QredoMarkerByteSequence;
        _data   = data;
    }
    return self;
}


-(instancetype)initWithDate:(QredoDate *)date {
    self = [super init];
    if (self)_marker = QredoMarkerDate;
    if (self && date){
        uint16_t year  = CFSwapInt16HostToBig(date.year);
        uint8_t month = date.month;
        uint8_t day   = date.day;
        NSMutableData *dateBytes = [NSMutableData new];
        [dateBytes appendBytes:&year length:sizeof(year)];
        [dateBytes appendBytes:&month length:sizeof(month)];
        [dateBytes appendBytes:&day length:sizeof(day)];
        _data = [NSData dataWithData:dateBytes];
    }
    return self;
}


-(instancetype)initWithGenericDateTime:(QredoDateTime *)dateTime {
    self = [super init];
    if (self)_marker = QredoMarkerDateTime;
    if (self && dateTime){
        QredoDate *date = [dateTime date];
        QredoTime *time = [dateTime time];
        uint16_t year  = CFSwapInt16HostToBig(date.year);
        uint8_t month = date.month;
        uint8_t day   = date.day;
        uint32_t millisSinceMidnight = CFSwapInt32HostToBig((uint32_t)time.millisSinceMidnight);
        NSMutableData *dateTimeBytes = [NSMutableData new];
        [dateTimeBytes appendBytes:&year length:sizeof(year)];
        [dateTimeBytes appendBytes:&month length:sizeof(month)];
        [dateTimeBytes appendBytes:&day length:sizeof(day)];
        [dateTimeBytes appendBytes:&millisSinceMidnight length:sizeof(millisSinceMidnight)];
        
        if ([dateTime isMemberOfClass:[QredoLocalDateTime class]]){
            [dateTimeBytes appendBytes:"L" length:sizeof(char)];
        } else if ([dateTime isMemberOfClass:[QredoUTCDateTime class]]){
            [dateTimeBytes appendBytes:"U" length:sizeof(char)];
        } else {
            @throw [NSException exceptionWithName:@"QredoUnexpectedMarkerException"
                                           reason:[NSString stringWithFormat:@"Unexpected QredoDateTime subclass '%@'.",
                                                   [[dateTime class] description]]
                                         userInfo:nil];
        }
        _data = [NSData dataWithData:dateTimeBytes];
    }
    return self;
}


-(instancetype)initWithInt32:(NSNumber *)int32 {
    self = [super init];
    if (self){
        _marker = QredoMarkerInt;
        int32_t data = CFSwapInt32HostToBig([int32 intValue]);
        _data   = [NSData dataWithBytes:&data length:sizeof(data)];
    }
    return self;
}


-(instancetype)initWithInt64:(NSNumber *)int64 {
    self = [super init];
    if (self){
        _marker = QredoMarkerInt;
        int64_t data = CFSwapInt64HostToBig([int64 longLongValue]);
        _data   = [NSData dataWithBytes:&data length:sizeof(data)];
    }
    return self;
}


-(instancetype)initWithLocalDateTime:(QredoLocalDateTime *)localDateTime {
    return [self initWithGenericDateTime:localDateTime];
}


-(instancetype)initWithString:(NSString *)string {
    self = [super init];
    if (self)_marker = QredoMarkerString;
    if (self && string){
        _data   = [string dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}


-(instancetype)initWithSymbol:(NSString *)symbol {
    self = [super init];
    if (self && symbol){
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[a-zA-Z_][a-zA-Z_0-9]*" options:0 error:nil];
        NSTextCheckingResult *result = [regex firstMatchInString:symbol options:0 range:NSMakeRange(0,symbol.length)];
        
        if ([symbol isEqualToString:[symbol substringWithRange:[result range]]]){
            _marker = QredoMarkerSymbol;
            _data   = [symbol dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            @throw [NSException exceptionWithName:@"QredoInvalidSymbol"
                                           reason:[NSString stringWithFormat:@"Symbols must match [a-zA-Z_][a-zA-Z_0-9]*, but \"%@\" doesn't.",symbol]
                                         userInfo:nil];
        }
    }
    return self;
}


-(instancetype)initWithTime:(QredoTime *)time {
    self = [super init];
    if (self)_marker = QredoMarkerTime;
    if (self && time){
         uint32_t data = CFSwapInt32HostToBig((uint32_t)time.millisSinceMidnight);
        _data   = [NSData dataWithBytes:&data length:sizeof(data)];
    }
    return self;
}


-(instancetype)initWithQUID:(QredoQUID *)quid {
    self = [super init];
    if (self)_marker = QredoMarkerQUID;
    if (self && quid){
        uint8_t bytes[32];
        [quid getQUIDBytes:bytes];
        _data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    }
    return self;
}


-(instancetype)initWithUTCDateTime:(QredoUTCDateTime *)utcDateTime {
    return [self initWithGenericDateTime:utcDateTime];
}


-(NSNumber *)asBoolean {
    switch (self.marker){
        case QredoMarkerBooleanTrue:
            return @TRUE;
            
        case QredoMarkerBooleanFalse:
            return @FALSE;
            
        default:
            @throw [NSException exceptionWithName:@"QredoUnexpectedMarkerException"
                                           reason:[NSString stringWithFormat:@"Expected Boolean marker, got '%c'.",self.marker]
                                         userInfo:nil];
    }
}


-(NSData *)asByteSequence {
    [self expectMarker:QredoMarkerByteSequence];
    return self.data;
}


-(NSData *)asData {
    NSNumber *i = @(self.marker);
    char c = [i charValue];
    NSMutableData *data = [NSMutableData dataWithBytes:&c length:1];
    if ([self.data length] > 0){
        [data appendData:self.data];
    }
    return [data copy];
}


-(QredoDate *)asDate {
    [self expectMarker:QredoMarkerDate];
    [self expectLength:4];
    uint16_t year;
    uint8_t month;
    uint8_t day;
    [self.data getBytes:&year range:NSMakeRange(0,sizeof(year))];
    [self.data getBytes:&month range:NSMakeRange(2,sizeof(month))];
    [self.data getBytes:&day range:NSMakeRange(3,sizeof(day))];
    return [QredoDate dateWithYear:CFSwapInt16BigToHost(year)
                             month:month
                               day:day];
}


-(QredoDateTime *)asGenericDateTime {
    [self expectMarker:QredoMarkerDateTime];
    [self expectLength:9];
    uint16_t year;
    uint8_t month;
    uint8_t day;
    [self.data getBytes:&year range:NSMakeRange(0,sizeof(year))];
    [self.data getBytes:&month range:NSMakeRange(2,sizeof(month))];
    [self.data getBytes:&day range:NSMakeRange(3,sizeof(day))];
    QredoDate *date = [QredoDate dateWithYear:CFSwapInt16BigToHost(year)
                                        month:month
                                          day:day];
    
    uint32_t millisSinceMidnight;
    [self.data getBytes:&millisSinceMidnight range:NSMakeRange(4,4)];
    QredoTime *time = [QredoTime timeWithMillisSinceMidnight:CFSwapInt32BigToHost(millisSinceMidnight)];
    
    uint8_t timeZoneMarker = ((uint8_t *)self.data.bytes)[8];
    switch (timeZoneMarker){
        case QredoMarkerLocalTimezone:
            return [QredoDateTime dateTimeWithDate:date time:time isUTC:false];
            
        case QredoMarkerUTCTimezone:
            return [QredoDateTime dateTimeWithDate:date time:time isUTC:true];
            
        default:
            [NSException exceptionWithName:@"QredoUnexpectedMarkerException"
                                    reason:[NSString stringWithFormat:@"Unexpected timezone marker '%c'.",self.marker]
                                  userInfo:nil];
            return nil;
    }
}


-(NSNumber *)asInt32 {
    int32_t int32;
    [self expectMarker:QredoMarkerInt];
    [self expectLength:sizeof(int32)];
    [self.data getBytes:&int32 length:sizeof(int32)];
    int32 = CFSwapInt32BigToHost(int32);
    return @(int32);
}


-(NSNumber *)asInt64 {
    int64_t int64;
    [self expectMarker:QredoMarkerInt];
    [self expectLength:sizeof(int64)];
    [self.data getBytes:&int64 length:sizeof(int64)];
    int64 = CFSwapInt64BigToHost(int64);
    return @(int64);
}


-(QredoLocalDateTime *)asLocalDateTime {
    [self expectMarker:QredoMarkerDateTime];
    [self expectLength:9];
    [self expectDateTimeMarker:QredoMarkerLocalTimezone];
    return (QredoLocalDateTime *)[self asGenericDateTime];
}


-(NSString *)asString {
    [self expectMarker:QredoMarkerString];
    NSMutableData *stringBytes = [NSMutableData dataWithData:self.data];
    [stringBytes appendBytes:"" length:1];
    return [NSString stringWithUTF8String:stringBytes.bytes];
}


-(NSString *)asSymbol {
    [self expectMarker:QredoMarkerSymbol];
    NSMutableData *symbolBytes = [NSMutableData dataWithData:self.data];
    [symbolBytes appendBytes:"" length:1];
    return [NSString stringWithUTF8String:symbolBytes.bytes];
}


-(QredoTime *)asTime {
    uint32_t time;
    
    [self expectMarker:QredoMarkerTime];
    [self expectLength:4];
    [self.data getBytes:&time length:sizeof(time)];
    time = CFSwapInt32BigToHost(time);
    return [QredoTime timeWithMillisSinceMidnight:time];
}


-(QredoQUID *)asQUID {
    [self expectMarker:QredoMarkerQUID];
    [self expectLength:32];
    return [[QredoQUID alloc] initWithQUIDBytes:self.data.bytes];
}


-(QredoUTCDateTime *)asUTCDateTime {
    [self expectMarker:QredoMarkerDateTime];
    [self expectLength:9];
    [self expectDateTimeMarker:QredoMarkerUTCTimezone];
    return (QredoUTCDateTime *)[self asGenericDateTime];
}


-(void)expectDateTimeMarker:(QredoMarker)expectedMarker {
    uint8_t actualMarker = ((uint8_t *)self.data.bytes)[8];
    
    if (actualMarker != expectedMarker){
        @throw [NSException exceptionWithName:@"QredoUnexpectedMarkerException"
                                       reason:[NSString stringWithFormat:@"Expected date/time marker '%c', got '%c'.",expectedMarker,actualMarker]
                                     userInfo:nil];
    }
}


-(void)expectMarker:(QredoMarker)expectedMarker {
    if (self.marker != expectedMarker){
        @throw [NSException exceptionWithName:@"QredoUnexpectedMarkerException"
                                       reason:[NSString stringWithFormat:@"Expected marker '%c' (0x%02X), got '%c' (0x%02X).",expectedMarker,expectedMarker,self.marker,self.marker]
                                     userInfo:nil];
    }
}


-(void)expectLength:(int)expectedLength {
    if ([self.data length] != expectedLength){
        @throw [NSException exceptionWithName:@"QredoUnexpectedLengthException"
                                       reason:[NSString stringWithFormat:@"Expected length %d, got %d.",expectedLength,(unsigned int)[self.data length]]
                                     userInfo:nil];
    }
}


-(BOOL)isEqual:(id)other {
    if (other == self)return YES;
    
    if (!other || ![[other class] isEqual:[self class]])return NO;
    
    return [self isEqualToAtom:other];
}


-(BOOL)isEqualToAtom:(QredoMarkedAtom *)atom {
    if (self == atom)return YES;
    if (atom == nil)return NO;
    if (self.marker != atom.marker)return NO;
    if (self.data != atom.data && ![self.data isEqualToData:atom.data])return NO;
    
    return YES;
}


-(NSUInteger)hash {
    NSUInteger hash = (NSUInteger)self.marker;
    hash = hash * 31u + [self.data hash];
    return hash;
}


@end

@implementation QredoVersion

+(instancetype)versionWithMajor:(NSNumber *)major minor:(NSNumber *)minor patch:(NSNumber *)patch {
    return [[self alloc] initWithMajor:major minor:minor patch:patch];
}


-(instancetype)initWithMajor:(NSNumber *)major minor:(NSNumber *)minor patch:(NSNumber *)patch {
    self = [super init];
    if (self){
        _major = major;
        _minor = minor;
        _patch = patch;
    }
    return self;
}


-(BOOL)isEqual:(id)other {
    if (other == self)return YES;
    if (!other || ![[other class] isEqual:[self class]])return NO;
    return [self isEqualToVersion:other];
}


-(BOOL)isEqualToVersion:(QredoVersion *)version {
    if (self == version)return YES;
    if (version == nil)return NO;
    if (self.major != version.major && ![self.major isEqualToNumber:version.major])return NO;
    if (self.minor != version.minor && ![self.minor isEqualToNumber:version.minor])return NO;
    if (self.patch != version.patch && ![self.patch isEqualToNumber:version.patch])return NO;
    
    return YES;
}


-(NSUInteger)hash {
    NSUInteger hash = [self.major hash];
    hash = hash * 31u + [self.minor hash];
    hash = hash * 31u + [self.patch hash];
    return hash;
}


@end

@implementation QredoMessageHeader

+(instancetype)messageHeaderWithProtocolVersion:(QredoVersion *)protocolVersion releaseVersion:(QredoVersion *)releaseVersion {
    return [[self alloc] initWithProtocolVersion:protocolVersion releaseVersion:releaseVersion];
}


-(instancetype)initWithProtocolVersion:(QredoVersion *)protocolVersion releaseVersion:(QredoVersion *)releaseVersion {
    self = [super init];
    if (self){
        _protocolVersion = protocolVersion;
        _releaseVersion  = releaseVersion;
    }
    return self;
}


-(BOOL)isEqual:(id)other {
    if (other == self)return YES;
    if (!other || ![[other class] isEqual:[self class]])return NO;
    return [self isEqualToHeader:other];
}


-(BOOL)isEqualToHeader:(QredoMessageHeader *)header {
    if (self == header)return YES;
    if (header == nil)return NO;
    if (self.protocolVersion != header.protocolVersion && ![self.protocolVersion isEqualToVersion:header.protocolVersion])return NO;
    if (self.releaseVersion != header.releaseVersion && ![self.releaseVersion isEqualToVersion:header.releaseVersion])return NO;
    return YES;
}


-(NSUInteger)hash {
    NSUInteger hash = [self.protocolVersion hash];
    hash = hash * 31u + [self.releaseVersion hash];
    return hash;
}


@end

@implementation QredoInterchangeHeader

+(instancetype)interchangeHeaderWithReturnChannelID:(NSData *)returnChannelID
                                      correlationID:(NSData *)correlationID
                                        serviceName:(NSString *)serviceName
                                      operationName:(NSString *)operationName {
    return [[self alloc] initWithReturnChannelID:returnChannelID
                                   correlationID:correlationID
                                     serviceName:serviceName
                                   operationName:operationName];
}


-(instancetype)initWithReturnChannelID:(NSData *)returnChannelID
                         correlationID:(NSData *)correlationID
                           serviceName:(NSString *)serviceName
                         operationName:(NSString *)operationName {
    self = [super init];
    if (self){
        _returnChannelID = returnChannelID;
        _correlationID   = correlationID;
        _serviceName     = serviceName;
        _operationName   = operationName;
    }
    return self;
}


-(BOOL)isEqual:(id)other {
    if (other == self)return YES;
    
    if (!other || ![[other class] isEqual:[self class]])return NO;
    
    return [self isEqualToHeader:other];
}


-(BOOL)isEqualToHeader:(QredoInterchangeHeader *)header {
    if (self == header)return YES;
    if (header == nil)return NO;
    if (self.returnChannelID != header.returnChannelID && ![self.returnChannelID isEqual:header.returnChannelID])return NO;
    if (self.correlationID != header.correlationID && ![self.correlationID isEqual:header.correlationID])return NO;
    if (self.serviceName != header.serviceName && ![self.serviceName isEqualToString:header.serviceName])return NO;
    if (self.operationName != header.operationName && ![self.operationName isEqualToString:header.operationName])return NO;
    return YES;
}


-(NSUInteger)hash {
    NSUInteger hash = [self.returnChannelID hash];
    
    hash = hash * 31u + [self.correlationID hash];
    hash = hash * 31u + [self.serviceName hash];
    hash = hash * 31u + [self.operationName hash];
    return hash;
}


@end


@interface QredoAppCredentials ()

@property (readwrite) NSString *appId;
@property (readwrite) NSData *appSecret;

@end

@implementation QredoAppCredentials

+(QredoAppCredentials *)empty {
    NSString *emptyAppId   = @"";
    NSData *emptyAppSecret = [NSData data];
    return [[self alloc] initWithAppId:emptyAppId appSecret:emptyAppSecret];
}


+(QredoAppCredentials *)appCredentialsWithAppId:(NSString *)appId
                                      appSecret:(NSData *)appSecret {
    return [[self alloc] initWithAppId:appId appSecret:appSecret];
}


-(QredoAppCredentials *)initWithAppId:(NSString *)appId
                            appSecret:(NSData *)appSecret {
    self = [super init];
    if (self){
        _appId     = appId;
        _appSecret = appSecret;
    }
    return self;
}


-(BOOL)isEqual:(id)other {
    if (other == self)return YES;
    if (!other || ![[other class] isEqual:[self class]])return NO;
    return [self isEqualToAppCredentials:other];
}


-(BOOL)isEqualToAppCredentials:(QredoAppCredentials *)appCredentials {
    if (self == appCredentials)return YES;
    if (appCredentials == nil)return NO;
    if (self.appId != appCredentials.appId && ![self.appId isEqualToString:appCredentials.appId])return NO;
    if (self.appSecret != appCredentials.appSecret && ![self.appSecret isEqualToData:appCredentials.appSecret])return NO;
    
    return YES;
}


-(NSUInteger)hash {
    NSUInteger hash = [self.appId hash];
    hash = hash * 31u + [self.appSecret hash];
    return hash;
}


-(NSString*)description{
    NSMutableString *ret = [[NSMutableString alloc] init];
    [ret appendString:[NSString stringWithFormat:@"AppID    : %@", self.appId]];
    [ret appendString:[NSString stringWithFormat:@"AppSecret: %@", self.appSecret]];
    return  [ret copy];
}

@end


@implementation QredoResultHeader

+(instancetype)resultHeaderWithStatus:(NSNumber *)status {
    return [[self alloc] initWithStatus:status];
}


-(instancetype)initWithStatus:(NSNumber *)status {
    self = [super init];
    if (self){
        _status = status;
    }
    return self;
}


-(BOOL)isFailure {
    return [self.status isEqualToNumber:@(QredoMarkerOperationFailure)];
}


-(BOOL)isSuccess {
    return [self.status isEqualToNumber:@(QredoMarkerOperationSuccess)];
}


@end

@implementation QredoDebugInfo

+(QredoDebugInfo *)debugInfoWithKey:(NSString *)key value:(NSString *)value {
    return [[self alloc] initWithKey:key value:value];
}


-(instancetype)initWithKey:(NSString *)key value:(NSString *)value {
    self = [super init];
    if (self){
        _key = key;
        _value = value;
    }
    return self;
}


-(BOOL)isEqual:(id)other {
    if (other == self)return YES;
    if (!other || ![[other class] isEqual:[self class]])return NO;
    return [self isEqualToInfo:other];
}


-(BOOL)isEqualToInfo:(QredoDebugInfo *)info {
    if (self == info)return YES;
    if (info == nil)return NO;
    if (self.key != info.key && ![self.key isEqualToString:info.key])return NO;
    if (self.value != info.value && ![self.value isEqualToString:info.value])return NO;
    return YES;
}


-(NSUInteger)hash {
    NSUInteger hash = [self.key hash];
    hash = hash * 31u + [self.value hash];
    return hash;
}


@end

@implementation QredoErrorInfo

+(instancetype)errorInfoWithCode:(NSInteger)code
                    debugMessage:(NSString *)debugMessage
                       debugInfo:(NSArray *)debugInfo {
    return [[self alloc] initWithCode:code debugMessage:debugMessage debugInfo:debugInfo];
}


-(instancetype)initWithCode:(NSInteger)code
               debugMessage:(NSString *)debugMessage
                  debugInfo:(NSArray *)debugInfo {
    self = [super init];
    if (self){
        _code = code;
        _debugMessage = debugMessage;
        _debugInfo = debugInfo;
    }
    return self;
}


-(BOOL)isEqual:(id)other {
    if (other == self)return YES;
    if (!other || ![[other class] isEqual:[self class]])return NO;
    return [self isEqualToInfo:other];
}


-(BOOL)isEqualToInfo:(QredoErrorInfo *)info {
    if (self == info)return YES;
    if (info == nil)return NO;
    if (self.code != info.code)return NO;
    if (self.debugMessage != info.debugMessage && ![self.debugMessage isEqualToString:info.debugMessage])return NO;
    if (self.debugInfo != info.debugInfo && ![self.debugInfo isEqualToArray:info.debugInfo])return NO;
    return YES;
}


-(NSUInteger)hash {
    NSUInteger hash = self.code;
    hash = hash * 31u + [self.debugMessage hash];
    hash = hash * 31u + [self.debugInfo hash];
    return hash;
}


@end


@interface QredoWireFormatReader ()
@property (readwrite) QredoSExpressionReader *reader;
@end


@implementation QredoWireFormatReader

+(instancetype)wireFormatReaderWithInputStream:(NSInputStream *)inputStream {
    return [[QredoWireFormatReader alloc] initWithInputStream:inputStream];
}


-(instancetype)initWithInputStream:(NSInputStream *)inputStream {
    self = [super init];
    if (self){
        _reader = [QredoSExpressionReader sexpressionReaderForInputStream:inputStream];
    }
    return self;
}


-(NSNumber *)readBoolean {
    return [[self readMarkedAtom] asBoolean];
}


-(NSNumber *)readByte {
    uint8_t *bytes = (uint8_t *)[self.reader readAtom].bytes;
    
    return @(bytes[0]);
}


-(NSData *)readByteSequence {
    return [[self readMarkedAtom] asByteSequence];
}


-(QredoDate *)readDate {
    return [[self readMarkedAtom] asDate];
}


-(QredoDateTime *)readGenericDateTime {
    return [[self readMarkedAtom] asGenericDateTime];
}


-(NSNumber *)readInt32 {
    return [[self readMarkedAtom] asInt32];
}


-(NSNumber *)readInt64 {
    return [[self readMarkedAtom] asInt64];
}


-(QredoLocalDateTime *)readLocalDateTime {
    return [[self readMarkedAtom] asLocalDateTime];
}


-(NSString *)readString {
    return [[self readMarkedAtom] asString];
}


-(NSString *)readSymbol {
    return [[self readMarkedAtom] asSymbol];
}


-(QredoTime *)readTime {
    return [[self readMarkedAtom] asTime];
}


-(QredoQUID *)readQUID {
    return [[self readMarkedAtom] asQUID];
}


-(QredoUTCDateTime *)readUTCDateTime {
    return [[self readMarkedAtom] asUTCDateTime];
}


-(QredoMessageHeader *)readMessageHeader {
    [self readStart];
    QredoVersion *protocolVersion = [self readVersion];
    QredoVersion *releaseVersion  = [self readVersion];
    return [QredoMessageHeader messageHeaderWithProtocolVersion:protocolVersion
                                                 releaseVersion:releaseVersion];
}


-(QredoVersion *)readVersion {
    NSData *versionBytes = [self readByteSequence];
    
    uint16_t majorInt;
    uint16_t minorInt;
    uint16_t patchInt;
    
    [versionBytes getBytes:&majorInt range:NSMakeRange(0,2)];
    [versionBytes getBytes:&minorInt range:NSMakeRange(2,2)];
    [versionBytes getBytes:&patchInt range:NSMakeRange(4,2)];
    
    NSNumber *major = @(CFSwapInt16BigToHost(majorInt));
    NSNumber *minor = @(CFSwapInt16BigToHost(minorInt));
    NSNumber *patch = @(CFSwapInt16BigToHost(patchInt));
    
    return [QredoVersion versionWithMajor:major minor:minor patch:patch];
}


-(QredoInterchangeHeader *)readInterchangeHeader {
    [self expectMarkedListWithMarker:QredoMarkerInterchange];
    
    NSData *returnChannelID = [self readByteSequence];
    NSData *correlationID   = [self readByteSequence];
    NSString *serviceName     = [self readSymbol];
    NSString *operationName   = [self readSymbol];
    
    return [QredoInterchangeHeader interchangeHeaderWithReturnChannelID:returnChannelID
                                                          correlationID:correlationID
                                                            serviceName:serviceName
                                                          operationName:operationName];
}


-(QredoAppCredentials *)readInvocationHeader {
    [self expectMarkedListWithMarker:QredoMarkerOperationInvocation];
    NSString *appId   = [self readString];
    NSData *appSecret = [self readByteSequence];
    return [QredoAppCredentials appCredentialsWithAppId:appId appSecret:appSecret];
}


-(NSArray *)readErrorInfoItems {
    NSMutableArray *errorInfoItems = [NSMutableArray new];
    [self readSequenceStart];
    while (![self atEnd])
        [errorInfoItems addObject:[self readErrorInfoItem]];
    [self readEnd];
    return [errorInfoItems copy];
}


-(QredoErrorInfo *)readErrorInfoItem {
    [self readStart];
    NSNumber *code = [self readInt32];
    NSString *debugMessage = [self readString];
    NSMutableArray *debugInfoItems = [NSMutableArray new];
    
    while (![self atEnd])
        [debugInfoItems addObject:[self readDebugInfoItem]];
    [self readEnd];
    return [QredoErrorInfo errorInfoWithCode:code.integerValue
                                debugMessage:debugMessage
                                   debugInfo:[debugInfoItems copy]];
}


-(QredoDebugInfo *)readDebugInfoItem {
    [self readStart];
    NSString *key = [self readString];
    NSString *value = [self readString];
    [self readEnd];
    return [QredoDebugInfo debugInfoWithKey:key
                                      value:value];
}


-(QredoResultHeader *)readResultStart {
    [self readStart];
    NSNumber *status = [self readByte];
    return [QredoResultHeader resultHeaderWithStatus:status];
}


-(void)readSequenceStart {
    [self expectMarkedListWithMarker:QredoMarkerSequence];
}


-(void)readSetStart {
    [self expectMarkedListWithMarker:QredoMarkerSet];
}


-(NSString *)readConstructorStart {
    [self expectMarkedListWithMarker:QredoMarkerConstructor];
    return [self readSymbol];
}


-(NSString *)readFieldStart {
    [self readStart];
    return [self readSymbol];
}


-(BOOL)atEnd {
    return ([self.reader lookAhead] == QredoTokenRParen);
}


-(void)readStart {
    [self.reader readLeftParen];
}


-(void)readEnd {
    [self.reader readRightParen];
}


-(QredoMarkedAtom *)readMarkedAtom {
    return [QredoMarkedAtom markedAtomWithAtom:[self.reader readAtom]];
}


-(void)expectMarkedListWithMarker:(QredoMarker)expectedMarker {
    [self readStart];
    [self expectMarker:expectedMarker];
}


-(void)expectMarker:(QredoMarker)expectedMarker {
    NSNumber *actualMarker = [self readByte];
    
    if ([actualMarker intValue] != expectedMarker){
        @throw [NSException exceptionWithName:@"QredoUnexpectedMarkedListException"
                                       reason:[NSString stringWithFormat:@"Expected marker '%c' (0x%02X), got '%c' (0x%02X).",expectedMarker,expectedMarker,[actualMarker charValue],[actualMarker charValue]]
                                     userInfo:nil];
    }
}


@end

#pragma mark - Qredo wire format writer implementation

@interface QredoWireFormatWriter ()
@property (readwrite) QredoSExpressionWriter *writer;
@end


@implementation QredoWireFormatWriter

+(instancetype)wireFormatWriterWithOutputStream:(NSOutputStream *)outputStream {
    return [[self alloc] initWithOutputStream:outputStream];
}


-(instancetype)initWithOutputStream:(NSOutputStream *)outputStream {
    self = [super init];
    if (self){
        _writer = [QredoSExpressionWriter sexpressionWriterForOutputStream:outputStream];
    }
    return self;
}


-(void)writeBoolean:(NSNumber *)boolean {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithBoolean:boolean] asData]];
}


-(void)writeByte:(NSNumber *)byte {
    uint8_t rawByte = [byte unsignedCharValue];
    
    [self.writer writeAtom:[NSData dataWithBytes:&rawByte length:sizeof(rawByte)]];
}


-(void)writeByteSequence:(NSData *)data {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithByteSequence:data] asData]];
}


-(void)writeDate:(QredoDate *)date {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithDate:date] asData]];
}


-(void)writeGenericDateTime:(QredoDateTime *)dateTime {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithGenericDateTime:dateTime] asData]];
}


-(void)writeInt32:(NSNumber *)int32 {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithInt32:int32] asData]];
}


-(void)writeInt64:(NSNumber *)int64 {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithInt64:int64] asData]];
}


-(void)writeLocalDateTime:(QredoLocalDateTime *)localDateTime {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithLocalDateTime:localDateTime] asData]];
}


-(void)writeString:(NSString *)string {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithString:string] asData]];
}


-(void)writeSymbol:(NSString *)symbol {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithSymbol:symbol] asData]];
}


-(void)writeTime:(QredoTime *)time {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithTime:time] asData]];
}


-(void)writeQUID:(QredoQUID *)quid {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithQUID:quid] asData]];
}


-(void)writeUTCDateTime:(QredoUTCDateTime *)utcDateTime {
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithUTCDateTime:utcDateTime] asData]];
}


-(void)writeMessageHeader:(QredoMessageHeader *)messageHeader {
    [self.writer writeLeftParen];
    [self writeVersion:[messageHeader protocolVersion]];
    [self writeVersion:[messageHeader releaseVersion]];
}


-(void)writeVersion:(QredoVersion *)version {
    NSMutableData *data = [NSMutableData new];
    uint16_t major = CFSwapInt16HostToBig([[version major] unsignedShortValue]);
    uint16_t minor = CFSwapInt16HostToBig([[version minor] unsignedShortValue]);
    uint16_t patch = CFSwapInt16HostToBig([[version patch] unsignedShortValue]);
    
    
    [data appendBytes:&major length:sizeof(major)];
    [data appendBytes:&minor length:sizeof(minor)];
    [data appendBytes:&patch length:sizeof(patch)];
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithByteSequence:data] asData]];
}


-(void)writeInterchangeHeader:(QredoInterchangeHeader *)interchangeHeader {
    [self writeMarkedListWithMarker:QredoMarkerInterchange];
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithByteSequence:[interchangeHeader returnChannelID]] asData]];
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithByteSequence:[interchangeHeader correlationID]] asData]];
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithSymbol:[interchangeHeader serviceName]] asData]];
    [self.writer writeAtom:[[QredoMarkedAtom markedAtomWithSymbol:[interchangeHeader operationName]] asData]];
}


-(void)writeInvocationHeader:(QredoAppCredentials *)appCredentials {
    [self writeMarkedListWithMarker:QredoMarkerOperationInvocation];
    [self writeString:appCredentials.appId];
    [self writeByteSequence:appCredentials.appSecret];
}


-(void)writeErrorInfoItems:(NSArray *)errorInfoItems {
    [self writeSequenceStart];
    
    for (QredoErrorInfo *errorInfoItem in errorInfoItems){
        [self writeErrorInfoItem:errorInfoItem];
    }
    
    [self writeEnd];
}


-(void)writeResultStart:(QredoResultHeader *)resultHeader {
    [self writeStart];
    [self writeByte:[resultHeader status]];
}


-(void)writeErrorInfoItem:(QredoErrorInfo *)errorInfoItem {
    [self writeStart];
    [self writeInt32:@([errorInfoItem code])];
    [self writeString:[errorInfoItem debugMessage]];
    
    for (QredoDebugInfo *debugInfoItem in [errorInfoItem debugInfo]){
        [self writeDebugInfoItem:debugInfoItem];
    }
    
    [self writeEnd];
}


-(void)writeDebugInfoItem:(QredoDebugInfo *)debugInfoItem {
    [self writeStart];
    [self writeString:[debugInfoItem key]];
    [self writeString:[debugInfoItem value]];
    [self writeEnd];
}


-(void)writeSequenceStart {
    [self writeMarkedListWithMarker:QredoMarkerSequence];
}


-(void)writeSetStart {
    [self writeMarkedListWithMarker:QredoMarkerSet];
}


-(void)writeConstructorStartWithObjectName:(NSString *)objectName {
    [self writeMarkedListWithMarker:QredoMarkerConstructor];
    [self writeSymbol:objectName];
}


-(void)writeFieldStartWithFieldName:(NSString *)fieldName {
    [self writeStart];
    [self writeSymbol:fieldName];
}


-(void)writeStart {
    [self.writer writeLeftParen];
}


-(void)writeEnd {
    [self.writer writeRightParen];
}


-(void)writeMarkedListWithMarker:(uint8_t)marker {
    [self.writer writeLeftParen];
    [self writeByte:@(marker)];
}


@end
