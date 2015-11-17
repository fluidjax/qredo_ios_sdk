#import <XCTest/XCTest.h>
#import "NSData+QredoRandomData.h"
#import "QredoWireFormat.h"
#import "QredoQUID.h"

@interface QredoWireFormatTests : XCTestCase

@end

@implementation QredoWireFormatTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBoolean {
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeBoolean:@TRUE];
    [writer writeBoolean:@FALSE];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    NSNumber *boolean1 = [reader readBoolean];
    NSNumber *boolean2 = [reader readBoolean];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([boolean1 boolValue]);
    XCTAssertFalse([boolean2 boolValue]);
    
}

- (void)testByte {
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeByte:@0];
    [writer writeByte:@1];
    [writer writeByte:@2];
    [writer writeByte:@3];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    NSNumber *byte1 = [reader readByte];
    NSNumber *byte2 = [reader readByte];
    NSNumber *byte3 = [reader readByte];
    NSNumber *byte4 = [reader readByte];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([byte1 isEqualToNumber:@0]);
    XCTAssertTrue([byte2 isEqualToNumber:@1]);
    XCTAssertTrue([byte3 isEqualToNumber:@2]);
    XCTAssertTrue([byte4 isEqualToNumber:@3]);
    
}

- (void)testByteSequence {
    
    uint8_t testBytes1[6]  = {1, 2, 3, 4, 5, 6};
    uint8_t testBytes2[10] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    uint8_t testBytes3[12] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
    
    NSData *testData1 = [NSData dataWithBytes:testBytes1 length:sizeof(testBytes1)];
    NSData *testData2 = [NSData dataWithBytes:testBytes2 length:sizeof(testBytes2)];
    NSData *testData3 = [NSData dataWithBytes:testBytes3 length:sizeof(testBytes3)];
    
    __block NSData *actualData1;
    __block NSData *actualData2;
    __block NSData *actualData3;
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeByteSequence:testData1];
    [writer writeByteSequence:testData2];
    [writer writeByteSequence:testData3];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    actualData1 = [reader readByteSequence];
    actualData2 = [reader readByteSequence];
    actualData3 = [reader readByteSequence];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([actualData1 isEqualToData:testData1]);
    XCTAssertTrue([actualData2 isEqualToData:testData2]);
    XCTAssertTrue([actualData3 isEqualToData:testData3]);
    
}

- (void)testDate {
    
    QredoDate *testDate1 = [QredoDate dateWithYear:1983 month:4  day:12];
    QredoDate *testDate2 = [QredoDate dateWithYear:1982 month:1  day:1];
    QredoDate *testDate3 = [QredoDate dateWithYear:2006 month:2  day:15];
    QredoDate *testDate4 = [QredoDate dateWithYear:2009 month:11 day:25];
    QredoDate *testDate5 = [QredoDate dateWithYear:2013 month:12 day:23];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeDate:testDate1];
    [writer writeDate:testDate2];
    [writer writeDate:testDate3];
    [writer writeDate:testDate4];
    [writer writeDate:testDate5];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoDate *actualDate1 = [reader readDate];
    QredoDate *actualDate2 = [reader readDate];
    QredoDate *actualDate3 = [reader readDate];
    QredoDate *actualDate4 = [reader readDate];
    QredoDate *actualDate5 = [reader readDate];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualDate1);
    XCTAssertTrue([actualDate1 year]  == 1983);
    XCTAssertTrue([actualDate1 month] == 4);
    XCTAssertTrue([actualDate1 day]   == 12);
    
    XCTAssertNotNil(actualDate2);
    XCTAssertTrue([actualDate2 year]  == 1982);
    XCTAssertTrue([actualDate2 month] == 1);
    XCTAssertTrue([actualDate2 day]   == 1);
    
    XCTAssertNotNil(actualDate3);
    XCTAssertTrue([actualDate3 year]  == 2006);
    XCTAssertTrue([actualDate3 month] == 2);
    XCTAssertTrue([actualDate3 day]   == 15);
    
    XCTAssertNotNil(actualDate4);
    XCTAssertTrue([actualDate4 year]  == 2009);
    XCTAssertTrue([actualDate4 month] == 11);
    XCTAssertTrue([actualDate4 day]   == 25);
    
    XCTAssertNotNil(actualDate5);
    XCTAssertTrue([actualDate5 year]  == 2013);
    XCTAssertTrue([actualDate5 month] == 12);
    XCTAssertTrue([actualDate5 day]   == 23);
    
}

- (void)testDateFromNSDate {
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:-559310400];
    QredoDate *testDate = [QredoDate dateWithDate:date];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeDate:testDate];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoDate *actualDate = [reader readDate];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualDate);
    XCTAssertTrue(actualDate.year  == 1983);
    XCTAssertTrue(actualDate.month == 4);
    XCTAssertTrue(actualDate.day   == 12);
    
}

