/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import "QredoDateTime.h"
#import "QredoSExpression.h"

#pragma mark - Qredo marked atom

typedef NS_ENUM (char,QredoMarker) {
    QredoMarkerInt = 'I',
    QredoMarkerBooleanTrue = 'T',
    QredoMarkerBooleanFalse = 'F',
    QredoMarkerString = 'S',
    QredoMarkerSymbol = '\'',
    QredoMarkerQUID = 'Q',
    QredoMarkerDate = 'd',
    QredoMarkerTime = 't',
    QredoMarkerDateTime = 'D',
    QredoMarkerByteSequence = 'b',
    QredoMarkerSequence = '[',
    QredoMarkerSet = '{',
    QredoMarkerConstructor = 'C',
    QredoMarkerInterchange = 's',
    QredoMarkerOperationInvocation = 'o',
    QredoMarkerOperationSuccess = 'r',
    QredoMarkerOperationFailure = 'R',
    QredoMarkerLocalTimezone = 'L',
    QredoMarkerUTCTimezone = 'U'
};

@interface QredoMarkedAtom :NSObject

@property (readonly) QredoMarker marker;
@property (readonly) NSData *data;

+(instancetype)markedAtomWithAtom:(QredoAtom *)atom;
+(instancetype)markedAtomWithBoolean:(NSNumber *)boolean;
+(instancetype)markedAtomWithByteSequence:(NSData *)data;
+(instancetype)markedAtomWithDate:(QredoDate *)date;
+(instancetype)markedAtomWithGenericDateTime:(QredoDateTime *)dateTime;
+(instancetype)markedAtomWithInt32:(NSNumber *)int32;
+(instancetype)markedAtomWithInt64:(NSNumber *)int64;
+(instancetype)markedAtomWithLocalDateTime:(QredoLocalDateTime *)localDateTime;
+(instancetype)markedAtomWithString:(NSString *)string;
+(instancetype)markedAtomWithSymbol:(NSString *)symbol;
+(instancetype)markedAtomWithTime:(QredoTime *)time;
+(instancetype)markedAtomWithQUID:(QredoQUID *)quid;
+(instancetype)markedAtomWithUTCDateTime:(QredoUTCDateTime *)utcDateTime;

-(instancetype)initWithAtom:(QredoAtom *)atom;
-(instancetype)initWithBoolean:(NSNumber *)boolean;
-(instancetype)initWithByteSequence:(NSData *)data;
-(instancetype)initWithDate:(QredoDate *)date;
-(instancetype)initWithGenericDateTime:(QredoDateTime *)dateTime;
-(instancetype)initWithInt32:(NSNumber *)int32;
-(instancetype)initWithInt64:(NSNumber *)int64;
-(instancetype)initWithLocalDateTime:(QredoLocalDateTime *)localDateTime;
-(instancetype)initWithString:(NSString *)string;
-(instancetype)initWithSymbol:(NSString *)symbol;
-(instancetype)initWithTime:(QredoTime *)time;
-(instancetype)initWithQUID:(QredoQUID *)quid;
-(instancetype)initWithUTCDateTime:(QredoUTCDateTime *)utcDateTime;

-(NSNumber *)asBoolean;
-(NSData *)asByteSequence;
-(QredoDate *)asDate;
-(QredoDateTime *)asGenericDateTime;
-(NSNumber *)asInt32;
-(NSNumber *)asInt64;
-(QredoLocalDateTime *)asLocalDateTime;
-(NSString *)asString;
-(NSString *)asSymbol;
-(QredoTime *)asTime;
-(QredoQUID *)asQUID;
-(QredoUTCDateTime *)asUTCDateTime;

-(NSData *)asData;

-(BOOL)isEqual:(id)other;
-(BOOL)isEqualToAtom:(QredoMarkedAtom *)atom;
-(NSUInteger)hash;

@end

#pragma mark - Qredo structural objects

@interface QredoVersion :NSObject

@property (readonly) NSNumber *major;
@property (readonly) NSNumber *minor;
@property (readonly) NSNumber *patch;

+(instancetype)versionWithMajor:(NSNumber *)major
                          minor:(NSNumber *)minor
                          patch:(NSNumber *)patch;

-(instancetype)initWithMajor:(NSNumber *)major
                       minor:(NSNumber *)minor
                       patch:(NSNumber *)patch;

-(BOOL)isEqual:(id)other;
-(BOOL)isEqualToVersion:(QredoVersion *)version;
-(NSUInteger)hash;

@end

@interface QredoMessageHeader :NSObject

@property (readonly) QredoVersion *protocolVersion;
@property (readonly) QredoVersion *releaseVersion;

+(instancetype)messageHeaderWithProtocolVersion:(QredoVersion *)protocolVersion
                                 releaseVersion:(QredoVersion *)releaseVersion;

-(instancetype)initWithProtocolVersion:(QredoVersion *)protocolVersion
                        releaseVersion:(QredoVersion *)releaseVersion;

-(BOOL)isEqual:(id)other;
-(BOOL)isEqualToHeader:(QredoMessageHeader *)header;
-(NSUInteger)hash;

@end

@interface QredoInterchangeHeader :NSObject

@property (readonly) NSData *returnChannelID;
@property (readonly) NSData *correlationID;
@property (readonly) NSString *serviceName;
@property (readonly) NSString *operationName;

+(instancetype)interchangeHeaderWithReturnChannelID:(NSData *)returnChannelID
                                      correlationID:(NSData *)correlationID
                                        serviceName:(NSString *)serviceName
                                      operationName:(NSString *)operationName;

