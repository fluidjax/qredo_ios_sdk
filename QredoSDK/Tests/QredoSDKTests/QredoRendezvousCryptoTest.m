/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import "QredoXCTestCase.h"
#import <XCTest/XCTest.h>
#import "QredoRendezvousCrypto.h"
#import "QredoRawCrypto.h"
#import "QredoCryptoImpl.h"
#import "QredoCryptoImplV1.h"
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
    QredoKey *masterKey = [rendezvousCrypto masterKeyWithTag:tag appId:k_TEST_APPID];
    
    XCTAssertNotNil(masterKey,@"Master key should not be nil");
    
    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    XCTAssertNotNil(hashedTag,@"Hashed tag should not be nil");
    
    QredoKey *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    XCTAssertNotNil(authKey,@"Authentication key should not be nil");
    
    QredoKey *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    XCTAssertNotNil(encKey,@"Authentication key should not be nil");
}


-(void)testDerrivedKeysNotNil_AnonymousRendezvous {
    [self common_TestDerrivedKeysNotNilWithTag:@"any anonymous tag"];
}


-(void)testDerrivedKeysNotNil_TrustedRendezvous {
    [self common_TestDerrivedKeysNotNilWithTag:@"any trusted tag@public key data"];
}


-(void)common_TestVectorsWithTag:(NSString *)tag {
    QredoKey *masterKey = [rendezvousCrypto masterKeyWithTag:tag appId:k_TEST_APPID];
    
    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    
    QredoKey *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    
    QredoKey *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    
    
    QLFKeyPairLF *requesterKeyPair  = [rendezvousCrypto newRequesterKeyPair];
    NSData *requesterPublicKeyBytes = [[requesterKeyPair pubKey] bytes];
    NSString *conversationType      = @"com.qredo.chat";
    
    QLFRendezvousResponderInfo *responderInfo
    = [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKeyBytes
                                                               conversationType:conversationType
                                                                       transCap:[NSSet set]];
    
    [QredoPrimitiveMarshallers marshalObject:responderInfo includeHeader:NO];
    
    NSData *encryptedResponderInfo = [rendezvousCrypto encryptResponderInfo:responderInfo encryptionKey:encKey];
    [QredoPrimitiveMarshallers unmarshalObject:encryptedResponderInfo
                                  unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                   parseHeader:YES];
    NSMakeRange(0,16);
    
    [rendezvousCrypto authenticationCodeWithHashedTag:hashedTag
                                    authenticationKey:authKey
                               encryptedResponderData:encryptedResponderInfo];
}


@end
