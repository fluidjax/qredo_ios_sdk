/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousHelper_Private.h"

@implementation QredoRendezvousAnonymousHelper

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeAnonymous;
}

- (NSString *)tag
{
    return self.originalTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return nil;
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data
{
    return nil;
}

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData
{
    return YES;
}

@end


