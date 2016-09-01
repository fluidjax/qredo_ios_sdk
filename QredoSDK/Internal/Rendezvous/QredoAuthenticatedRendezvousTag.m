/* HEADER GOES HERE */
#import "QredoAuthenticatedRendezvousTag.h"
#import "QredoLoggerPrivate.h"

@interface QredoAuthenticatedRendezvousTag ()

@property (nonatomic,copy) NSString *fullTag;
@property (nonatomic,copy) NSString *prefix;
@property (nonatomic,copy) NSString *authenticationTag;

@end

@implementation QredoAuthenticatedRendezvousTag

-(instancetype)initWithFullTag:(NSString *)fullTag error:(NSError **)error {
    self = [super init];
    
    if (self){
        if (![self processFullTag:fullTag error:error]){
            return nil;
        }
        
        _fullTag = [fullTag copy];
    }
    
    return self;
}

-(instancetype)initWithPrefix:(NSString *)prefix authenticationTag:(NSString *)authenticationTag error:(NSError **)error {
    self = [super init];
    
    if (self){
        _prefix = [prefix copy];
        _authenticationTag = [authenticationTag copy];
        _fullTag = [QredoAuthenticatedRendezvousTag getFullTagFromPrefix:_prefix authenticationTag:_authenticationTag];
    }
    
    return self;
}

+(BOOL)isAuthenticatedTag:(NSString *)tag {
    return [tag containsString:@"@"];
}

-(BOOL)processFullTag:(NSString *)fullTag error:(NSError **)error {
    if (!fullTag){
        NSString *message = @"Nil full tag provided.";
        QredoLogError(@"%@",message);
        
        if (error){
            *error = createError(QredoAuthenticatedRendezvousTagErrorMissingTag,message);
        }
        
        return NO;
    }
    
    NSString *prefixValue = @"";
    NSString *authenticationTagValue = @"";
    
    //Only 1x '@' is allowed, any more is a malformed tag
    //Note: Authenticated rendezvous must include @, even if no prefix is present. If @ is missing, malformed tag
    NSArray *splitTagParts = [[fullTag copy] componentsSeparatedByString:@"@"];
    NSUInteger separatorCount = splitTagParts.count - 1;
    
    if (separatorCount != 1){
        NSString *message = [NSString stringWithFormat:@"Invalid number (%lu) of @ characters present. Require exactly 1. Full tag: '%@'",
                             (unsigned long)separatorCount,fullTag];
        QredoLogError(@"%@",message);
        
        if (error){
            *error = createError(QredoAuthenticatedRendezvousTagErrorMalformedTag,message);
        }
        
        return NO;
    } else {
        //Just 1 separator, and 2 elements to the parts array (prefix and then authentication tag)
        prefixValue = splitTagParts[0];
        authenticationTagValue = splitTagParts[1];
    }
    
    self.prefix = prefixValue;
    self.authenticationTag = authenticationTagValue;
    
    return YES;
}

+(NSString *)getFullTagFromPrefix:(NSString *)prefix authenticationTag:(NSString *)authenticationTag {
    //Ignore nil arguments, and replace with empty strings (avoids 'nil' appearing in the final string)
    NSString *prefixValue = @"";
    NSString *authenticationTagValue = @"";
    
    if (prefix){
        prefixValue = prefix;
    }
    
    if (authenticationTag){
        authenticationTagValue = authenticationTag;
    }
    
    //An authenticated rendezvous always starts with @, even if no prefix present
    NSString *fullTag = [NSString stringWithFormat:@"%@@%@",prefixValue,authenticationTagValue];
    
    return fullTag;
}

NSError *createError(QredoAuthenticatedRendezvousTagError errorCode,NSString *description) {
    NSError *error = [NSError errorWithDomain:QredoAuthenticatedRendezvousTagErrorDomain
                                         code:errorCode
                                     userInfo:@{ NSLocalizedDescriptionKey:description }];
    
    return error;
}

@end
