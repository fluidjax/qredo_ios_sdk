/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousHelper_Private.h"
#import "QredoLogging.h"


@interface QredoRendezvousAnonymousHelper ()
@property (nonatomic, copy) NSString *fullTag;
@end

@implementation QredoRendezvousAnonymousHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    // Signing handler is ignored for anonymous rendezvous
    self = [super initWithCrypto:crypto];
    if (self) {
        
        // TODO: DH - validate anonymous rendezvous tag?
        
        // TODO: DH - If tag is null or empty (0 length), then generated a random tag of 32 bytes and base58 encodes it
        
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

        if (fullTag.length == 0) {
            // Empty tag, so generate a random tag
            _fullTag = [crypto getRandomTag];
            
        }
        else {
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

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    LogDebug(@"Anonymous Rendezvous - signature is always valid!");
    return YES;
}

@end


