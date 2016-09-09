/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"


@interface QredoUtilsTests :QredoXCTestCase

@end

@implementation QredoUtilsTests

-(void)setUp {
    [super setUp];
    //Put setup code here. This method is called before the invocation of each test method in the class.
}


-(void)tearDown {
    //Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)testDHChannel {
    NSString *message = @"the quick brown fox jumps over the lazy dog";
    QredoSecureChannel *qscForward = [[QredoSecureChannel alloc] init];
    QredoSecureChannel *qscBackWards = [[QredoSecureChannel alloc] init];
    
    [qscForward setRemotePublicKey:[qscBackWards publicKey]];
    [qscBackWards setRemotePublicKey:[qscForward publicKey]];
    
    NSString *cipherText = [qscForward encryptString:message];
    NSString *decrypted = [qscBackWards decryptString:cipherText];
    
    XCTAssertTrue([message isEqualToString:decrypted],@"decrypt/encrypt  fails");
}


-(void)testData2Eng {
    NSData *dataShort  = [QredoUtils hexStringToData:@"ccaaddee"];
    NSString *english = [QredoUtils key2Eng:dataShort];
    NSString *expected = @"RASH BEST EMIT";
    
    XCTAssertTrue([expected isEqualToString:english],@"Incorrect string produced");
}


-(void)testEng2Data {
    NSString *start = @"rASh     bEst EMiT";
    NSData *newData = [QredoUtils eng2Key:start];
    NSString *hex = [QredoUtils dataToHexString:newData];
    
    XCTAssertTrue([hex isEqualToString:@"CCAADDEE"],@"Hex dont match");
}


-(void)testKey1 {
    NSData *myPrivateKeyData = [QredoUtils hexStringToData:@"ccac2aed 591056be 4f90fd44 1c534766"];
    NSString *english = [QredoUtils rfc1751Key2Eng:myPrivateKeyData];
    NSData *hexdata = [QredoUtils rfc1751Eng2Key:english];
    
    XCTAssert([@"RASH BUSH MILK LOOK BAD BRIM AVID GAFF BAIT ROT POD LOVE" isEqualToString:english],@"Key doesn't encode correctly");
    XCTAssert([myPrivateKeyData isEqualToData:hexdata],@"Key doesn't decode correctly");
}


-(void)testKey2 {
    NSData *myPrivateKeyData = [QredoUtils hexStringToData:@"EFF8 1F9B FBC6 5350 920C DD74 16DE 8009"];
    NSString *english = [QredoUtils rfc1751Key2Eng:myPrivateKeyData];
    NSData *hexdata = [[QredoUtils rfc1751Eng2Key:english] copy];
    
    XCTAssert([@"TROD MUTE TAIL WARM CHAR KONG HAAG CITY BORE O TEAL AWL" isEqualToString:english],@"Key doesn't encode correctly");
    XCTAssert([myPrivateKeyData isEqualToData:hexdata],@"Key doesn't decode correctly");
}


-(void)testRFCtoEng {
    NSData *myPrivateKeyData = [QredoUtils hexStringToData:@"e87376b2 4a36c447 8d012a8e 337ebba5 df064f34 5ebbce08 2a2d88a9 5f5bb08b"];
    NSString *english = [QredoUtils rfc1751Key2Eng:myPrivateKeyData];
    NSData *hexdata = [[QredoUtils rfc1751Eng2Key:english] copy];
    
    XCTAssert([@"TECH HOYT LEER HAST CRAY LEA GLOW BUN JUDY CITY TILE ROUT SLIM PAW RAYS MODE MITT AUK MUM CRAY MY MOOR MILD WON" isEqualToString:english],@"Key doesn't encode correctly");
    XCTAssert([myPrivateKeyData isEqualToData:hexdata],@"Key doesn't decode correctly");
}


-(void)testHexToDatatoHex1 {
    NSString *start = @"aabbcc  CCDeedd eef fccdd aa 1123 245 237 23634 4   537";
    NSString *stripped = [[start stringByReplacingOccurrencesOfString:@" " withString:@""] uppercaseString];
    NSData *data = [QredoUtils hexStringToData:start];
    NSString *end = [QredoUtils dataToHexString:data];
    
    XCTAssertTrue([stripped isEqualToString:end],@"strings dont match");
}


-(void)testHexToDatatoHex2 {
    NSString *start = @"aabbcc  CCDeedd eef fccdd aa 1123 245 237 23634 4   5379";
    NSString *stripped = [[start stringByReplacingOccurrencesOfString:@" " withString:@""] uppercaseString];
    NSData *data = [QredoUtils hexStringToData:start];
    NSString *end = [QredoUtils dataToHexString:data];
    
    XCTAssertNil(data);
    XCTAssertNil(end);
}


@end