- (void)testDateFromNSDateComponents {
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    [dateComponents setYear:1983];
    [dateComponents setMonth:4];
    [dateComponents setDay:12];
    QredoDate *testDate = [QredoDate dateWithDateComponents:dateComponents];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeDate:testDate];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoDate *actualDate = [reader readDate];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualDate);
    XCTAssertTrue(actualDate.year  == 1983);
    XCTAssertTrue(actualDate.month == 4);
    XCTAssertTrue(actualDate.day   == 12);
    
}

- (void)testGenericDateTime {
    
    QredoDate *date = [QredoDate dateWithYear:1983 month:4 day:12];
    QredoTime *time = [QredoTime timeWithMillisSinceMidnight:1000];
    QredoDateTime *testGenericDateTime1 = [QredoDateTime dateTimeWithDate:date time:time isUTC:true];
    QredoDateTime *testGenericDateTime2 = [QredoDateTime dateTimeWithDate:date time:time isUTC:false];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeGenericDateTime:testGenericDateTime1];
    [writer writeGenericDateTime:testGenericDateTime2];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoDateTime *actualGenericDateTime1 = [reader readGenericDateTime];
    QredoDateTime *actualGenericDateTime2 = [reader readGenericDateTime];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualGenericDateTime1);
    XCTAssertNotNil(actualGenericDateTime2);
    
    XCTAssertTrue([actualGenericDateTime1 isMemberOfClass:[QredoUTCDateTime class]]);
    XCTAssertTrue([[actualGenericDateTime1 date] year]  == 1983);
    XCTAssertTrue([[actualGenericDateTime1 date] month] == 4);
    XCTAssertTrue([[actualGenericDateTime1 date] day]   == 12);
    XCTAssertTrue([[actualGenericDateTime1 time] millisSinceMidnight] == 1000);

    XCTAssertTrue([actualGenericDateTime2 isMemberOfClass:[QredoLocalDateTime class]]);
    XCTAssertTrue([[actualGenericDateTime2 date] year]  == 1983);
    XCTAssertTrue([[actualGenericDateTime2 date] month] == 4);
    XCTAssertTrue([[actualGenericDateTime2 date] day]   == 12);
    XCTAssertTrue([[actualGenericDateTime2 time] millisSinceMidnight] == 1000);
    
}

- (void)testInt32 {
    
    NSNumber *testInt1 = [NSNumber numberWithLongLong:-1000000000000LL]; // Should underflow.
    NSNumber *testInt2 = [NSNumber numberWithLong:-1000000000L];
    NSNumber *testInt3 = [NSNumber numberWithLong:-1000000L];
    NSNumber *testInt4 = [NSNumber numberWithLong:-1000L];
    NSNumber *testInt5 = [NSNumber numberWithLong:0L];
    NSNumber *testInt6 = [NSNumber numberWithLong:1000L];
    NSNumber *testInt7 = [NSNumber numberWithLong:1000000L];
    NSNumber *testInt8 = [NSNumber numberWithLong:1000000000L];
    NSNumber *testInt9 = [NSNumber numberWithLongLong:1000000000000LL];  // Should overflow.
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeInt32:testInt1];
    [writer writeInt32:testInt2];
    [writer writeInt32:testInt3];
    [writer writeInt32:testInt4];
    [writer writeInt32:testInt5];
    [writer writeInt32:testInt6];
    [writer writeInt32:testInt7];
    [writer writeInt32:testInt8];
    [writer writeInt32:testInt9];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    NSNumber *actualInt1 = [reader readInt32];
    NSNumber *actualInt2 = [reader readInt32];
    NSNumber *actualInt3 = [reader readInt32];
    NSNumber *actualInt4 = [reader readInt32];
    NSNumber *actualInt5 = [reader readInt32];
    NSNumber *actualInt6 = [reader readInt32];
    NSNumber *actualInt7 = [reader readInt32];
    NSNumber *actualInt8 = [reader readInt32];
    NSNumber *actualInt9 = [reader readInt32];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertFalse([actualInt1 isEqualToNumber:testInt1]);
    XCTAssertTrue([actualInt2 isEqualToNumber:testInt2]);
    XCTAssertTrue([actualInt3 isEqualToNumber:testInt3]);
    XCTAssertTrue([actualInt4 isEqualToNumber:testInt4]);
    XCTAssertTrue([actualInt5 isEqualToNumber:testInt5]);
    XCTAssertTrue([actualInt6 isEqualToNumber:testInt6]);
    XCTAssertTrue([actualInt7 isEqualToNumber:testInt7]);
    XCTAssertTrue([actualInt8 isEqualToNumber:testInt8]);
    XCTAssertFalse([actualInt9 isEqualToNumber:testInt9]);
    
}

