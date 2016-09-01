/* HEADER GOES HERE */
#import "QredoClientId.h"

@interface QredoClientId ()

@property (copy) NSString *clientIdSafeString;

@end

@implementation QredoClientId

const int ReturnChannelIdSize = 16;

+ (instancetype)randomClientId
{
    NSData *randomData = [QredoClientId secureRandomWithSize:ReturnChannelIdSize];
    QredoClientId *clientId = [QredoClientId clientIdFromData:randomData];
    
    return clientId;
}

+ (NSData *)secureRandomWithSize:(NSUInteger)size
{
    size_t   randomSize  = size;
    uint8_t *randomBytes = alloca(randomSize);
    int result = SecRandomCopyBytes(kSecRandomDefault, randomSize, randomBytes);
    if (result != 0) {
        @throw [NSException exceptionWithName:@"QredoSecureRandomGenerationException"
                                       reason:[NSString stringWithFormat:@"Failed to generate a secure random byte array of size %lu (result: %d)..", (unsigned long)size, result]
                                     userInfo:nil];
    }
    return [NSData dataWithBytes:randomBytes length:randomSize];
}

+ (instancetype)clientIdFromData:(NSData *)data
{
    if (!data)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Data argument is nil"
                                     userInfo:nil];
    }
    
    if (data.length != ReturnChannelIdSize)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument must be %d bytes long", ReturnChannelIdSize]
                                     userInfo:nil];
    }
    
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    NSString *topicSafe = [QredoClientId getTopicSafeStringFromBase64:base64String];
    NSString *noPadding = [QredoClientId dropPaddingFromBase64String:topicSafe];
    QredoClientId *clientID = [[QredoClientId alloc] initWithClientIdSafeString:noPadding];
    
    return clientID;
}

+ (NSString *)dropPaddingFromBase64String:(NSString *)base64String
{
    // Android code returned substring from index 0 to index 22
    NSString *noPadding = [base64String substringToIndex:22];
    return noPadding;
}

+ (NSString *)addBase64PaddingToString:(NSString *)string
{
    // Android code added == to end
    NSString *padded = [string stringByAppendingString:@"=="];
    return padded;
}

+ (NSString *)getTopicSafeStringFromBase64:(NSString *)base64String
{
    NSString *topicSafe = [base64String stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    topicSafe = [topicSafe stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return topicSafe;
}

+ (NSString *)getBase64FromTopicSafeString:(NSString *)topicSafe
{
    NSString *base64 = [topicSafe stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    base64 = [base64 stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    return base64;
}

- (instancetype)initWithClientIdSafeString:(NSString *)clientId
{
    self = [super init];
    if (self)
    {
        _clientIdSafeString = clientId;
    }
    
    return self;
}

- (NSData *)getData
{
    NSString *base64String = [QredoClientId getBase64FromTopicSafeString:self.clientIdSafeString];
    NSString *base64StringPadded = [QredoClientId addBase64PaddingToString:base64String];
    
    NSData *base64Data = [base64StringPadded dataUsingEncoding:NSUTF8StringEncoding];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedData:base64Data options:0];
    return decodedData;
}

- (NSString *)getSafeString
{
    return self.clientIdSafeString;
}
@end
