/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoClientId.h"

@interface QredoClientIdTests : XCTestCase

@end

@implementation QredoClientIdTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRandomClientId
{
    QredoClientId *clientId1 = [QredoClientId randomClientId];
    QredoClientId *clientId2 = [QredoClientId randomClientId];
    XCTAssertNotNil(clientId1, @"Client ID 1 should not be nil.");
    XCTAssertNotNil(clientId2, @"Client ID 2 should not be nil.");
    XCTAssertNotEqual(clientId1, clientId2, @"Client ID objects should be different.");
    
    NSString *clientId1String = [clientId1 getSafeString];
    NSString *clientId2String = [clientId2 getSafeString];
    XCTAssertNotNil(clientId1String, @"Client ID 1 string should not be nil.");
    XCTAssertNotNil(clientId2String, @"Client ID 2 string should not be nil.");
    XCTAssertFalse([clientId1String isEqualToString:clientId2String], @"Client ID strings should be different");

    NSData *clientId1Data = [clientId1 getData];
    NSData *clientId2Data = [clientId2 getData];
    XCTAssertNotNil(clientId2String, @"Client ID 1 data should not be nil.");
    XCTAssertNotNil(clientId2String, @"Client ID 2 data should not be nil.");
    XCTAssertFalse([clientId1Data isEqualToData:clientId2Data], @"Client ID data should be different");
}

- (void)testClientIdFromData
{
    NSData *clientIdData = [@"1234567890123456" dataUsingEncoding:NSUTF8StringEncoding];

    QredoClientId *clientId = [QredoClientId clientIdFromData:clientIdData];
    XCTAssertNotNil(clientId, @"Client ID should not be nil.");
    
    NSData *actualClientIdData = [clientId getData];
    XCTAssertNotNil(clientId, @"Data should not be nil.");
    XCTAssertTrue([actualClientIdData isEqualToData:clientIdData], @"Client ID data does not match that used to create the object");
}

- (void)testClientIdFromData_TooShortData
{
    NSData *clientIdData = [@"123456789012345" dataUsingEncoding:NSUTF8StringEncoding];
    
    XCTAssertThrowsSpecificNamed([QredoClientId clientIdFromData:clientIdData], NSException, NSInvalidArgumentException, @"Passed invalid length data to clientIdFromData and  NSInvalidArgumentException not thrown.");
}

- (void)testClientIdFromData_TooLongData
{
    NSData *clientIdData = [@"12345678901234567" dataUsingEncoding:NSUTF8StringEncoding];
    
    XCTAssertThrowsSpecificNamed([QredoClientId clientIdFromData:clientIdData], NSException, NSInvalidArgumentException, @"Passed invalid length data to clientIdFromData and  NSInvalidArgumentException not thrown.");
}

- (void)testGetData_RoundTrip
{
    NSData *clientIdData = [@"1234567890123456" dataUsingEncoding:NSUTF8StringEncoding];
    
    QredoClientId *clientId = [QredoClientId clientIdFromData:clientIdData];
    
    NSData *actualClientIdData = [clientId getData];
    XCTAssertTrue([actualClientIdData isEqualToData:clientIdData], @"Client ID data does not match that used to create the object");
}

- (void)testGetString
{
    /*
    
     Input data (hex)= 01020304050607080910111213141516
     Base64 string = AQIDBAUGBwgJEBESExQVFg==
     Topic safe string = AQIDBAUGBwgJEBESExQVFg==
     Remove padding string = AQIDBAUGBwgJEBESExQVFg
     Final string = AQIDBAUGBwgJEBESExQVFg
     
     */
    
    uint8_t clientIdArray[] = {0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16};
    NSData *clientIdData = [NSData dataWithBytes:clientIdArray length:sizeof(clientIdArray) / sizeof(uint8_t)];
    NSString *expectedClientIdString = @"AQIDBAUGBwgJEBESExQVFg";
    
    QredoClientId *clientId = [QredoClientId clientIdFromData:clientIdData];
    
    NSString *actualClientIdString = [clientId getSafeString];
    XCTAssertTrue([actualClientIdString isEqualToString:expectedClientIdString], @"Client ID string is not correct.");
    XCTAssertFalse([actualClientIdString containsString:@"+"], @"Safe string should not contain +");
    XCTAssertFalse([actualClientIdString containsString:@"/"], @"Safe string should not contain /");
}

- (void)testGetString_CheckTopicSafeChangesPlus
{
    /*
     
     Input data (hex)= A2B3DFF227DC404F9F62F106BE2D888E
     Base64 string = orPf8ifcQE+fYvEGvi2Ijg==
     Topic safe string = orPf8ifcQE-fYvEGvi2Ijg==
     Remove padding string = orPf8ifcQE-fYvEGvi2Ijg
     Final string = orPf8ifcQE-fYvEGvi2Ijg
     
     */
    
    uint8_t clientIdArray[] = {0xA2,0xB3,0xDF,0xF2,0x27,0xDC,0x40,0x4F,0x9F,0x62,0xF1,0x06,0xBE,0x2D,0x88,0x8E};
    NSData *clientIdData = [NSData dataWithBytes:clientIdArray length:sizeof(clientIdArray) / sizeof(uint8_t)];
    NSString *expectedClientIdString = @"orPf8ifcQE-fYvEGvi2Ijg";
    
    QredoClientId *clientId = [QredoClientId clientIdFromData:clientIdData];
    
    NSString *actualClientIdString = [clientId getSafeString];
    XCTAssertTrue([actualClientIdString isEqualToString:expectedClientIdString], @"Client ID string is not correct.");
    XCTAssertFalse([actualClientIdString containsString:@"+"], @"Safe string should not contain +");
    XCTAssertFalse([actualClientIdString containsString:@"/"], @"Safe string should not contain /");
    XCTAssertTrue([actualClientIdString containsString:@"-"], @"Safe string should have replaced + with -");
}

- (void)testGetString_CheckTopicSafeChangesSlash
{
    /*
     
     Input data (hex)= 048AFFD73F064C2AB7C67E804CF87B35
     Base64 string = BIr/1z8GTCq3xn6ATPh7NQ==
     Topic safe string = BIr_1z8GTCq3xn6ATPh7NQ==
     Remove padding string = BIr_1z8GTCq3xn6ATPh7NQ
     Final string = BIr_1z8GTCq3xn6ATPh7NQ
     
     */
    
    uint8_t clientIdArray[] = {0x04,0x8A,0xFF,0xD7,0x3F,0x06,0x4C,0x2A,0xB7,0xC6,0x7E,0x80,0x4C,0xF8,0x7B,0x35};
    NSData *clientIdData = [NSData dataWithBytes:clientIdArray length:sizeof(clientIdArray) / sizeof(uint8_t)];
    NSString *expectedClientIdString = @"BIr_1z8GTCq3xn6ATPh7NQ";
    
    QredoClientId *clientId = [QredoClientId clientIdFromData:clientIdData];
    
    NSString *actualClientIdString = [clientId getSafeString];
    XCTAssertTrue([actualClientIdString isEqualToString:expectedClientIdString], @"Client ID string is not correct.");
    XCTAssertFalse([actualClientIdString containsString:@"+"], @"Safe string should not contain +");
    XCTAssertFalse([actualClientIdString containsString:@"/"], @"Safe string should not contain /");
    XCTAssertTrue([actualClientIdString containsString:@"_"], @"Safe string should have replaced / with _");
}

@end