- (void)testInt64 {

    NSNumber *testInt1 = [NSNumber numberWithLongLong:-9223372036854775807LL];
    NSNumber *testInt2 = [NSNumber numberWithLongLong:-1000000LL];
    NSNumber *testInt3 = [NSNumber numberWithLongLong:0LL];
    NSNumber *testInt4 = [NSNumber numberWithLongLong:1000000LL];
    NSNumber *testInt5 = [NSNumber numberWithLongLong:9223372036854775807LL];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeInt64:testInt1];
    [writer writeInt64:testInt2];
    [writer writeInt64:testInt3];
    [writer writeInt64:testInt4];
    [writer writeInt64:testInt5];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    NSNumber *actualInt1 = [reader readInt64];
    NSNumber *actualInt2 = [reader readInt64];
    NSNumber *actualInt3 = [reader readInt64];
    NSNumber *actualInt4 = [reader readInt64];
    NSNumber *actualInt5 = [reader readInt64];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([actualInt1 isEqualToNumber:testInt1]);
    XCTAssertTrue([actualInt2 isEqualToNumber:testInt2]);
    XCTAssertTrue([actualInt3 isEqualToNumber:testInt3]);
    XCTAssertTrue([actualInt4 isEqualToNumber:testInt4]);
    XCTAssertTrue([actualInt5 isEqualToNumber:testInt5]);
    
}

- (void)testLocalDateTime {
    
    QredoDate *date1 = [QredoDate dateWithYear:1983 month:4 day:12];
    QredoTime *time1 = [QredoTime timeWithMillisSinceMidnight:1000];
    QredoDate *date2 = [QredoDate dateWithYear:1982 month:1 day:1];
    QredoTime *time2 = [QredoTime timeWithMillisSinceMidnight:4000];
    QredoLocalDateTime *testLocalDateTime1 = (QredoLocalDateTime *)[QredoDateTime dateTimeWithDate:date1 time:time1 isUTC:false];
    QredoLocalDateTime *testLocalDateTime2 = (QredoLocalDateTime *)[QredoDateTime dateTimeWithDate:date2 time:time2 isUTC:false];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeLocalDateTime:testLocalDateTime1];
    [writer writeLocalDateTime:testLocalDateTime2];
    [writer writeGenericDateTime:testLocalDateTime1];
    [writer writeGenericDateTime:testLocalDateTime2];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoLocalDateTime *actualLocalDateTime1 = [reader readLocalDateTime];
    QredoLocalDateTime *actualLocalDateTime2 = [reader readLocalDateTime];
    QredoDateTime *actualGenericDateTime3    = [reader readGenericDateTime];
    QredoDateTime *actualGenericDateTime4    = [reader readGenericDateTime];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualLocalDateTime1);
    XCTAssertNotNil(actualLocalDateTime2);
    XCTAssertNotNil(actualGenericDateTime3);
    XCTAssertNotNil(actualGenericDateTime4);
    
    XCTAssertTrue([[actualLocalDateTime1 date] year]  == 1983);
    XCTAssertTrue([[actualLocalDateTime1 date] month] == 4);
    XCTAssertTrue([[actualLocalDateTime1 date] day]   == 12);
    XCTAssertTrue([[actualLocalDateTime1 time] millisSinceMidnight] == 1000);
    
    XCTAssertTrue([[actualLocalDateTime2 date] year]  == 1982);
    XCTAssertTrue([[actualLocalDateTime2 date] month] == 1);
    XCTAssertTrue([[actualLocalDateTime2 date] day]   == 1);
    XCTAssertTrue([[actualLocalDateTime2 time] millisSinceMidnight] == 4000);
    
    XCTAssertTrue([actualGenericDateTime3 isMemberOfClass:[QredoLocalDateTime class]]);
    XCTAssertTrue([[actualGenericDateTime3 date] year]  == 1983);
    XCTAssertTrue([[actualGenericDateTime3 date] month] == 4);
    XCTAssertTrue([[actualGenericDateTime3 date] day]   == 12);
    XCTAssertTrue([[actualGenericDateTime3 time] millisSinceMidnight] == 1000);
    
    XCTAssertTrue([actualGenericDateTime4 isMemberOfClass:[QredoLocalDateTime class]]);
    XCTAssertTrue([[actualGenericDateTime4 date] year]  == 1982);
    XCTAssertTrue([[actualGenericDateTime4 date] month] == 1);
    XCTAssertTrue([[actualGenericDateTime4 date] day]   == 1);
    XCTAssertTrue([[actualGenericDateTime4 time] millisSinceMidnight] == 4000);
    
}

