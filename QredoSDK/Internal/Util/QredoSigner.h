/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoED25519SigningKey;

@protocol QredoSigner <NSObject>

@required
- (NSData *)signData:(NSData *)data error:(NSError **)error;

@end

@interface QredoED25519Singer : NSObject <QredoSigner>

- (instancetype)initWithSigningKey:(QredoED25519SigningKey *)signingKey;

@end

@interface QredoRSASinger : NSObject <QredoSigner>

- (instancetype)initWithRSAKeyRef:(SecKeyRef)keyRef;

@end