-(instancetype)initWithReturnChannelID:(NSData *)returnChannelID
                         correlationID:(NSData *)correlationID
                           serviceName:(NSString *)serviceName
                         operationName:(NSString *)operationName;

-(BOOL)isEqual:(id)other;
-(BOOL)isEqualToHeader:(QredoInterchangeHeader *)header;
-(NSUInteger)hash;

@end

@interface QredoAppCredentials :NSObject

@property (readonly) NSString *appId;
@property (readonly) NSData *appSecret;

+(QredoAppCredentials *)empty;

+(QredoAppCredentials *)appCredentialsWithAppId:(NSString *)appId
                                      appSecret:(NSData *)appSecret;

-(BOOL)isEqual:(id)other;
-(BOOL)isEqualToAppCredentials:(QredoAppCredentials *)appCredentials;
-(NSUInteger)hash;

@end

@interface QredoResultHeader :NSObject

@property (readonly) NSNumber *status;

+(instancetype)resultHeaderWithStatus:(NSNumber *)status;

-(instancetype)initWithStatus:(NSNumber *)status;

-(BOOL)isSuccess;
-(BOOL)isFailure;

@end

@interface QredoDebugInfo :NSObject

@property (readonly) NSString *key;
@property (readonly) NSString *value;

+(instancetype)debugInfoWithKey:(NSString *)key
                          value:(NSString *)value;

-(instancetype)initWithKey:(NSString *)key
                     value:(NSString *)value;

-(BOOL)isEqual:(id)other;
-(BOOL)isEqualToInfo:(QredoDebugInfo *)info;
-(NSUInteger)hash;

@end

@interface QredoErrorInfo :NSObject

@property (readonly) NSInteger code;
@property (readonly) NSString *debugMessage;
@property (readonly) NSArray *debugInfo;

+(instancetype)errorInfoWithCode:(NSInteger)code
                    debugMessage:(NSString *)debugMessage
                       debugInfo:(NSArray *)debugInfo;

-(instancetype)initWithCode:(NSInteger)code
               debugMessage:(NSString *)debugMessage
                  debugInfo:(NSArray *)debugInfo;

-(BOOL)isEqual:(id)other;
-(BOOL)isEqualToInfo:(QredoErrorInfo *)info;
-(NSUInteger)hash;

@end

#pragma mark - Qredo wire format reader

@interface QredoWireFormatReader :NSObject

+(instancetype)wireFormatReaderWithInputStream:(NSInputStream *)inputStream;

-(instancetype)initWithInputStream:(NSInputStream *)inputStream;

-(NSNumber *)readBoolean;
-(NSNumber *)readByte;
-(NSData *)readByteSequence;
-(QredoDate *)readDate;
-(QredoDateTime *)readGenericDateTime;
-(NSNumber *)readInt32;
-(NSNumber *)readInt64;
-(QredoLocalDateTime *)readLocalDateTime;
-(NSString *)readString;
-(NSString *)readSymbol;
-(QredoTime *)readTime;
-(QredoQUID *)readQUID;
-(QredoUTCDateTime *)readUTCDateTime;

-(QredoMessageHeader *)readMessageHeader;
-(QredoVersion *)readVersion;
-(QredoInterchangeHeader *)readInterchangeHeader;
-(QredoAppCredentials *)readInvocationHeader;
-(NSArray *)readErrorInfoItems;
-(QredoResultHeader *)readResultStart;
-(void)readSequenceStart;
-(void)readSetStart;
-(NSString *)readConstructorStart;
-(NSString *)readFieldStart;
-(BOOL)atEnd;

-(void)readStart;
-(void)readEnd;

@end

#pragma mark - Qredo wire format writer

@interface QredoWireFormatWriter :NSObject

+(instancetype)wireFormatWriterWithOutputStream:(NSOutputStream *)outputStream;

-(instancetype)initWithOutputStream:(NSOutputStream *)outputStream;

-(void)writeBoolean:(NSNumber *)boolean;
-(void)writeByte:(NSNumber *)byte;
-(void)writeByteSequence:(NSData *)data;
-(void)writeDate:(QredoDate *)date;
-(void)writeGenericDateTime:(QredoDateTime *)dateTime;
-(void)writeInt32:(NSNumber *)int32;
-(void)writeInt64:(NSNumber *)int64;
-(void)writeLocalDateTime:(QredoLocalDateTime *)localDateTime;
-(void)writeString:(NSString *)string;
-(void)writeSymbol:(NSString *)symbol;
-(void)writeTime:(QredoTime *)time;
-(void)writeQUID:(QredoQUID *)quid;
-(void)writeUTCDateTime:(QredoUTCDateTime *)utcDateTime;

-(void)writeMessageHeader:(QredoMessageHeader *)messageHeader;
-(void)writeVersion:(QredoVersion *)version;
-(void)writeInterchangeHeader:(QredoInterchangeHeader *)interchangeHeader;
-(void)writeInvocationHeader:(QredoAppCredentials *)appCredentials;
-(void)writeErrorInfoItems:(NSArray *)errorInfoItems;
-(void)writeResultStart:(QredoResultHeader *)status;
-(void)writeSequenceStart;
-(void)writeSetStart;
-(void)writeConstructorStartWithObjectName:(NSString *)objectName;
-(void)writeFieldStartWithFieldName:(NSString *)fieldName;

-(void)writeStart;
-(void)writeEnd;

@end
