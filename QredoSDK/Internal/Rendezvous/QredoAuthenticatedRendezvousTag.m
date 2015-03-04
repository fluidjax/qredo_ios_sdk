/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoAuthenticatedRendezvousTag.h"
#import "QredoLogging.h"

@interface QredoAuthenticatedRendezvousTag ()

@property (nonatomic, copy) NSString *fullTag;
@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *authenticationTag;

@end

@implementation QredoAuthenticatedRendezvousTag

- (instancetype)initWithFullTag:(NSString *)fullTag error:(NSError **)error
{
    self = [super init];
    if (self) {
        if (![self processFullTag:fullTag error:error]) {
            return nil;
        }
        
        _fullTag = fullTag;

        LogDebug(@"Prefix: '%@'. Authentication Tag: '%@'. Full Tag: '%@'.", _prefix, _authenticationTag, _fullTag);
    }
    
    return self;
}


- (instancetype)initWithPrefix:(NSString *)prefix authenticationTag:(NSString *)authenticationTag error:(NSError **)error
{
    self = [super init];
    if (self) {
        _prefix = prefix;
        _authenticationTag = authenticationTag;
        _fullTag = [QredoAuthenticatedRendezvousTag getFullTagFromPrefix:_prefix authenticationTag:_authenticationTag];
        
        LogDebug(@"Prefix: '%@'. Authentication Tag: '%@'. Full Tag: '%@'.", _prefix, _authenticationTag, _fullTag);
    }
    
    return self;
}

- (BOOL)processFullTag:(NSString *)fullTag error:(NSError **)error
{
    if (!fullTag) {
        NSString *message = @"Nil full tag provided.";
        LogError(@"%@", message);
        if (error) {
            *error = createError(QredoAuthenticatedRendezvousTagErrorMissingTag, message);
        }
        return NO;
    }

    NSString *prefixValue = @"";
    NSString *authenticationTagValue = @"";

    // Only 1x '@' is allowed, any more is a malformed tag
    // Note: Authenticated rendezvous must include @, even if no prefix is present. If @ is missing, malformed tag
    NSArray *splitTagParts = [fullTag componentsSeparatedByString:@"@"];
    NSUInteger separatorCount = splitTagParts.count - 1;
    if (separatorCount != 1) {
        NSString *message = [NSString stringWithFormat:@"Invalid number (%lu) of @ characters present. Require exactly 1. Full tag: '%@'",
                             (unsigned long)separatorCount, fullTag];
        LogError(@"%@", message);
        if (error) {
            *error = createError(QredoAuthenticatedRendezvousTagErrorMalformedTag, message);
        }
        return NO;
    }
    else {
        // Just 1 separator, and 2 elements to the parts array (prefix and then authentication tag)
        prefixValue = splitTagParts[0];
        authenticationTagValue = splitTagParts[1];
    }
    
    self.prefix = prefixValue;
    self.authenticationTag = authenticationTagValue;
    
    return YES;
}

+ (NSString *)getFullTagFromPrefix:(NSString *)prefix authenticationTag:(NSString *)authenticationTag
{
    // Ignore nil arguments, and replace with empty strings (avoids 'nil' appearing in the final string)
    NSString *prefixValue = @"";
    NSString *authenticationTagValue = @"";
    
    if (prefix) {
        prefixValue = prefix;
    }
    
    if (authenticationTag) {
        authenticationTagValue = authenticationTag;
    }
    
    // An authenticated rendezvous always starts with @, even if no prefix present
    NSString *fullTag = [NSString stringWithFormat:@"%@@%@", prefixValue, authenticationTagValue];
    
    return fullTag;
}

NSError *createError(QredoAuthenticatedRendezvousTagError errorCode, NSString *description)
{
    NSError *error = [NSError errorWithDomain:QredoAuthenticatedRendezvousTagErrorDomain
                                         code:errorCode
                                     userInfo:@{NSLocalizedDescriptionKey: description}];
    return error;
}


@end
