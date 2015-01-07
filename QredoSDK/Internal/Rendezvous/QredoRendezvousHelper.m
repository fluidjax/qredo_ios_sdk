/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"


@implementation QredoAbstractRendezvousHelper

- (instancetype)initWithTag:(NSString *)tag
{
    self = [super init];
    if (self) {
        self.originalTag = tag;
    }
    return self;
}

@end