- (void)testString {
    
    NSString *testString1 = @"Hello, world!";
    NSString *testString2 = @"";
    NSString *testString3 = @"Thîš īś ä tëßt.";
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeString:testString1];
    [writer writeString:testString2];
    [writer writeString:testString3];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    NSString *actualString1 = [reader readString];
    NSString *actualString2 = [reader readString];
    NSString *actualString3 = [reader readString];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualString1);
    XCTAssertNotNil(actualString2);
    XCTAssertNotNil(actualString3);
    
    XCTAssertTrue([actualString1 isEqualToString:testString1]);
    XCTAssertTrue([actualString2 isEqualToString:testString2]);
    XCTAssertTrue([actualString3 isEqualToString:testString3]);
    
}

- (void)testSymbol {
    
    NSString *testSymbol1 = @"HelloWorld";
    NSString *testSymbol2 = @"";
    NSString *testSymbol3 = @"ThisIsAlsoATest";
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeSymbol:testSymbol1];
    [writer writeSymbol:testSymbol2];
    [writer writeSymbol:testSymbol3];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    NSString *actualSymbol1 = [reader readSymbol];
    NSString *actualSymbol2 = [reader readSymbol];
    NSString *actualSymbol3 = [reader readSymbol];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualSymbol1);
    XCTAssertNotNil(actualSymbol2);
    XCTAssertNotNil(actualSymbol3);
    
    XCTAssertTrue([actualSymbol1 isEqualToString:testSymbol1]);
    XCTAssertTrue([actualSymbol2 isEqualToString:testSymbol2]);
    XCTAssertTrue([actualSymbol3 isEqualToString:testSymbol3]);
    
}

- (void)testTime {
    
    QredoTime *testTime1 = [QredoTime timeWithMillisSinceMidnight:1000];
    QredoTime *testTime2 = [QredoTime timeWithMillisSinceMidnight:2000];
    QredoTime *testTime3 = [QredoTime timeWithMillisSinceMidnight:3000];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeTime:testTime1];
    [writer writeTime:testTime2];
    [writer writeTime:testTime3];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoTime *actualTime1 = [reader readTime];
    QredoTime *actualTime2 = [reader readTime];
    QredoTime *actualTime3 = [reader readTime];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualTime1);
    XCTAssertNotNil(actualTime2);
    XCTAssertNotNil(actualTime3);
    
    XCTAssertTrue(actualTime1.millisSinceMidnight == testTime1.millisSinceMidnight);
    XCTAssertTrue(actualTime2.millisSinceMidnight == testTime2.millisSinceMidnight);
    XCTAssertTrue(actualTime3.millisSinceMidnight == testTime3.millisSinceMidnight);
    
}

- (void)testTimeFromNSDate {
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:-559310400];
    QredoTime *testTime = [QredoTime timeWithDate:date];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeTime:testTime];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoTime *actualTime = [reader readTime];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualTime);
    XCTAssertTrue(actualTime.hour   == 12);
    XCTAssertTrue(actualTime.minute == 0);
    XCTAssertTrue(actualTime.second == 0);
    XCTAssertTrue(actualTime.milli  == 0);
    
}

- (void)testTimeFromNSDateComponents {
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    [dateComponents setHour:12];
    [dateComponents setMinute:34];
    [dateComponents setSecond:56];
    QredoTime *testTime = [QredoTime timeWithDateComponents:dateComponents];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeTime:testTime];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoTime *actualTime = [reader readTime];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualTime);
    XCTAssertTrue(actualTime.hour   == 12);
    XCTAssertTrue(actualTime.minute == 34);
    XCTAssertTrue(actualTime.second == 56);
    XCTAssertTrue(actualTime.milli  == 0);
}

- (void)testQUID {
    
    QredoQUID *testQUID1 = [QredoQUID QUID];
    QredoQUID *testQUID2 = [QredoQUID QUID];
    QredoQUID *testQUID3 = [QredoQUID QUID];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeQUID:testQUID1];
    [writer writeQUID:testQUID2];
    [writer writeQUID:testQUID3];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoQUID *actualQUID1 = [reader readQUID];
    QredoQUID *actualQUID2 = [reader readQUID];
    QredoQUID *actualQUID3 = [reader readQUID];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualQUID1);
    XCTAssertNotNil(actualQUID2);
    XCTAssertNotNil(actualQUID3);
    
    XCTAssertTrue([actualQUID1 isEqual:testQUID1]);
    XCTAssertTrue([actualQUID2 isEqual:testQUID2]);
    XCTAssertTrue([actualQUID3 isEqual:testQUID3]);
    
}

