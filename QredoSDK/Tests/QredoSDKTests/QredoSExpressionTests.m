#import <XCTest/XCTest.h>
#import "QredoSExpression.h"
#import "QredoXCTestCase.h"

@interface QredoSExpressionTests : QredoXCTestCase

@end

@implementation QredoSExpressionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testReadWriteEmptyList {
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoSExpressionWriter *writer = [QredoSExpressionWriter sexpressionWriterForOutputStream:out];
    [writer writeLeftParen];
    [writer writeRightParen];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoSExpressionReader *reader = [QredoSExpressionReader sexpressionReaderForInputStream:in];
    [reader readLeftParen];
    [reader readRightParen];
    XCTAssertTrue([reader isExhausted], @"Expected reader stream to be exhausted.");
    [in close];
    
}

- (void)testReadWriteListOfSingleAtom {
    
    uint8_t testAtom[6] = {1, 2, 3, 4, 5, 6};
    NSData  *testData = [NSData dataWithBytes:testAtom length:sizeof(testAtom)];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoSExpressionWriter *writer = [QredoSExpressionWriter sexpressionWriterForOutputStream:out];
    [writer writeLeftParen];
    [writer writeAtom:testData];
    [writer writeRightParen];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoSExpressionReader *reader = [QredoSExpressionReader sexpressionReaderForInputStream:in];
    [reader readLeftParen];
    NSData *atom = [reader readAtom];
    XCTAssertTrue([atom isEqualToData:testData], @"Expected read data to match written data.");
    [reader readRightParen];
    XCTAssertTrue([reader isExhausted], @"Expected reader stream to be exhausted.");
    [in close];
    
}

- (void)testReadWriteMultipleAtomList {
    uint8_t testAtom1[6]  = { 1,  2,  3,  4,  5,  6};
    uint8_t testAtom2[8]  = { 7,  8,  9, 10, 11, 12, 13, 14};
    uint8_t testAtom3[14] = {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28};
    NSData  *testData1 = [NSData dataWithBytes:testAtom1 length:sizeof(testAtom1)];
    NSData  *testData2 = [NSData dataWithBytes:testAtom2 length:sizeof(testAtom2)];
    NSData  *testData3 = [NSData dataWithBytes:testAtom3 length:sizeof(testAtom3)];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoSExpressionWriter *writer = [QredoSExpressionWriter sexpressionWriterForOutputStream:out];
    [writer writeLeftParen];
    [writer writeAtom:testData1];
    [writer writeAtom:testData2];
    [writer writeAtom:testData3];
    [writer writeRightParen];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoSExpressionReader *reader = [QredoSExpressionReader sexpressionReaderForInputStream:in];
    [reader readLeftParen];
    NSData *atom1 = [reader readAtom];
    NSData *atom2 = [reader readAtom];
    NSData *atom3 = [reader readAtom];
    XCTAssertTrue([atom1 isEqualToData:testData1], @"Expected read data to match written data.");
    XCTAssertTrue([atom2 isEqualToData:testData2], @"Expected read data to match written data.");
    XCTAssertTrue([atom3 isEqualToData:testData3], @"Expected read data to match written data.");
    [reader readRightParen];
    XCTAssertTrue([reader isExhausted], @"Expected reader stream to be exhausted.");
    [in close];
}

