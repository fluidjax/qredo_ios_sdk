/* HEADER GOES HERE */
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import <CommonCrypto/CommonCrypto.h>


static NSString *kQUIDEncodeKey = @"Qredo.quidbytes";

@implementation QredoQUID {
    unsigned char _quid[32];
}

+(instancetype)QUIDByHashingData:(NSData *)data {
    return [[QredoQUID alloc] initWithQUIDData:[QredoQUID sha256:data]];
}

+(instancetype)QUID {
    return [[self alloc] init];
}

+(NSData *)sha256:(NSData *)data {
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(data.bytes,(CC_LONG)data.length,hash.mutableBytes);
    
    return hash;
}

-(instancetype)init {
    if ((self = [super init])){
        [[NSUUID UUID] getUUIDBytes:_quid];
        [[NSUUID UUID] getUUIDBytes:_quid + 16];
    }
    
    return self;
}

-(instancetype)initWithQUIDBytes:(const unsigned char *)bytes {
    if ((self = [super init])){
        NSAssert(sizeof(bytes) < sizeof(_quid),@"bytes is too short");
        memcpy(_quid,bytes,sizeof(_quid));
    }
    
    return self;
}

-(instancetype)initWithQUIDData:(NSData *)data {
    NSAssert(data != nil,@"Data can not be nil");
    return [self initWithQUIDBytes:[data bytes]];
}

-(instancetype)initWithQUIDString:(NSString *)string {
    if (string.length != 64){
        [NSException raise:NSInvalidArgumentException
                    format:@"QUID string should be 64 characters long"];
    }
    
    if ((self = [super init])){
        char chars[3] = { 0 };
        
        for (int i = 0; i < string.length / 2; i++){
            chars[0] = [string characterAtIndex:i * 2];
            chars[1] = [string characterAtIndex:i * 2 + 1];
            unsigned long res = strtoul(chars,NULL,16);
            
            if (res == ULONG_MAX){
                self = nil;
                [NSException raise:NSInvalidArgumentException
                            format:@"QUID has invalid character. It should contain only hexadecimal digits"];
            }
            
            _quid[i] = (unsigned char)res;
        }
    }
    
    return self;
}

-(void)getQUIDBytes:(unsigned char *)quid {
    memcpy(quid,_quid,sizeof(_quid));
}

-(int)bytesCount {
    return 32;
}

-(const unsigned char *)bytes {
    return _quid;
}

-(NSData *)data {
    return [NSData dataWithBytesNoCopy:_quid length:32 freeWhenDone:NO];
}

-(NSString *)QUIDString {
    char quid_string[65] = { 0 };
    
    for (int i = 0; i < sizeof(_quid); i++){
        sprintf(quid_string + i * 2,"%02x",_quid[i]);
    }
    
    return [NSString stringWithUTF8String:quid_string];
}

-(NSComparisonResult)compare:(QredoQUID *)object {
    uint8_t selfBytes[32];
    uint8_t theirBytes[32];
    
    [self getQUIDBytes:selfBytes];
    [object getQUIDBytes:theirBytes];
    int cmp = memcmp(selfBytes,theirBytes,sizeof(selfBytes));
    return (NSComparisonResult)((cmp > 0) - (cmp < 0));
}

#pragma mark - NSObject

-(BOOL)isEqual:(id)object {
    if (self == object){
        return YES;
    } else if ([object isKindOfClass:[self class]]){
        unsigned char other_quid[32];
        [object getQUIDBytes:other_quid];
        return memcmp(_quid,other_quid,32) == 0;
    } else {
        return NO;
    }
}

-(NSUInteger)hash {
    NSData *data = [[NSData alloc] initWithBytes:_quid length:sizeof(_quid)];
    NSUInteger hash = [data hash];
    
    return hash;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@>",[self QUIDString]];
}

#pragma mark - NSCopying

-(instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - NSSecureCoding

+(BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark - NSCoding

-(instancetype)initWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]){
        NSUInteger length = 0;
        const uint8_t *quid = [coder decodeBytesForKey:kQUIDEncodeKey returnedLength:&length];
        
        if (length == sizeof(_quid)){
            return [self initWithQUIDBytes:quid];
        } else {
            return [self init];
        }
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"-[QredoQUID initWithCoder]: QUIDs cannot be decoded by non-keyed coders" userInfo:nil];
    }
}

-(void)encodeWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]){
        [coder encodeBytes:_quid length:sizeof(_quid) forKey:kQUIDEncodeKey];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"-[QredoQUID encodeWithCoder]: QUIDs cannot be encoded by non-keyed coders" userInfo:nil];
    }
}

@end