- (void)testUTCDateTime {
    
    QredoDate *date1 = [QredoDate dateWithYear:1983 month:4 day:12];
    QredoTime *time1 = [QredoTime timeWithMillisSinceMidnight:1000];
    QredoDate *date2 = [QredoDate dateWithYear:1982 month:1 day:1];
    QredoTime *time2 = [QredoTime timeWithMillisSinceMidnight:4000];
    QredoUTCDateTime *testUTCDateTime1 = (QredoUTCDateTime *)[QredoDateTime dateTimeWithDate:date1 time:time1 isUTC:true];
    QredoUTCDateTime *testUTCDateTime2 = (QredoUTCDateTime *)[QredoDateTime dateTimeWithDate:date2 time:time2 isUTC:true];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeUTCDateTime:testUTCDateTime1];
    [writer writeUTCDateTime:testUTCDateTime2];
    [writer writeGenericDateTime:testUTCDateTime1];
    [writer writeGenericDateTime:testUTCDateTime2];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoUTCDateTime *actualUTCDateTime1  = [reader readUTCDateTime];
    QredoUTCDateTime *actualUTCDateTime2  = [reader readUTCDateTime];
    QredoDateTime *actualGenericDateTime3 = [reader readGenericDateTime];
    QredoDateTime *actualGenericDateTime4 = [reader readGenericDateTime];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertNotNil(actualUTCDateTime1);
    XCTAssertNotNil(actualUTCDateTime2);
    XCTAssertNotNil(actualGenericDateTime3);
    XCTAssertNotNil(actualGenericDateTime4);
    
    XCTAssertTrue([[actualUTCDateTime1 date] year]  == 1983);
    XCTAssertTrue([[actualUTCDateTime1 date] month] == 4);
    XCTAssertTrue([[actualUTCDateTime1 date] day]   == 12);
    XCTAssertTrue([[actualUTCDateTime1 time] millisSinceMidnight] == 1000);
    
    XCTAssertTrue([[actualUTCDateTime2 date] year]  == 1982);
    XCTAssertTrue([[actualUTCDateTime2 date] month] == 1);
    XCTAssertTrue([[actualUTCDateTime2 date] day]   == 1);
    XCTAssertTrue([[actualUTCDateTime2 time] millisSinceMidnight] == 4000);
    
    XCTAssertTrue([actualGenericDateTime3 isMemberOfClass:[QredoUTCDateTime class]]);
    XCTAssertTrue([[actualGenericDateTime3 date] year]  == 1983);
    XCTAssertTrue([[actualGenericDateTime3 date] month] == 4);
    XCTAssertTrue([[actualGenericDateTime3 date] day]   == 12);
    XCTAssertTrue([[actualGenericDateTime3 time] millisSinceMidnight] == 1000);
    
    XCTAssertTrue([actualGenericDateTime4 isMemberOfClass:[QredoUTCDateTime class]]);
    XCTAssertTrue([[actualGenericDateTime4 date] year]  == 1982);
    XCTAssertTrue([[actualGenericDateTime4 date] month] == 1);
    XCTAssertTrue([[actualGenericDateTime4 date] day]   == 1);
    XCTAssertTrue([[actualGenericDateTime4 time] millisSinceMidnight] == 4000);
    
}

- (void)testMessageHeader {
    
    QredoVersion *protocolVersion = [QredoVersion versionWithMajor:@1 minor:@2 patch:@3];
    QredoVersion *releaseVersion  = [QredoVersion versionWithMajor:@4 minor:@5 patch:@6];
    QredoMessageHeader *messageHeader = [QredoMessageHeader messageHeaderWithProtocolVersion:protocolVersion
                                                                              releaseVersion:releaseVersion];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeMessageHeader:messageHeader];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoMessageHeader *actualMessageHeader = [reader readMessageHeader];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([[[actualMessageHeader protocolVersion] major] isEqualToNumber:[protocolVersion major]]);
    XCTAssertTrue([[[actualMessageHeader protocolVersion] minor] isEqualToNumber:[protocolVersion minor]]);
    XCTAssertTrue([[[actualMessageHeader protocolVersion] patch] isEqualToNumber:[protocolVersion patch]]);
    XCTAssertTrue([[[actualMessageHeader releaseVersion] major] isEqualToNumber:[releaseVersion major]]);
    XCTAssertTrue([[[actualMessageHeader releaseVersion] minor] isEqualToNumber:[releaseVersion minor]]);
    XCTAssertTrue([[[actualMessageHeader releaseVersion] patch] isEqualToNumber:[releaseVersion patch]]);
    
}

