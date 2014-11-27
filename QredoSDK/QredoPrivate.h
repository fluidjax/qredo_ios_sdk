/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoPrivate_h
#define QredoSDK_QredoPrivate_h

#import "Qredo.h"
#import "QredoServiceInvoker.h"

@interface QredoClient ()

/** Creates instance of qredo client
 @param serviceURL Root URL for Qredo services
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL;

/**
 @param serviceURL serviceURL Root URL for Qredo services
 @param options qredo options. At the moment there is only `QredoClientOptionVaultID`
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL options:(NSDictionary*)options;

- (QredoServiceInvoker*)serviceInvoker;
- (QredoVault *)systemVault;

@end

#endif
