/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoRendezvousHelper_Private.h"
#import "QredoAuthenticatedRendezvousTag.h"

// Salt length for RSA PSS signing of authenticated rendezvous (related to hash length)
extern const NSInteger kRsaAuthenticatedRendezvousSaltLength;

@interface QredoAbstractRendezvousRsaPemHelper : QredoAbstractRendezvousHelper

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength;
- (NSData *)emptySignatureData;

@property (nonatomic, readonly) NSUInteger keySizeBits;
@property (nonatomic, readonly) NSUInteger minimumAuthenticationTagLength;
@property (nonatomic, readonly) QredoRendezvousAuthenticationType type;

@end

@interface QredoRendezvousRsaPemCreateHelper : QredoAbstractRendezvousRsaPemHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength error:(NSError **)error;
- (NSData *)signatureForData:(NSData *)data error:(NSError **)error;

@property (nonatomic, readonly) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;

@end

@interface QredoRendezvousRsaPemRespondHelper : QredoAbstractRendezvousRsaPemHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength error:(NSError **)error;
- (BOOL)isSignatureDataValid:(NSData *)signatureData rendezvousData:(NSData *)rendezvousData;

@property (nonatomic, readonly) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;

@end