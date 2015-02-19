//
//  QredoRendezvousRsaPemCommonHelperTests.m
//  QredoSDK_pods
//
//  Created by David Hearn on 19/02/2015.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRendezvousRsaPemCommonHelper.h"
#import "CryptoImplV1.h"

@interface QredoRendezvousRsaPemCommonHelperTests : XCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@end

@implementation QredoRendezvousRsaPemCommonHelperTests

- (void)setUp {
    [super setUp];

    self.cryptoImpl = [[CryptoImplV1 alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAbstractHelper_InitWithCrypto
{
    id<CryptoImpl> crypto = self.cryptoImpl;
    QredoRendezvousAuthenticationType type = QredoRendezvousAuthenticationTypeRsa2048Pem;  // TODO: DH - try other values?
    NSUInteger keySizeBits = 1234;
    NSUInteger minimumAuthenticationTagLength = 5678;
    
    QredoAbstractRendezvousRsaPemHelper *abstractHelper = [[QredoAbstractRendezvousRsaPemHelper alloc]
                                                           initWithCrypto:crypto
                                                           type:type
                                                           keySizeBits:keySizeBits
                                                           minimumAuthenticationTagLength:minimumAuthenticationTagLength];
    XCTAssertNotNil(abstractHelper);
    XCTAssertEqual(abstractHelper.type, type);
    XCTAssertEqual(abstractHelper.keySizeBits, keySizeBits);
    XCTAssertEqual(abstractHelper.minimumAuthenticationTagLength, minimumAuthenticationTagLength);
}


@end