- (void)testVersion {
    
    QredoVersion *testVersion1 = [QredoVersion versionWithMajor:@1 minor:@2 patch:@3];
    QredoVersion *testVersion2 = [QredoVersion versionWithMajor:@65535 minor:@65535 patch:@65535];
    QredoVersion *testVersion3 = [QredoVersion versionWithMajor:@0 minor:@0 patch:@0];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeVersion:testVersion1];
    [writer writeVersion:testVersion2];
    [writer writeVersion:testVersion3];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoVersion *actualVersion1 = [reader readVersion];
    QredoVersion *actualVersion2 = [reader readVersion];
    QredoVersion *actualVersion3 = [reader readVersion];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([[actualVersion1 major] isEqualToNumber:[testVersion1 major]]);
    XCTAssertTrue([[actualVersion1 minor] isEqualToNumber:[testVersion1 minor]]);
    XCTAssertTrue([[actualVersion1 patch] isEqualToNumber:[testVersion1 patch]]);
    
    XCTAssertTrue([[actualVersion2 major] isEqualToNumber:[testVersion2 major]]);
    XCTAssertTrue([[actualVersion2 minor] isEqualToNumber:[testVersion2 minor]]);
    XCTAssertTrue([[actualVersion2 patch] isEqualToNumber:[testVersion2 patch]]);
    
    XCTAssertTrue([[actualVersion3 major] isEqualToNumber:[testVersion3 major]]);
    XCTAssertTrue([[actualVersion3 minor] isEqualToNumber:[testVersion3 minor]]);
    XCTAssertTrue([[actualVersion3 patch] isEqualToNumber:[testVersion3 patch]]);
    
}

- (void)testInterchangeHeader {
    
    NSData *testReturnChannelID = [NSData dataWithRandomBytesOfLength:16];
    NSData *testCorrelationID = [NSData dataWithRandomBytesOfLength:16];
    NSString *testServiceName = @"ServiceName";
    NSString *testOperationName =@"OperationName";
    
    QredoInterchangeHeader *testInterchangeHeader =
        [QredoInterchangeHeader interchangeHeaderWithReturnChannelID:testReturnChannelID
                                                       correlationID:testCorrelationID
                                                         serviceName:testServiceName
                                                       operationName:testOperationName];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeInterchangeHeader:testInterchangeHeader];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoInterchangeHeader *actualInterchangeHeader = [reader readInterchangeHeader];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([[actualInterchangeHeader returnChannelID] isEqualToData:testReturnChannelID]);
    XCTAssertTrue([[actualInterchangeHeader correlationID]   isEqualToData:testCorrelationID]);
    XCTAssertTrue([[actualInterchangeHeader serviceName]     isEqualToString:testServiceName]);
    XCTAssertTrue([[actualInterchangeHeader operationName]   isEqualToString:testOperationName]);
    
}

- (void)testInvocationHeader {
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeInvocationHeader:[QredoAppCredentials empty]];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    [reader readInvocationHeader];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
}

- (void)testSequence {
    
    NSString *testString1 = @"Test String 1";
    NSString *testString2 = @"Test String 2";
    NSString *testString3 = @"Test String 3";
    NSString *testString4 = @"Test String 4";
    NSString *testString5 = @"Test String 5";
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeSequenceStart];
    [writer writeString:testString1];
    [writer writeString:testString2];
    [writer writeString:testString3];
    [writer writeString:testString4];
    [writer writeString:testString5];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readSequenceStart];
    NSString *actualString1 = [reader readString];
    NSString *actualString2 = [reader readString];
    NSString *actualString3 = [reader readString];
    NSString *actualString4 = [reader readString];
    NSString *actualString5 = [reader readString];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([actualString1 isEqualToString:testString1]);
    XCTAssertTrue([actualString2 isEqualToString:testString2]);
    XCTAssertTrue([actualString3 isEqualToString:testString3]);
    XCTAssertTrue([actualString4 isEqualToString:testString4]);
    XCTAssertTrue([actualString5 isEqualToString:testString5]);
    
}

- (void)testSet {
    
    NSString *testString1 = @"Test String 1";
    NSString *testString2 = @"Test String 2";
    NSString *testString3 = @"Test String 3";
    NSString *testString4 = @"Test String 4";
    NSString *testString5 = @"Test String 5";
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeSetStart];
    [writer writeString:testString1];
    [writer writeString:testString2];
    [writer writeString:testString3];
    [writer writeString:testString4];
    [writer writeString:testString5];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readSetStart];
    NSString *actualString1 = [reader readString];
    NSString *actualString2 = [reader readString];
    NSString *actualString3 = [reader readString];
    NSString *actualString4 = [reader readString];
    NSString *actualString5 = [reader readString];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([actualString1 isEqualToString:testString1]);
    XCTAssertTrue([actualString2 isEqualToString:testString2]);
    XCTAssertTrue([actualString3 isEqualToString:testString3]);
    XCTAssertTrue([actualString4 isEqualToString:testString4]);
    XCTAssertTrue([actualString5 isEqualToString:testString5]);
    
}

