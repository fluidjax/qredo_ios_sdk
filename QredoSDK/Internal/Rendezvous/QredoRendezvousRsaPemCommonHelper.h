/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoRendezvousHelper_Private.h"
#import "QredoAuthenticatedRendezvousTag.h"

// Salt length for RSA PSS signing of authenticated rendezvous (related to hash length)
extern const NSInteger kRsaAuthenticatedRendezvousSaltLength;

@interface QredoAbstractRendezvousRsaPemHelper : QredoAbstractRendezvousHelper

// TODO: DH - look at moving some of these things into a separate protocol (as we're manually duplicating elements from a protocol the child implements)
- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength;
- (NSData *)emptySignatureData;

@property (nonatomic, readonly, assign) NSUInteger keySizeBits;
@property (nonatomic, readonly, assign) NSUInteger minimumAuthenticationTagLength;
@property (nonatomic, readonly, assign) QredoRendezvousAuthenticationType type;

@end

@interface QredoRendezvousRsaPemCreateHelper : QredoAbstractRendezvousRsaPemHelper

// TODO: DH - look at moving some of these things (methods?) into a separate protocol (as we're manually duplicating elements from a protocol the child implements) - or as a private interface?
- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength error:(NSError **)error;
- (NSData *)signatureForData:(NSData *)data error:(NSError **)error;

// TODO: DH - look at moving to the parent class, but seeing in child class
@property (nonatomic, readonly, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;

@end

@interface QredoRendezvousRsaPemRespondHelper : QredoAbstractRendezvousRsaPemHelper

// TODO: DH - look at moving some of these things (methods?) into a separate protocol (as we're manually duplicating elements from a protocol the child implements) - or as a private interface?
- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength error:(NSError **)error;
- (BOOL)isSignatureDataValid:(NSData *)signatureData rendezvousData:(NSData *)rendezvousData;

// TODO: DH - look at moving to the parent class, but seeing in child class
@property (nonatomic, readonly, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;

@end