/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "QredoBase58.h"

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>



static inline NSData *createRandomData() {
    
    const NSUInteger dataLength = rand() % 64;
    unsigned char *dataBytes = malloc(dataLength);
    
    // Generate random data.
    for (int byteIndex = 0; byteIndex < dataLength; byteIndex++) {
        dataBytes[byteIndex] = rand() % 0x100;
    }
    
    return [NSData dataWithBytesNoCopy:dataBytes length:dataLength];
    
}

static inline NSString *createRandomEncodedValue() {
    
    static const char kAlphabet[] = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    
    const NSUInteger dataLength = rand() % 100;
    unichar *dataBytes = malloc(dataLength * sizeof(const unichar));
    
    // Generate random data.
    for (int byteIndex = 0; byteIndex < dataLength; byteIndex++) {
        dataBytes[byteIndex] = kAlphabet[rand() % 58];
    }
    
    return [NSString stringWithCharacters:dataBytes length:dataLength];
}


@interface Base58Tests : XCTestCase

@end

@implementation Base58Tests

- (void)test_0010_SimpleEncoding {
    
    NSMutableData *data8 = [NSMutableData dataWithLength:1];
    unsigned char *data8Bytes = [data8 mutableBytes];
    NSUInteger data8Length = [data8 length];
    data8Bytes[data8Length-1] = 8;
    
    NSString *result = [QredoBase58 encodeData:data8];
    XCTAssertEqualObjects(result, @"9");
    
}

- (void)test_0020_SimpleDecoding {
    
    NSString *string9 = @"9";
    NSData *data8 = [QredoBase58 decodeData:string9];
    XCTAssertNotNil(data8);
    
    NSUInteger data8Length = [data8 length];
    XCTAssertEqual(data8Length, 1);
    
    unsigned char *data8Bytes = (unsigned char *)[data8 bytes];
    XCTAssertEqual(data8Bytes[0], 8);
    
}

- (void)test_0030_EncodingAndDecoding {
    
    NSData *dataToEncode = [@"My test data" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *encodedString = [QredoBase58 encodeData:dataToEncode];
    XCTAssertNotNil(encodedString);
    
    NSData *decodedData = [QredoBase58 decodeData:encodedString];
    XCTAssertNotNil(decodedData);
    XCTAssertEqualObjects(decodedData, dataToEncode);
    
}

- (void)test_0040_EncodingAndDecodingWithZerosPadding {
    
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

- (void)test_0050_EncodingAndDecodingRandomEquality {
    
    NSUInteger kIterations = 1000000;
    srand ( (int)time(NULL) );
    
    for (int i = 1; i <= kIterations; i++) {
        
        NSData *dataToEncode = createRandomData();
        NSString *encodedValue = [QredoBase58 encodeData:dataToEncode];
        NSData *decodedData = [QredoBase58 decodeData:encodedValue];
        
        if (![dataToEncode isEqual:decodedData]) {
            XCTFail("Encoding or decoding faild. Data to encode: <%@>, decoded data: <%@>",
                    dataToEncode, decodedData);
        }
        
        if ((i % 10000) == 0) {
            NSLog(@"[Base58Tests testRandomEquality] iterations: %@k", @(i/1000));
        }
        
    }
    
}

- (void)test_0060_DecodingAndEncodingRandomEquality {
    
    NSUInteger kIterations = 1000000;
    srand ( (int)time(NULL) );
    
    for (int i = 1; i <= kIterations; i++) {
        
        NSString *valueToDecode = createRandomEncodedValue();
        NSData *encodedData = [QredoBase58 decodeData:valueToDecode];
        NSString *encodedValue = [QredoBase58 encodeData:encodedData];
        
        if (![valueToDecode isEqualToString:encodedValue]) {
            XCTFail("Encoding or decoding faild. Value to encode: <%@>, encoded value: <%@>",
                    valueToDecode, encodedValue);
        }
        
        if ((i % 10000) == 0) {
            NSLog(@"[Base58Tests testRandomEquality] iterations: %@k", @(i/1000));
        }
        
    }
    
}

- (void)test_0070_EncodingRandomInequality {
    
    NSUInteger kIterations = 1000000;
    srand ( (int)time(NULL) );
    
    for (int i = 1; i <= kIterations; i++) {
        
        
        NSData *dataToEncode1 = createRandomData();
        NSData *dataToEncode2 = createRandomData();
        while ([dataToEncode1 isEqual:dataToEncode2]) {
            dataToEncode2 = createRandomData();
        }
        
        NSString *encodedValue1 = [QredoBase58 encodeData:dataToEncode1];
        NSString *encodedValue2 = [QredoBase58 encodeData:dataToEncode2];
        
        if ([encodedValue1 isEqual:encodedValue2]) {
            XCTFail("Encoding of diffent data resulted in same encoded value. Data to encode 1: <%@>, data to encode 2: <%@>, endoded value: <%@>",
                    dataToEncode1, dataToEncode2, encodedValue1);
        }
        
        if ((i % 10000) == 0) {
            NSLog(@"[Base58Tests testRandomEquality] iterations: %@k", @(i/1000));
        }
        
    }
    
}

- (void)test_0080_DecodingRandomInequality {
    
    NSUInteger kIterations = 1000000;
    srand ( (int)time(NULL) );
    
    for (int i = 1; i <= kIterations; i++) {
        
        NSString *valueToDecode1 = createRandomEncodedValue();
        NSString *valueToDecode2 = createRandomEncodedValue();
        while ([valueToDecode1 isEqualToString:valueToDecode2]) {
            valueToDecode2 = createRandomEncodedValue();
        }
        
        NSData *decodedData1 = [QredoBase58 decodeData:valueToDecode1];
        NSData *decodedData2 = [QredoBase58 decodeData:valueToDecode2];
        
        if ([decodedData1 isEqual:decodedData2]) {
            XCTFail("Decoding of diffent values resulted in same decoded data. Value to decode 1: <%@>, value to decode 2: <%@>, decoded data: <%@>",
                    valueToDecode1, valueToDecode2, decodedData1);
        }
        
        if ((i % 10000) == 0) {
            NSLog(@"[Base58Tests testRandomEquality] iterations: %@k", @(i/1000));
        }
        
    }
    
}

@end



