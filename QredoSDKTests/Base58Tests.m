/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "QredoBase58.h"

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>



@interface Base58Tests : XCTestCase

@end

@implementation Base58Tests

- (void)testSimpleEncoding {
    
    NSMutableData *data8 = [NSMutableData dataWithLength:1];
    unsigned char *data8Bytes = [data8 mutableBytes];
    NSUInteger data8Length = [data8 length];
    data8Bytes[data8Length-1] = 8;
    
    NSString *result = [QredoBase58 encodeData:data8];
    XCTAssertEqualObjects(result, @"9");
    
}

- (void)testSimpleDecoding {
    
    NSString *string9 = @"9";
    NSData *data8 = [QredoBase58 decodeData:string9];
    XCTAssertNotNil(data8);
    
    NSUInteger data8Length = [data8 length];
    XCTAssertEqual(data8Length, 1);
    
    unsigned char *data8Bytes = (unsigned char *)[data8 bytes];
    XCTAssertEqual(data8Bytes[0], 8);
    
}

- (void)testEncodingAndDecoding {
    
    NSData *dataToEncode = [@"My test data" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *encodedString = [QredoBase58 encodeData:dataToEncode];
    XCTAssertNotNil(encodedString);
    
    NSData *decodedData = [QredoBase58 decodeData:encodedString];
    XCTAssertNotNil(decodedData);
    XCTAssertEqualObjects(decodedData, dataToEncode);
    
}

- (void)testEncodingAndDecodingWithZerosPadding {
    
    
    NSData *nonZeroPaddedData = [@"My test data" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *zeroPaddedData = [NSMutableData dataWithLength:5];
    [zeroPaddedData appendData:nonZeroPaddedData];
    
    NSData *dataToEncode = [NSData dataWithData:zeroPaddedData];
    
    NSString *encodedString = [QredoBase58 encodeData:dataToEncode];
    XCTAssertNotNil(encodedString);
    
    NSData *decodedData = [QredoBase58 decodeData:encodedString];
    XCTAssertNotNil(decodedData);
    XCTAssertEqualObjects(decodedData, dataToEncode);
    
}

@end



