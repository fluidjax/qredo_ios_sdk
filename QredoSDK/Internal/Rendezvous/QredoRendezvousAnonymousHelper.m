/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousHelper_Private.h"
#import "QredoLogger.h"
#import "NSData+QredoRandomData.h"
#import "QredoBase58.h"

@implementation QredoAbstractRendezvousAnonymousHelper
@end

@interface QredoRendezvousAnonymousCreateHelper ()
@property (nonatomic, copy) NSString *fullTag;
@end

@implementation QredoRendezvousAnonymousCreateHelper

static const NSUInteger kRandomTagLength = 32;

- (instancetype)initWithFullTag:(NSString *)fullTag
                         crypto:(id<CryptoImpl>)crypto
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                 signingHandler:(signDataBlock)signingHandler
                          error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        
        // Crypto, TrustedRootPems and CrlPems are unused in anonymous rendezvous
        
        if (!fullTag) {
            QredoLogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        // Signing handler unnecessary for anonymous rendezvous
        if (signingHandler)
        {
            QredoLogError(@"Signing handler provided for anonymous rendezvous.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided, nil);
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
                QredoLogError(@"Full tag contains @, not valid for anonymous rendezvous tag.");
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMalformedTag, nil);
                return nil;
            }

            _fullTag = [fullTag copy];
        }
    }
    
    return self;
}

- (instancetype)initWithFullTag:(NSString *)fullTag
                         crypto:(id<CryptoImpl>)crypto
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                          error:(NSError **)error
{
    return [self initWithFullTag:fullTag
                          crypto:crypto
                 trustedRootPems:trustedRootPems
                         crlPems:crlPems
                  signingHandler:nil
                           error:error];
}

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeAnonymous;
}

- (NSString *)tag
{
    return self.fullTag;
}

- (QLFRendezvousAuthSignature *)emptySignature
{
    return nil;
}

- (QLFRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
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

- (instancetype)initWithFullTag:(NSString *)fullTag
                         crypto:(id<CryptoImpl>)crypto
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                          error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        
        // Crypto, TrustedRootPems and CrlPems are unused for anonymous rendezvous

        if (!fullTag) {
            QredoLogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }

        // When responding to a rendezvous, can't have an empty tag
        if (fullTag.length == 0) {
            QredoLogError(@"Full tag is empty.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        // Anonymous tag must not look like an authenticated rendezvous
        if ([fullTag containsString:@"@"]) {
            QredoLogError(@"Full tag contains @, not valid for anonymous rendezvous tag.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMalformedTag, nil);
            return nil;
        }
        
        _fullTag = [fullTag copy];
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

- (QLFRendezvousAuthSignature *)emptySignature
{
    return nil;
}

- (QLFRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    return nil;
}

- (BOOL)isValidSignature:(QLFRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    return YES;
}

@end


