/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"
#import "QredoLogging.h"

@implementation QredoAbstractRendezvousHelper

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto
{
    self = [super init];
    if (self) {
        NSAssert(crypto, @"A crypto implementation has not been provided.");
        _cryptoImpl = crypto;
    }
    return self;
}

// TODO: DH - Unit test stripPrefixFromFullTag
- (NSString *)stripPrefixFromFullTag:(NSString *)fullTag error:(NSError **)error
{
    if (!fullTag) {
        LogError(@"Nil full tag provided.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
        }
        return nil;
    }
    
    if (fullTag.length == 0) {
        LogError(@"Invalid full tag length: %ld", fullTag.length)
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
        }
        return nil;
    }
    
    // TODO: DH - Count number of @ in string, more than 1 is malformed.
    
    // TODO: DH - Review forward/backward search - Once ensured only 1 @ present, pick shortest route (forward?)
    NSUInteger prefixPos = [fullTag rangeOfString:@"@" options:NSBackwardsSearch].location;
    
    NSString *tagWithoutPrefix = nil;
    if (prefixPos == NSNotFound) {
        tagWithoutPrefix = fullTag;
    } else {
        // Don't include the @ symbol
        tagWithoutPrefix = [fullTag substringFromIndex:prefixPos+1];
    }
    
    LogDebug(@"Original tag: '%@'. Tag without prefix: '%@'.", fullTag, tagWithoutPrefix);
    
    return tagWithoutPrefix;
}

// TODO: DH - Unit test getPrefixFromFullTag
- (NSString *)getPrefixFromFullTag:(NSString *)fullTag error:(NSError **)error
{
    if (!fullTag) {
        LogError(@"Nil full tag provided.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
        }
        return nil;
    }
    
    if (fullTag.length == 0) {
        LogError(@"Invalid full tag length: %ld", fullTag.length)
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
        }
        return nil;
    }
    
    // TODO: DH - Count number of @ in string, more than 1 is malformed.

    // TODO: DH - Review forward/backward search - Once ensured only 1 @ present, pick shortest route (forward?)
    NSUInteger prefixPos = [fullTag rangeOfString:@"@" options:NSBackwardsSearch].location;
    
    NSString *prefixWithoutTag = nil;
    if (prefixPos == NSNotFound) {
        prefixWithoutTag = @"";
    } else {
        // Don't include the @ symbol
        prefixWithoutTag = [fullTag substringToIndex:prefixPos];
    }
    
    // TODO: DH - validate prefix - shouldn't contain whitespace or newlines (removed stripping from ED25519 code, so must enforce/remove here)
    
    LogDebug(@"Original tag: '%@'. Prefix: '%@'.", fullTag, prefixWithoutTag);
    
    return prefixWithoutTag;
}

@end

NSError *qredoRendezvousHelperError(QredoRendezvousHelperError errorCode, NSDictionary *userInfo)
{
    return [NSError errorWithDomain:QredoRendezvousHelperErrorDomain code:errorCode userInfo:userInfo];
}
