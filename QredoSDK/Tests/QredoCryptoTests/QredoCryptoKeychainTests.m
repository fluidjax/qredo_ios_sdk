//
//  QredoCryptoKeychainTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import <XCTest/XCTest.h>
#import "QredoCryptoKeychain.h"
#import "QredoKey.h"
#import "QredoKeyRef.h"
#import "UICKeyChainStore.h"

@interface QredoCryptoKeychainTests : XCTestCase

@end

@implementation QredoCryptoKeychainTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



-(void)testKeychainStoreRetrieve{
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    QredoKey *testKey = [[QredoKey alloc] initWithHexString:@"1c68b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];
    QredoKeyRef *ref = [keychain makeKeyRef];

    XCTAssertNotNil(keychain);
    XCTAssertNotNil(ref);
    XCTAssertNotNil(testKey);

    [keychain store:testKey withRef:ref];
    NSData *rawKey = [keychain retrieveWithRef:ref];
    XCTAssertNotNil(rawKey);
    QredoKey *outKey = [[QredoKey alloc] initWithData:rawKey];
    XCTAssertTrue([testKey isEqual:outKey],@"Key saved in keychain arent the same");
}


@end
