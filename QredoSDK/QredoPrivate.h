/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"

@interface QredoClient ()

- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;

@end

#endif
