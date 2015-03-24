/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoAuthenticatedRendezvousTag.h"

@interface QredoAuthenticatedRendezvousTagTests : XCTestCase

@end

@implementation QredoAuthenticatedRendezvousTagTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitWithFullTag_Valid_PrefixWithAuthenticationTag
{
    NSString *fullTag = @"prefix@authenticationTag";
    NSError *error = nil;
    
    NSString *expectedPrefix = @"prefix";
    NSString *expectedAuthenticationTag = @"authenticationTag";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.prefix isEqualToString:expectedPrefix]);
    XCTAssertTrue([tag.authenticationTag isEqualToString:expectedAuthenticationTag]);
}

- (void)testInitWithFullTag_Valid_NoPrefixWithAuthenticationTag
{
    NSString *fullTag = @"@authenticationTag";
    NSError *error = nil;
    
    NSString *expectedPrefix = @"";
    NSString *expectedAuthenticationTag = @"authenticationTag";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.prefix isEqualToString:expectedPrefix]);
    XCTAssertTrue([tag.authenticationTag isEqualToString:expectedAuthenticationTag]);
}

- (void)testInitWithFullTag_Valid_NoPrefixOrAuthenticationTag
{
    NSString *fullTag = @"@";
    NSError *error = nil;
    
    NSString *expectedPrefix = @"";
    NSString *expectedAuthenticationTag = @"";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.prefix isEqualToString:expectedPrefix]);
    XCTAssertTrue([tag.authenticationTag isEqualToString:expectedAuthenticationTag]);
}

- (void)testInitWithFullTag_Invalid_NilTag
{
    NSString *fullTag = nil;
    NSError *error = nil;
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:&error];
    XCTAssertNil(tag);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMissingTag);
}

- (void)testInitWithFullTag_Invalid_EmptyTagNoAtSymbol
{
    NSString *fullTag = @"";
    NSError *error = nil;
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:&error];
    XCTAssertNil(tag);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testInitWithFullTag_Invalid_AuthenticationTagButNoAtSymbol
{
    NSString *fullTag = @"authenticationTag";
    NSError *error = nil;
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:&error];
    XCTAssertNil(tag);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testInitWithFullTag_Invalid_MultipleAtSymbol
{
    NSString *fullTag = @"@authentication@Tag";
    NSError *error = nil;
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:&error];
    XCTAssertNil(tag);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testInitWithPrefix_Valid_PrefixWithAuthenticationTag
{
    NSString *prefix = @"prefix";
    NSString *authenticationTag = @"authenticationTag";
    NSError *error = nil;
    
    NSString *expectedFullTag = @"prefix@authenticationTag";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:prefix authenticationTag:authenticationTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.fullTag isEqualToString:expectedFullTag]);
}

- (void)testInitWithPrefix_Valid_NoPrefixWithAuthenticationTag
{
    NSString *prefix = @"";
    NSString *authenticationTag = @"authenticationTag";
    NSError *error = nil;
    
    NSString *expectedFullTag = @"@authenticationTag";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:prefix authenticationTag:authenticationTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.fullTag isEqualToString:expectedFullTag]);
}

- (void)testInitWithPrefix_Valid_NilPrefixWithAuthenticationTag
{
    NSString *prefix = nil;
    NSString *authenticationTag = @"authenticationTag";
    NSError *error = nil;
    
    NSString *expectedFullTag = @"@authenticationTag";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:prefix authenticationTag:authenticationTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.fullTag isEqualToString:expectedFullTag]);
}

- (void)testInitWithPrefix_Valid_PrefixWithoutAuthenticationTag
{
    NSString *prefix = @"prefix";
    NSString *authenticationTag = @"";
    NSError *error = nil;
    
    NSString *expectedFullTag = @"prefix@";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:prefix authenticationTag:authenticationTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.fullTag isEqualToString:expectedFullTag]);
}

- (void)testInitWithPrefix_Valid_PrefixWithNilAuthenticationTag
{
    NSString *prefix = @"prefix";
    NSString *authenticationTag = nil;
    NSError *error = nil;
    
    NSString *expectedFullTag = @"prefix@";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:prefix authenticationTag:authenticationTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.fullTag isEqualToString:expectedFullTag]);
}

- (void)testInitWithPrefix_Valid_NoPrefixWithNoAuthenticationTag
{
    NSString *prefix = @"";
    NSString *authenticationTag = @"";
    NSError *error = nil;
    
    NSString *expectedFullTag = @"@";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:prefix authenticationTag:authenticationTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.fullTag isEqualToString:expectedFullTag]);
}

- (void)testInitWithPrefix_Valid_NilPrefixWithNilAuthenticationTag
{
    NSString *prefix = nil;
    NSString *authenticationTag = nil;
    NSError *error = nil;
    
    NSString *expectedFullTag = @"@";
    
    QredoAuthenticatedRendezvousTag *tag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:prefix authenticationTag:authenticationTag error:&error];
    XCTAssertNotNil(tag);
    XCTAssertNil(error);
    XCTAssertTrue([tag.fullTag isEqualToString:expectedFullTag]);
}

@end
