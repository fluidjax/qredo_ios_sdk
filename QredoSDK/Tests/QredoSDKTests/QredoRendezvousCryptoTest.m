/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import "QredoXCTestCase.h"
#import <XCTest/XCTest.h>
#import "QredoRendezvousCrypto.h"
#import "QredoRawCrypto.h"
#import "NSData+HexTools.h"

@interface QredoRendezvousCryptoTest :QredoXCTestCase
{
    QredoRendezvousCrypto *rendezvousCrypto;
}

@end

@implementation QredoRendezvousCryptoTest

-(void)setUp {
    [super setUp];
    rendezvousCrypto = [QredoRendezvousCrypto instance];
}


-(void)common_TestDerrivedKeysNotNilWithTag:(NSString *)tag {
    QredoKeyRef *masterKeyRef = [rendezvousCrypto masterKeyWithTag:tag appId:k_TEST_APPID];
    
    XCTAssertNotNil(masterKeyRef,@"Master key should not be nil");
    
    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKeyRef];
    XCTAssertNotNil(hashedTag,@"Hashed tag should not be nil");
    
    QredoKeyRef *authKeyRef = [rendezvousCrypto authenticationKeyWithMasterKey:masterKeyRef];
    XCTAssertNotNil(authKeyRef,@"Authentication key should not be nil");
    
    QredoKeyRef *encKeyRef = [rendezvousCrypto encryptionKeyWithMasterKey:masterKeyRef];
    XCTAssertNotNil(encKeyRef,@"Authentication key should not be nil");
}


-(void)testDerrivedKeysNotNil_AnonymousRendezvous {
    [self common_TestDerrivedKeysNotNilWithTag:@"any anonymous tag"];
}


-(void)testDerrivedKeysNotNil_TrustedRendezvous {
    [self common_TestDerrivedKeysNotNilWithTag:@"any trusted tag@public key data"];
}


-(void)common_TestVectorsWithTag:(NSString *)tag {
    QredoKeyRef *masterKeyRef = [rendezvousCrypto masterKeyWithTag:tag appId:k_TEST_APPID];
    
    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKeyRef];
    
    QredoKeyRef *authKeyRef = [rendezvousCrypto authenticationKeyWithMasterKey:masterKeyRef];
    
    QredoKeyRef *encKeyRef = [rendezvousCrypto encryptionKeyWithMasterKey:masterKeyRef];
    
    
    QLFKeyPairLF *requesterKeyPair  = [rendezvousCrypto newRequesterKeyPair];
    NSData *requesterPublicKeyBytes = [[requesterKeyPair pubKey] bytes];
    NSString *conversationType      = @"com.qredo.chat";
    
    QLFRendezvousResponderInfo *responderInfo
    = [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKeyBytes
                                                               conversationType:conversationType
                                                                       transCap:[NSSet set]];
    
    [QredoPrimitiveMarshallers marshalObject:responderInfo includeHeader:NO];
    
    NSData *encryptedResponderInfo = [rendezvousCrypto encryptResponderInfo:responderInfo encryptionKeyRef:encKeyRef];
    [QredoPrimitiveMarshallers unmarshalObject:encryptedResponderInfo
                                  unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                   parseHeader:YES];
    NSMakeRange(0,16);
    
    [rendezvousCrypto authenticationCodeWithHashedTag:hashedTag
                                    authenticationKeyRef:authKeyRef
                               encryptedResponderData:encryptedResponderInfo];
}


@end