- (void)testConstructorFields {
    
    NSString *testConstructorName = @"TestConstructor";
    NSString *testFieldName1      = @"TestField1";
    NSString *testFieldValue1     = @"TestFieldValue1";
    NSString *testFieldName2      = @"TestField2";
    NSNumber *testFieldValue2     = @123;
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeConstructorStartWithObjectName:testConstructorName];
    [writer writeFieldStartWithFieldName:testFieldName1];
    [writer writeString:testFieldValue1];
    [writer writeEnd];
    [writer writeFieldStartWithFieldName:testFieldName2];
    [writer writeInt32:testFieldValue2];
    [writer writeEnd];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    NSString *actualConstructorName = [reader readConstructorStart];
    NSString *actualFieldName1 = [reader readFieldStart];
    NSString *actualFieldValue1 = [reader readString];
    [reader readEnd];
    NSString *actualFieldName2 = [reader readFieldStart];
    NSNumber *actualFieldValue2 = [reader readInt32];
    [reader readEnd];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([actualConstructorName isEqualToString:testConstructorName]);
    XCTAssertTrue([actualFieldName1 isEqualToString:testFieldName1]);
    XCTAssertTrue([actualFieldValue1 isEqualToString:testFieldValue1]);
    XCTAssertTrue([actualFieldName2 isEqualToString:testFieldName2]);
    XCTAssertTrue([actualFieldValue2 isEqualToNumber:testFieldValue2]);
    
}

- (void)testErrorInfoItems {
    
    QredoDebugInfo *testDebugInfo1 = [QredoDebugInfo debugInfoWithKey:@"Key1" value:@"Value1"];
    QredoDebugInfo *testDebugInfo2 = [QredoDebugInfo debugInfoWithKey:@"Key2" value:@"Value2"];
    QredoDebugInfo *testDebugInfo3 = [QredoDebugInfo debugInfoWithKey:@"Key3" value:@"Value3"];
    NSMutableArray *testDebugInfoItems = [NSMutableArray new];
    [testDebugInfoItems addObject:testDebugInfo1];
    [testDebugInfoItems addObject:testDebugInfo2];
    [testDebugInfoItems addObject:testDebugInfo3];
    
    QredoErrorInfo *errorInfo1 = [QredoErrorInfo errorInfoWithCode:123
                                                      debugMessage:@"ErrorInfo1"
                                                         debugInfo:[testDebugInfoItems copy]];
    QredoErrorInfo *errorInfo2 = [QredoErrorInfo errorInfoWithCode:456
                                                      debugMessage:@"ErrorInfo2"
                                                         debugInfo:[testDebugInfoItems copy]];
    QredoErrorInfo *errorInfo3 = [QredoErrorInfo errorInfoWithCode:789
                                                      debugMessage:@"ErrorInfo3"
                                                         debugInfo:[testDebugInfoItems copy]];
    NSMutableArray *testErrorInfoItems = [NSMutableArray new];
    [testErrorInfoItems addObject:errorInfo1];
    [testErrorInfoItems addObject:errorInfo2];
    [testErrorInfoItems addObject:errorInfo3];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeErrorInfoItems:[testErrorInfoItems copy]];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    NSArray *actualErrorInfoItems = [reader readErrorInfoItems];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([actualErrorInfoItems count] == 3);
    QredoErrorInfo *actualErrorInfo1 = [actualErrorInfoItems objectAtIndex:0];
    QredoErrorInfo *actualErrorInfo2 = [actualErrorInfoItems objectAtIndex:1];
    QredoErrorInfo *actualErrorInfo3 = [actualErrorInfoItems objectAtIndex:2];
    
    QredoDebugInfo *actualDebugInfo1;
    QredoDebugInfo *actualDebugInfo2;
    QredoDebugInfo *actualDebugInfo3;
    
    XCTAssertTrue([actualErrorInfo1 code] == 123);
    XCTAssertTrue([[actualErrorInfo1 debugMessage] isEqualToString:@"ErrorInfo1"]);
    XCTAssertTrue([[actualErrorInfo1 debugInfo] count] == 3);
    actualDebugInfo1 = [[actualErrorInfo1 debugInfo] objectAtIndex:0];
    actualDebugInfo2 = [[actualErrorInfo1 debugInfo] objectAtIndex:1];
    actualDebugInfo3 = [[actualErrorInfo1 debugInfo] objectAtIndex:2];
    XCTAssertTrue([[actualDebugInfo1 key] isEqualToString:@"Key1"]);
    XCTAssertTrue([[actualDebugInfo1 value] isEqualToString:@"Value1"]);
    XCTAssertTrue([[actualDebugInfo2 key] isEqualToString:@"Key2"]);
    XCTAssertTrue([[actualDebugInfo2 value] isEqualToString:@"Value2"]);
    XCTAssertTrue([[actualDebugInfo3 key] isEqualToString:@"Key3"]);
    XCTAssertTrue([[actualDebugInfo3 value] isEqualToString:@"Value3"]);
    
    XCTAssertTrue([actualErrorInfo2 code] == 456);
    XCTAssertTrue([[actualErrorInfo2 debugMessage] isEqualToString:@"ErrorInfo2"]);
    XCTAssertTrue([[actualErrorInfo2 debugInfo] count] == 3);
    actualDebugInfo1 = [[actualErrorInfo2 debugInfo] objectAtIndex:0];
    actualDebugInfo2 = [[actualErrorInfo2 debugInfo] objectAtIndex:1];
    actualDebugInfo3 = [[actualErrorInfo2 debugInfo] objectAtIndex:2];
    XCTAssertTrue([[actualDebugInfo1 key] isEqualToString:@"Key1"]);
    XCTAssertTrue([[actualDebugInfo1 value] isEqualToString:@"Value1"]);
    XCTAssertTrue([[actualDebugInfo2 key] isEqualToString:@"Key2"]);
    XCTAssertTrue([[actualDebugInfo2 value] isEqualToString:@"Value2"]);
    XCTAssertTrue([[actualDebugInfo3 key] isEqualToString:@"Key3"]);
    XCTAssertTrue([[actualDebugInfo3 value] isEqualToString:@"Value3"]);
    
    XCTAssertTrue([actualErrorInfo3 code] == 789);
    XCTAssertTrue([[actualErrorInfo3 debugMessage] isEqualToString:@"ErrorInfo3"]);
    XCTAssertTrue([[actualErrorInfo3 debugInfo] count] == 3);
    actualDebugInfo1 = [[actualErrorInfo3 debugInfo] objectAtIndex:0];
    actualDebugInfo2 = [[actualErrorInfo3 debugInfo] objectAtIndex:1];
    actualDebugInfo3 = [[actualErrorInfo3 debugInfo] objectAtIndex:2];
    XCTAssertTrue([[actualDebugInfo1 key] isEqualToString:@"Key1"]);
    XCTAssertTrue([[actualDebugInfo1 value] isEqualToString:@"Value1"]);
    XCTAssertTrue([[actualDebugInfo2 key] isEqualToString:@"Key2"]);
    XCTAssertTrue([[actualDebugInfo2 value] isEqualToString:@"Value2"]);
    XCTAssertTrue([[actualDebugInfo3 key] isEqualToString:@"Key3"]);
    XCTAssertTrue([[actualDebugInfo3 value] isEqualToString:@"Value3"]);
    
}

