/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousHelper_Private.h"
#import "QredoLogging.h"
#import "NSData+QredoRandomData.h"
#import "QredoBase58.h"

@implementation QredoAbstractRendezvousAnonymousHelper
@end

#define RANDOM_TAG_LENGTH 32

@interface QredoRendezvousAnonymousCreateHelper ()
@property (nonatomic, copy) NSString *fullTag;
@end

@implementation QredoRendezvousAnonymousCreateHelper

static const NSUInteger kRandomTagLength = 32;

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }
        
        // Signing handler unnecessary for anonymous rendezvous
        if (signingHandler)
        {
            LogError(@"Signing handler provided for anonymous rendezvous.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided, nil);
            }
            return nil;
        }

        // When creating a rendezvous, empty tag indicates helper should generate one automatically
        if (fullTag.length == 0) {
            // Empty tag, so generate a random tag
            _fullTag = [self getRandomTag];
        }
        else {
            
            // Anonymous tag must not look like an authenticated rendezvous
            if ([fullTag containsString:@"@"]) {
                LogError(@"Full tag contains @, not valid for anonymous rendezvous tag.");
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
                }
                return nil;
            }

            _fullTag = fullTag;
        }
    }
    
    return self;
}

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    return [self initWithFullTag:fullTag crypto:crypto signingHandler:nil error:error];
}

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeAnonymous;
}

- (NSString *)tag
{
    return self.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return nil;
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    return nil;
}

- (NSString *)getRandomTag
{
    NSData *randomTagData = [NSData dataWithRandomBytesOfLength:kRandomTagLength];
    
    NSString *tag = [QredoBase58 encodeData:randomTagData];
    
    return tag;
}

@end

@interface QredoRendezvousAnonymousRespondHelper ()
@property (nonatomic, copy) NSString *fullTag;
@end

@implementation QredoRendezvousAnonymousRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {

        if (!fullTag) {
            LogError(@"Full tag is nil.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }

        // When responding to a rendezvous, can't have an empty tag
        if (fullTag.length == 0) {
            LogError(@"Full tag is empty.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }
        
        // Anonymous tag must not look like an authenticated rendezvous
        if ([fullTag containsString:@"@"]) {
            LogError(@"Full tag contains @, not valid for anonymous rendezvous tag.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
            }
            return nil;
        }
        
        _fullTag = fullTag;
    }
    
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeAnonymous;
}

- (NSString *)tag
{
    return self.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return nil;
}

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    LogDebug(@"Anonymous Rendezvous - signature is always valid!");
    return YES;
}

@end