- (void)testReadWriteComplexStructure {
    
    uint8_t testAtom1[6]  = { 1,  2,  3,  4,  5,  6};
    uint8_t testAtom2[8]  = { 7,  8,  9, 10, 11, 12, 13, 14};
    uint8_t testAtom3[14] = {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28};
    NSData  *testData1 = [NSData dataWithBytes:testAtom1 length:sizeof(testAtom1)];
    NSData  *testData2 = [NSData dataWithBytes:testAtom2 length:sizeof(testAtom2)];
    NSData  *testData3 = [NSData dataWithBytes:testAtom3 length:sizeof(testAtom3)];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoSExpressionWriter *writer = [QredoSExpressionWriter sexpressionWriterForOutputStream:out];
    [writer writeLeftParen];
    [writer writeAtom:testData1];
    [writer writeLeftParen];
    [writer writeAtom:testData2];
    [writer writeRightParen];
    [writer writeAtom:testData3];
    [writer writeRightParen];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoSExpressionReader *reader = [QredoSExpressionReader sexpressionReaderForInputStream:in];
    [reader readLeftParen];
    NSData *atom1 = [reader readAtom];
    [reader readLeftParen];
    NSData *atom2 = [reader readAtom];
    [reader readRightParen];
    NSData *atom3 = [reader readAtom];
    [reader readRightParen];
    XCTAssertTrue([reader isExhausted], @"Expected reader stream to be exhausted.");
    XCTAssertTrue([atom1 isEqualToData:testData1], @"Expected read data to match written data.");
    XCTAssertTrue([atom2 isEqualToData:testData2], @"Expected read data to match written data.");
    XCTAssertTrue([atom3 isEqualToData:testData3], @"Expected read data to match written data.");
    [in close];
    
}

- (void)testReadAhead {
    uint8_t testAtom1[6]  = { 1,  2,  3,  4,  5,  6};
    uint8_t testAtom2[8]  = { 7,  8,  9, 10, 11, 12, 13, 14};
    uint8_t testAtom3[14] = {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28};
    NSData  *testData1 = [NSData dataWithBytes:testAtom1 length:sizeof(testAtom1)];
    NSData  *testData2 = [NSData dataWithBytes:testAtom2 length:sizeof(testAtom2)];
    NSData  *testData3 = [NSData dataWithBytes:testAtom3 length:sizeof(testAtom3)];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoSExpressionWriter *writer = [QredoSExpressionWriter sexpressionWriterForOutputStream:out];
    [writer writeLeftParen];
    [writer writeAtom:testData1];
    [writer writeLeftParen];
    [writer writeAtom:testData2];
    [writer writeRightParen];
    [writer writeAtom:testData3];
    [writer writeRightParen];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoSExpressionReader *reader = [QredoSExpressionReader sexpressionReaderForInputStream:in];
    QredoToken lookAheadParen1 = [reader lookAhead];
    [reader readLeftParen];
    QredoToken lookAheadAtom1 = [reader lookAhead];
    NSData *atom1 = [reader readAtom];
    QredoToken lookAheadParen2 = [reader lookAhead];
    [reader readLeftParen];
    QredoToken lookAheadAtom2 = [reader lookAhead];
    NSData *atom2 = [reader readAtom];
    QredoToken lookAheadParen3 = [reader lookAhead];
    [reader readRightParen];
    QredoToken lookAheadAtom3 = [reader lookAhead];
    NSData *atom3 = [reader readAtom];
    QredoToken lookAheadParen4 = [reader lookAhead];
    [reader readRightParen];
    QredoToken lookAheadEOF = [reader lookAhead];
    [in close];
    
    XCTAssertTrue([reader isExhausted], @"Expected reader stream to be exhausted.");
    XCTAssertTrue([atom1 isEqualToData:testData1], @"Expected read data to match written data.");
    XCTAssertTrue([atom2 isEqualToData:testData2], @"Expected read data to match written data.");
    XCTAssertTrue([atom3 isEqualToData:testData3], @"Expected read data to match written data.");
    
    XCTAssertEqual(lookAheadParen1, QredoTokenLParen);
    XCTAssertEqual(lookAheadParen2, QredoTokenLParen);
    XCTAssertEqual(lookAheadParen3, QredoTokenRParen);
    XCTAssertEqual(lookAheadParen4, QredoTokenRParen);
    XCTAssertEqual(lookAheadAtom1, QredoTokenAtom);
    XCTAssertEqual(lookAheadAtom2, QredoTokenAtom);
    XCTAssertEqual(lookAheadAtom3, QredoTokenAtom);
    XCTAssertEqual(lookAheadEOF, QredoTokenEnd);
}

@end
