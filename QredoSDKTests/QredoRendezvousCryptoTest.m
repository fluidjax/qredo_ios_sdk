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


- (void)common_TestVectorsWithTag:(NSString *)tag {
    QredoRendezvousCrypto *rendezvousCrypto = [QredoRendezvousCrypto instance];


    NSLog(@"============ BEGIN ============");
    NSData *masterKey = [rendezvousCrypto masterKeyWithTag:tag];
    NSLog(@"Rendezvous tag: \"%@\"", tag);
    NSLog(@"Master key: %@", masterKey);

    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    NSLog(@"Hashed tag: %@", [hashedTag data]);

    NSData *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    NSLog(@"Authentication key: %@", authKey);

    NSData *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    NSLog(@"Encryption key: %@", encKey);


    QLFKeyPairLF *requesterKeyPair  = [rendezvousCrypto newRequesterKeyPair];
    NSData *requesterPublicKeyBytes = [[requesterKeyPair pubKey] bytes];
    NSString *conversationType      = @"com.qredo.chat";

    NSLog(@"---");
    NSLog(@"Responder Info:");
    NSLog(@"Requester public key: %@", requesterPublicKeyBytes);
    NSLog(@"Conversation type: \"%@\"", conversationType);




    QLFRendezvousResponderInfo *responderInfo
    = [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKeyBytes
                                                               conversationType:conversationType
                                                                       transCap:[NSSet set]];

    NSData *marshalledResponderInfo = [QredoPrimitiveMarshallers marshalObject:responderInfo];
    NSLog(@"Marshalled responder info %@", marshalledResponderInfo);
    NSLog(@"---");

    NSData *encryptedResponderInfo = [rendezvousCrypto encryptResponderInfo:responderInfo encryptionKey:encKey];
    NSLog(@"Encrypted responder info %@", encryptedResponderInfo);

    NSData *authenticationCode = [rendezvousCrypto authenticationCodeWithHashedTag:hashedTag
                                                                 authenticationKey:authKey
                                                            encryptedResponderData:encryptedResponderInfo];

    NSLog(@"Authentication code: %@", authenticationCode);
    NSLog(@"============ END ============");
}

- (void)testGenerateTestVectors
{
    [self common_TestVectorsWithTag:@"simple tag"];
    [self common_TestVectorsWithTag:@"fcc989f23ff77dd956cc5cde637c2d7eb07376dcf7322565e265e7f0913b5ad9"];

    QredoRendezvousCrypto *rendezvousCrypto = [QredoRendezvousCrypto instance];
    id<QredoRendezvousCreateHelper> rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                      fullTag:@"Ed25519@"
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];

    rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                      fullTag:@"RSA2048@"
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];


    rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                      fullTag:@"RSA4096@"
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];
}

@end
