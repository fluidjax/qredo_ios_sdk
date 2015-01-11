/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper.h"


@protocol CryptoImpl;

@interface QredoAbstractRendezvousHelper ()
@property (nonatomic, copy, readonly) NSString *originalTag;
@property (nonatomic, readonly) id<CryptoImpl> cryptoImpl;
@end