- (void)testResults {
    
    QredoResultHeader *testResult1 = [QredoResultHeader resultHeaderWithStatus:[NSNumber numberWithChar:QredoMarkerOperationSuccess]];
    QredoResultHeader *testResult2 = [QredoResultHeader resultHeaderWithStatus:[NSNumber numberWithChar:QredoMarkerOperationFailure]];
    
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];
    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
    [writer writeStart];
    [writer writeResultStart:testResult1];
    [writer writeInt32:@123];
    [writer writeEnd];
    [writer writeResultStart:testResult2];
    [writer writeInt32:@456];
    [writer writeEnd];
    [writer writeEnd];
    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [out close];
    
    NSInputStream *in = [NSInputStream inputStreamWithData:data];
    [in open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
    [reader readStart];
    QredoResultHeader *actualResult1 = [reader readResultStart];
    NSNumber *actualNumber1 = [reader readInt32];
    [reader readEnd];
    QredoResultHeader *actualResult2 = [reader readResultStart];
    NSNumber *actualNumber2 = [reader readInt32];
    [reader readEnd];
    XCTAssertTrue([reader atEnd]);
    [reader readEnd];
    XCTAssertFalse([in hasBytesAvailable]);
    [in close];
    
    XCTAssertTrue([actualResult1 isSuccess]);
    XCTAssertTrue([actualNumber1 isEqualToNumber:@123]);
    XCTAssertTrue([actualResult2 isFailure]);
    XCTAssertTrue([actualNumber2 isEqualToNumber:@456]);
    
}

//- (NSData *)withConnectedStreamsFromWriter:(void (^)(QredoWireFormatWriter *writer))writeBlock
//                                    reader:(void (^)(QredoWireFormatReader *reader))readBlock {
//    
//    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
//    [out open];
//    QredoWireFormatWriter *writer = [QredoWireFormatWriter wireFormatWriterWithOutputStream:out];
//    writeBlock(writer);
//    NSData *data = [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
//    [out close];
//    
//    NSInputStream *in = [NSInputStream inputStreamWithData:data];
//    [in open];
//    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:in];
//    readBlock(reader);
//    XCTAssertFalse([in hasBytesAvailable]);
//    [in close];
//    
//}

@end
