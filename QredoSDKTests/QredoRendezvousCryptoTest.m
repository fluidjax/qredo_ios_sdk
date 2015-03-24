/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRendezvousCrypto.h"
#import "QredoCrypto.h"
#import "CryptoImpl.h"
#import "CryptoImplV1.h"

@interface QredoRendezvousCryptoTest : XCTestCase

@end

@implementation QredoRendezvousCryptoTest

- (void)common_TestDerrivedKeysNotNilWithTag:(NSString *)tag
{
    QredoRendezvousCrypto *rendezvousCrypto = [QredoRendezvousCrypto instance];
    NSData *masterKey = [rendezvousCrypto masterKeyWithTag:tag];
    XCTAssertNotNil(masterKey, @"Master key should not be nil");

    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    XCTAssertNotNil(hashedTag, @"Hashed tag should not be nil");

    NSData *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    XCTAssertNotNil(authKey, @"Authentication key should not be nil");

    NSData *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    XCTAssertNotNil(encKey, @"Authentication key should not be nil");
}

- (void)testDerrivedKeysNotNil_AnonymousRendezvous
{
    [self common_TestDerrivedKeysNotNilWithTag:@"any anonymous tag"];
}

- (void)testDerrivedKeysNotNil_TrustedRendezvous
{
    [self common_TestDerrivedKeysNotNilWithTag:@"any trusted tag@public key data"];
}

@end
