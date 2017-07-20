/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoCertificateUtils.h"
#import "QredoCertificateUtils_Private.h"
#import "TestCertificates.h"
#import "NSData+QredoRandomData.h"
#import "QredoCrypto.h"
#import "QredoLoggerPrivate.h"
#import "QredoCryptoTestUtilities.h"

@interface QredoCertificateUtilsTests :XCTestCase

@end

@implementation QredoCertificateUtilsTests

-(void)setUp {
    [super setUp];
    //These test produce many intentional errors - so turn off Debug Logging so we dont get lots of error warning '❤️  ERROR'
    [QredoLogger setLogLevel:QredoLogLevelNone];
    //Must remove any existing keys before starting
    [QredoCryptoTestUtilities deleteAllKeysInAppleKeychain];
    
}


-(void)tearDown {
    //Must remove any keys after completing
    [QredoCryptoTestUtilities deleteAllKeysInAppleKeychain];
    
    [super tearDown];
}


-(void)testCreateCertificateWithDerData {
    NSData *derFormattedCertData = [NSData dataWithBytes:TestCertDHTestingLocalhostClientDerArray
                                                  length:sizeof(TestCertDHTestingLocalhostClientDerArray) / sizeof(uint8_t)];
    
    SecCertificateRef certificateRef = [QredoCertificateUtils createCertificateWithDerData:derFormattedCertData];
    
    XCTAssertNotNil((__bridge id)certificateRef,@"Nil certificate ref returned");
}


-(void)testCreateCertificateWithDerData_Nil {
    NSData *certData = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils createCertificateWithDerData:certData],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testCreateCertificateWithDerData_EmptyData_Invalid {
    NSData *derFormattedCertData = [[NSData alloc] init];
    
    SecCertificateRef certificateRef = [QredoCertificateUtils createCertificateWithDerData:derFormattedCertData];
    
    XCTAssertNil((__bridge id)certificateRef,@"Non-nil certificate ref returned for empty data");
}


-(void)testCreateCertificateWithDerData_RandomData_Invalid {
    NSData *derFormattedCertData = [NSData dataWithRandomBytesOfLength:1000];
    
    SecCertificateRef certificateRef = [QredoCertificateUtils createCertificateWithDerData:derFormattedCertData];
    
    XCTAssertNil((__bridge id)certificateRef,@"Non-nil certificate ref returned for empty data");
}


-(void)testConvertCertificateRefsToPemCertificate_SingleCertificateRef {
    NSString *pemCertificates = TestCertJavaSdkClient4096Pem;
    int expectedCertificateRefCount = 1;
    
    NSArray *certificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:pemCertificates];
    
    XCTAssertNotNil(certificateRefs);
    XCTAssertEqual(certificateRefs.count,expectedCertificateRefCount);
    
    NSString *generatedPemCertificates = [QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateRefs];
    XCTAssertNotNil(generatedPemCertificates);
    
    //Note: Generated string may not be the same if the line breaks/wrapping is different, in this case, wrapping should match
    XCTAssertTrue([generatedPemCertificates isEqualToString:pemCertificates]);
}


-(void)testConvertCertificateRefsToPemCertificate_Invalid_NilArray {
    NSArray *certificateRefs = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateRefs],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testConvertCertificateRefsToPemCertificate_Invalid_EmptyArray {
    int expectedCertificateRefCount = 0;
    NSArray *certificateRefs = [[NSArray alloc] init];
    
    XCTAssertNotNil(certificateRefs);
    XCTAssertEqual(certificateRefs.count,expectedCertificateRefCount);
    
    NSString *generatedPemCertificates = [QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateRefs];
    XCTAssertNotNil(generatedPemCertificates);
}


-(void)testConvertCertificateRefsToPemCertificate_MultipleCertificateRefs {
    //Java SDK Root Certificate
    //Java SDK Intermediate Certificate
    //Java SDK Client Certificate
    NSString *pemCertificates = [NSString stringWithFormat:@"%@%@%@",
                                 TestCertJavaSdkRootPem,
                                 TestCertJavaSdkIntermediatePem,
                                 TestCertJavaSdkClient4096Pem];
    int expectedCertificateRefCount = 3;
    
    NSArray *certificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:pemCertificates];
    
    XCTAssertNotNil(certificateRefs);
    XCTAssertEqual(certificateRefs.count,expectedCertificateRefCount);
    
    NSString *generatedPemCertificates = [QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateRefs];
    XCTAssertNotNil(generatedPemCertificates);
    
    //Note: Generated string may not be the same if the line breaks/wrapping is different, in this case, wrapping should match
    XCTAssertTrue([generatedPemCertificates isEqualToString:pemCertificates]);
}


-(void)testConvertCertificateRefsToPemCertificate_MultipleCertificateRefs_UnmatchedExtraNewline {
    //Java SDK Root Certificate
    //Java SDK Intermediate Certificate
    //Java SDK Client Certificate
    //Note: Putting extra newline between certs which won't be present in re-created output
    NSString *pemCertificates = [NSString stringWithFormat:@"%@\n%@",
                                 TestCertJavaSdkIntermediatePem,
                                 TestCertJavaSdkClient4096Pem];
    NSString *pemExpectedCertificates = [NSString stringWithFormat:@"%@%@",
                                         TestCertJavaSdkIntermediatePem,
                                         TestCertJavaSdkClient4096Pem];
    int expectedCertificateRefCount = 2;
    
    NSArray *certificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:pemCertificates];
    
    XCTAssertNotNil(certificateRefs);
    XCTAssertEqual(certificateRefs.count,expectedCertificateRefCount);
    
    NSString *generatedPemCertificates = [QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateRefs];
    XCTAssertNotNil(generatedPemCertificates);
    
    //Note: Generated string may not be the same if the line breaks/wrapping is different, in this case, wrapping should match
    XCTAssertTrue([generatedPemCertificates isEqualToString:pemExpectedCertificates]);
    XCTAssertFalse([generatedPemCertificates isEqualToString:pemCertificates]);
}


-(NSString *)stripPem:(NSString *)pem {
    NSRange r1 = [pem rangeOfString:@"-----BEGIN CERTIFICATE-----"];
    NSRange r2 = [pem rangeOfString:@"-----END CERTIFICATE-----"];
    NSRange rSub = NSMakeRange(r1.location + r1.length,r2.location - r1.location - r1.length);
    NSString *sub = [pem substringWithRange:rSub];
    
    
    NSString *strippedPem = [NSString stringWithFormat:@"-----BEGIN CERTIFICATE-----%@-----END CERTIFICATE-----\n",sub];
    
    return strippedPem;
}


-(void)testConvertCertificateRefToPemCertificate {
    //Import some PKCS#12 data and then get the public certificate ref from the identity.
    //Use SecCertificateRef to create a PEM which is then processed (to confirm validity)
    
    NSError *error = nil;
    
    //1.) Create identity
    
    //Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert2.2048.IntCA1" error:&error];
    NSString *pkcs12Password = @"password";
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data
                                                                                             password:pkcs12Password
                                                                                  rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary,@"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,
                                                                      kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef,@"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
    
    //2.) Create Certificate Ref from Identity
    SecCertificateRef certificateRef = [QredoCryptoTestUtilities getCertificateRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)certificateRef);
    
    //3.) Actual test - convert the Certificate Ref to a PEM string
    NSString *pemCertificate = [QredoCertificateUtils convertCertificateRefToPemCertificate:certificateRef];
    XCTAssertNotNil(pemCertificate);
    
    //Compare the new certificate with the original certificate (used to create the PKCS12 data)
    XCTAssertTrue([pemCertificate isEqualToString:[self stripPem:[TestCertificates fetchPemForResource:@"clientCert2.2048.IntCA1cert" error:&error]]]);
}


-(void)testConvertKeyIdentifierToPemKey_GeneratedKey {
    //Generate some keys and get the public key in PEM format
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSUInteger keySizeBits = 2048;
    
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto rsaGenerate:keySizeBits
                                          publicKeyIdentifier:publicKeyIdentifier
                                         privateKeyIdentifier:privateKeyIdentifier
                                       persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef);
    
    NSString *pemEncodedPublicKey = [QredoCertificateUtils convertKeyIdentifierToPemKey:publicKeyIdentifier];
    XCTAssertNotNil(pemEncodedPublicKey);
    XCTAssertTrue(pemEncodedPublicKey.length > 0);
    XCTAssertTrue([pemEncodedPublicKey hasPrefix:@"-----BEGIN PUBLIC KEY-----\n"]);
    XCTAssertTrue([pemEncodedPublicKey hasSuffix:@"\n-----END PUBLIC KEY-----\n"]);
}


-(void)testConvertKeyIdentifierToPemKey_ImportedKey {
    //Import a known public key in DER format (already in PKCS#1, as we will output)
    //then check that converting it to PEM gives correct data
    NSString *expectedPemEncodedPublicKey = TestKeyJavaSdkClient4096PemPkcs1;
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSUInteger keySizeBits = 4096;
    
    NSData *pkcs1Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096Pkcs1DerArray
                                       length:sizeof(TestPubKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(pkcs1Data);
    
    SecKeyRef keyRef = [QredoCryptoTestUtilities importPkcs1KeyData:pkcs1Data
                                         keyLengthBits:keySizeBits
                                         keyIdentifier:publicKeyIdentifier
                                             isPrivate:NO];
    XCTAssertNotNil((__bridge id)keyRef);
    
    NSString *pemEncodedPublicKey = [QredoCertificateUtils convertKeyIdentifierToPemKey:publicKeyIdentifier];
    XCTAssertNotNil(pemEncodedPublicKey);
    XCTAssertTrue([pemEncodedPublicKey isEqualToString:expectedPemEncodedPublicKey]);
}


-(void)testConvertKeyIdentifierToPemKey_Invalid_NilIdentifier {
    NSString *publicKeyIdentifier = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertKeyIdentifierToPemKey:publicKeyIdentifier],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testConvertKeyIdentifierToPemKey_Invalid_EmptyIdentifier {
    NSString *publicKeyIdentifier = @"";
    
    NSString *pemEncodedPublicKey;
    
    @try {
        pemEncodedPublicKey = [QredoCertificateUtils convertKeyIdentifierToPemKey:publicKeyIdentifier];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Key shouldn't be found.");
    } @finally {
        XCTAssertNil(pemEncodedPublicKey);
    }
}


-(void)testConvertKeyIdentifierToPemKey_Invalid_UnknownIdentifier {
    NSString *publicKeyIdentifier = @"This is an unknown identifier";
    NSString *pemEncodedPublicKey;
    
    @try {
        pemEncodedPublicKey = [QredoCertificateUtils convertKeyIdentifierToPemKey:publicKeyIdentifier];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Key shouldn't be found.");
    } @finally {
        XCTAssertNil(pemEncodedPublicKey);
    }
}


-(void)testConvertPemWrappedStringToDer {
    NSString *pemWrappedString = TestKeyJavaSdkClient4096PemX509;
    NSString *startMarker = @"-----BEGIN PUBLIC KEY-----\n";
    NSString *endMarker = @"\n-----END PUBLIC KEY-----\n";
    
    NSData *expectedDerData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                             length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    
    NSData *convertedDerData = [QredoCertificateUtils convertPemWrappedStringToDer:pemWrappedString
                                                                       startMarker:startMarker
                                                                         endMarker:endMarker];
    
    XCTAssertNotNil(convertedDerData);
    XCTAssertTrue([convertedDerData isEqualToData:expectedDerData]);
}


-(void)testConvertPemWrappedStringToDer_StartMarkerWrong {
    //The StartMarker will not be found
    NSString *pemWrappedString = TestKeyJavaSdkClient4096PemX509;
    NSString *startMarker = @"-----BEGIN CERTIFICATE-----\n";
    NSString *endMarker = @"\n-----END PUBLIC KEY-----\n";
    
    NSData *convertedDerData = [QredoCertificateUtils convertPemWrappedStringToDer:pemWrappedString
                                                                       startMarker:startMarker
                                                                         endMarker:endMarker];
    
    XCTAssertNil(convertedDerData);
}


-(void)testConvertPemWrappedStringToDer_EndMarkerWrong {
    //The EndMarker will not be found
    NSString *pemWrappedString = TestKeyJavaSdkClient4096PemX509;
    NSString *startMarker = @"-----BEGIN PUBLIC KEY-----\n";
    NSString *endMarker = @"\n-----END CERTIFICATE-----\n";
    
    NSData *convertedDerData = [QredoCertificateUtils convertPemWrappedStringToDer:pemWrappedString
                                                                       startMarker:startMarker
                                                                         endMarker:endMarker];
    
    XCTAssertNil(convertedDerData);
}


-(void)testConvertPemWrappedStringToDer_StartEndMarkersSwapped {
    //The StartMarker and EndMarker are present, but in incorrect order
    NSString *pemWrappedString = TestKeyJavaSdkClient4096PemX509;
    NSString *startMarker = @"\n-----END PUBLIC KEY-----\n";
    NSString *endMarker = @"-----BEGIN PUBLIC KEY-----\n";
    
    NSData *convertedDerData = [QredoCertificateUtils convertPemWrappedStringToDer:pemWrappedString
                                                                       startMarker:startMarker
                                                                         endMarker:endMarker];
    
    XCTAssertNil(convertedDerData);
}


-(void)testConvertPemWrappedStringToDer_StartMarkerNil {
    //The StartMarker is nil
    NSString *pemWrappedString = TestKeyJavaSdkClient4096PemX509;
    NSString *startMarker = nil;
    NSString *endMarker = @"\n-----END PUBLIC KEY-----\n";
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertPemWrappedStringToDer:pemWrappedString
                                                                         startMarker:startMarker
                                                                           endMarker:endMarker],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testConvertPemWrappedStringToDer_EndMarkerNil {
    //The EndMarker is nil
    NSString *pemWrappedString = TestKeyJavaSdkClient4096PemX509;
    NSString *startMarker = @"-----BEGIN PUBLIC KEY-----\n";
    NSString *endMarker = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertPemWrappedStringToDer:pemWrappedString
                                                                         startMarker:startMarker
                                                                           endMarker:endMarker],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testConvertPemWrappedStringToDer_SearchStringNil {
    //The StartMarker is nil
    NSString *pemWrappedString = nil;
    NSString *startMarker = @"-----BEGIN PUBLIC KEY-----\n";
    NSString *endMarker = @"\n-----END PUBLIC KEY-----\n";
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertPemWrappedStringToDer:pemWrappedString
                                                                         startMarker:startMarker
                                                                           endMarker:endMarker],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testGetPkcs1PublicKeyDataFromUnknownPublicKeyData_Pkcs1Input {
    //X.509 format DER data in, PKCS#1 format data out
    NSData *publicKeyData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                           length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(publicKeyData);
    
    NSData *expectedPkcs1Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096Pkcs1DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(expectedPkcs1Data);
    
    NSData *convertedPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyData];
    XCTAssertNotNil(convertedPkcs1Data);
    XCTAssertTrue([convertedPkcs1Data isEqualToData:expectedPkcs1Data]);
}


-(void)testGetPkcs1PublicKeyDataFromUnknownPublicKeyData_X509Input {
    //PKCS#1 format DER data in, same PKCS#1 format data out
    NSData *publicKeyData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096Pkcs1DerArray
                                           length:sizeof(TestPubKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(publicKeyData);
    
    NSData *expectedPkcs1Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096Pkcs1DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(expectedPkcs1Data);
    
    NSData *convertedPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyData];
    XCTAssertNotNil(convertedPkcs1Data);
    XCTAssertTrue([convertedPkcs1Data isEqualToData:expectedPkcs1Data]);
}


-(void)testGetPkcs1PublicKeyDataFromUnknownPublicKeyData_InvalidNilInput {
    NSData *publicKeyData = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyData],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testGetPkcs1PublicKeyDataFromUnknownPublicKeyData_InvalidInput {
    //Random data in, nil data out
    NSData *publicKeyData = [NSData dataWithRandomBytesOfLength:2048];
    
    XCTAssertNotNil(publicKeyData);
    
    NSData *convertedPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyData];
    XCTAssertNil(convertedPkcs1Data);
}


-(void)testCheckIfPublicKeyDataIsPkcs1_Pkcs1Data {
    //PKCS#1 format data in
    NSData *publicKeyData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096Pkcs1DerArray
                                           length:sizeof(TestPubKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(publicKeyData);
    
    BOOL expectedCheckResult = YES;
    
    BOOL publicKeyDataIsPkcs1 = [QredoCertificateUtils checkIfPublicKeyDataIsPkcs1:publicKeyData];
    XCTAssertEqual(publicKeyDataIsPkcs1,expectedCheckResult);
}


-(void)testCheckIfPublicKeyDataIsPkcs1_X509Data {
    //X.509 format data in
    NSData *publicKeyData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                           length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(publicKeyData);
    
    BOOL expectedCheckResult = NO;
    
    BOOL publicKeyDataIsPkcs1 = [QredoCertificateUtils checkIfPublicKeyDataIsPkcs1:publicKeyData];
    XCTAssertEqual(publicKeyDataIsPkcs1,expectedCheckResult);
}


-(void)testCheckIfPublicKeyDataIsPkcs1_RandomData {
    //Random data in
    NSData *publicKeyData = [NSData dataWithRandomBytesOfLength:2048];
    
    XCTAssertNotNil(publicKeyData);
    
    BOOL expectedCheckResult = NO;
    
    BOOL publicKeyDataIsPkcs1 = [QredoCertificateUtils checkIfPublicKeyDataIsPkcs1:publicKeyData];
    XCTAssertEqual(publicKeyDataIsPkcs1,expectedCheckResult);
}


-(void)testCheckIfPublicKeyDataIsPkcs1_NilData {
    //Nil data in
    NSData *publicKeyData = nil;
    
    BOOL expectedCheckResult = NO;
    
    BOOL publicKeyDataIsPkcs1 = [QredoCertificateUtils checkIfPublicKeyDataIsPkcs1:publicKeyData];
    
    XCTAssertEqual(publicKeyDataIsPkcs1,expectedCheckResult);
}


-(void)testConvertX509PublicKeyToPkcs1PublicKey_X509Input {
    //X.509 format DER data in, PKCS#1 format data out
    NSData *publicKeyData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                           length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(publicKeyData);
    
    NSData *expectedPkcs1Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096Pkcs1DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(expectedPkcs1Data);
    
    NSData *convertedPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyData];
    XCTAssertNotNil(convertedPkcs1Data);
    XCTAssertTrue([convertedPkcs1Data isEqualToData:expectedPkcs1Data]);
}


-(void)testConvertX509PublicKeyToPkcs1PublicKey_Pkcs1Input {
    //PKCS#1 format data in, nil data out
    NSData *publicKeyData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096Pkcs1DerArray
                                           length:sizeof(TestPubKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    
    XCTAssertNotNil(publicKeyData);
    
    NSData *convertedPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyData];
    XCTAssertNil(convertedPkcs1Data);
}


-(void)testConvertX509PublicKeyToPkcs1PublicKey_InvalidNilInput {
    NSData *publicKeyData = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyData],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testConvertX509PublicKeyToPkcs1PublicKey_InvalidInput {
    //Random data in, nil data out
    NSData *publicKeyData = [NSData dataWithRandomBytesOfLength:2048];
    
    XCTAssertNotNil(publicKeyData);
    
    NSData *convertedPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyData];
    XCTAssertNil(convertedPkcs1Data);
}


-(void)testConvertPemPublicKeyToDer {
    NSString *pemPublicKey = TestKeyJavaSdkClient4096PemX509;
    
    NSData *expectedDerData = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                             length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    
    NSData *convertedDerData = [QredoCertificateUtils convertPemPublicKeyToDer:pemPublicKey];
    
    XCTAssertNotNil(convertedDerData);
    XCTAssertTrue([convertedDerData isEqualToData:expectedDerData]);
}


-(void)testConvertPemPublicKeyToDer_Invalid_NotPemKeyString {
    //Pass in PEM certificate, not PEM public key
    NSString *pemPublicKey = TestCertJavaSdkClient4096Pem;
    
    NSData *convertedDerData = [QredoCertificateUtils convertPemPublicKeyToDer:pemPublicKey];
    
    XCTAssertNil(convertedDerData);
}


-(void)testConvertPemPublicKeyToDer_Invalid_NilPemString {
    NSString *pemPublicKey = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertPemPublicKeyToDer:pemPublicKey],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testConvertPemPublicKeyToDer_Invalid_EmptyPemString {
    NSString *pemPublicKey = @"";
    
    NSData *convertedDerData = [QredoCertificateUtils convertPemPublicKeyToDer:pemPublicKey];
    
    XCTAssertNil(convertedDerData);
}


-(void)testConvertPemCertificateToDer {
    //DH localhost root CA
    NSString *certificateChainPemString = TestCertDHTestingLocalhostRootPem;
    
    uint8_t expectedDerFormattedDataArray[827] = {
        0x30,0x82,0x03,0x37,0x30,0x82,0x02,0xA0,0xA0,0x03,0x02,0x01,0x02,0x02,0x09,0x00,
        0xB4,0x07,0x54,0x0D,0x21,0xE0,0xD5,0xA1,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,
        0xF7,0x0D,0x01,0x01,0x05,0x05,0x00,0x30,0x71,0x31,0x0B,0x30,0x09,0x06,0x03,0x55,
        0x04,0x06,0x13,0x02,0x47,0x42,0x31,0x0F,0x30,0x0D,0x06,0x03,0x55,0x04,0x08,0x13,
        0x06,0x53,0x75,0x72,0x72,0x65,0x79,0x31,0x12,0x30,0x10,0x06,0x03,0x55,0x04,0x07,
        0x13,0x09,0x47,0x75,0x69,0x6C,0x64,0x66,0x6F,0x72,0x64,0x31,0x13,0x30,0x11,0x06,
        0x03,0x55,0x04,0x0A,0x13,0x0A,0x44,0x48,0x20,0x54,0x65,0x73,0x74,0x69,0x6E,0x67,
        0x31,0x14,0x30,0x12,0x06,0x03,0x55,0x04,0x0B,0x13,0x0B,0x44,0x65,0x76,0x65,0x6C,
        0x6F,0x70,0x6D,0x65,0x6E,0x74,0x31,0x12,0x30,0x10,0x06,0x03,0x55,0x04,0x03,0x13,
        0x09,0x6C,0x6F,0x63,0x61,0x6C,0x68,0x6F,0x73,0x74,0x30,0x1E,0x17,0x0D,0x31,0x34,
        0x31,0x30,0x32,0x33,0x31,0x30,0x31,0x30,0x33,0x31,0x5A,0x17,0x0D,0x32,0x34,0x31,
        0x30,0x32,0x30,0x31,0x30,0x31,0x30,0x33,0x31,0x5A,0x30,0x71,0x31,0x0B,0x30,0x09,
        0x06,0x03,0x55,0x04,0x06,0x13,0x02,0x47,0x42,0x31,0x0F,0x30,0x0D,0x06,0x03,0x55,
        0x04,0x08,0x13,0x06,0x53,0x75,0x72,0x72,0x65,0x79,0x31,0x12,0x30,0x10,0x06,0x03,
        0x55,0x04,0x07,0x13,0x09,0x47,0x75,0x69,0x6C,0x64,0x66,0x6F,0x72,0x64,0x31,0x13,
        0x30,0x11,0x06,0x03,0x55,0x04,0x0A,0x13,0x0A,0x44,0x48,0x20,0x54,0x65,0x73,0x74,
        0x69,0x6E,0x67,0x31,0x14,0x30,0x12,0x06,0x03,0x55,0x04,0x0B,0x13,0x0B,0x44,0x65,
        0x76,0x65,0x6C,0x6F,0x70,0x6D,0x65,0x6E,0x74,0x31,0x12,0x30,0x10,0x06,0x03,0x55,
        0x04,0x03,0x13,0x09,0x6C,0x6F,0x63,0x61,0x6C,0x68,0x6F,0x73,0x74,0x30,0x81,0x9F,
        0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x01,0x05,0x00,0x03,
        0x81,0x8D,0x00,0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xC8,0x77,0xE9,0xB7,0x08,0x66,
        0x5D,0x28,0xCC,0xF2,0x24,0x76,0xEA,0x4C,0xE3,0x78,0x31,0xE8,0x2C,0x41,0xBD,0x83,
        0x53,0x30,0x7B,0xC4,0x90,0x84,0x57,0x05,0x20,0xE4,0x89,0x17,0xCD,0x99,0x82,0xD0,
        0x9B,0xDC,0x88,0xC5,0x04,0x51,0x64,0xF3,0x37,0x97,0xD7,0xF8,0xD7,0x2B,0x74,0xCD,
        0xA0,0xB2,0x2B,0x07,0xAE,0x71,0x58,0x82,0x86,0x33,0x3F,0x93,0x62,0x67,0x64,0x7B,
        0x33,0x76,0xA1,0x11,0x70,0x30,0xEC,0x9F,0xC5,0xDA,0x3D,0x1A,0x0D,0xD8,0x41,0x9C,
        0x0E,0x2F,0x2B,0x66,0x94,0x81,0xAB,0x18,0x89,0x53,0x6E,0xEC,0xD1,0x69,0x48,0x92,
        0xCE,0xDD,0xAC,0xD2,0xF3,0xDA,0x6D,0x34,0xB3,0x01,0xF1,0x15,0x09,0xF0,0xFE,0x43,
        0x02,0x3F,0x91,0xD7,0x1B,0x35,0xA4,0x51,0x2B,0xFF,0x02,0x03,0x01,0x00,0x01,0xA3,
        0x81,0xD6,0x30,0x81,0xD3,0x30,0x1D,0x06,0x03,0x55,0x1D,0x0E,0x04,0x16,0x04,0x14,
        0xC6,0x95,0x58,0x32,0x1D,0x6A,0x07,0xA8,0x5A,0xF6,0x9C,0x1B,0x6A,0x6E,0xA8,0x6C,
        0x9D,0x07,0xF7,0x2E,0x30,0x81,0xA3,0x06,0x03,0x55,0x1D,0x23,0x04,0x81,0x9B,0x30,
        0x81,0x98,0x80,0x14,0xC6,0x95,0x58,0x32,0x1D,0x6A,0x07,0xA8,0x5A,0xF6,0x9C,0x1B,
        0x6A,0x6E,0xA8,0x6C,0x9D,0x07,0xF7,0x2E,0xA1,0x75,0xA4,0x73,0x30,0x71,0x31,0x0B,
        0x30,0x09,0x06,0x03,0x55,0x04,0x06,0x13,0x02,0x47,0x42,0x31,0x0F,0x30,0x0D,0x06,
        0x03,0x55,0x04,0x08,0x13,0x06,0x53,0x75,0x72,0x72,0x65,0x79,0x31,0x12,0x30,0x10,
        0x06,0x03,0x55,0x04,0x07,0x13,0x09,0x47,0x75,0x69,0x6C,0x64,0x66,0x6F,0x72,0x64,
        0x31,0x13,0x30,0x11,0x06,0x03,0x55,0x04,0x0A,0x13,0x0A,0x44,0x48,0x20,0x54,0x65,
        0x73,0x74,0x69,0x6E,0x67,0x31,0x14,0x30,0x12,0x06,0x03,0x55,0x04,0x0B,0x13,0x0B,
        0x44,0x65,0x76,0x65,0x6C,0x6F,0x70,0x6D,0x65,0x6E,0x74,0x31,0x12,0x30,0x10,0x06,
        0x03,0x55,0x04,0x03,0x13,0x09,0x6C,0x6F,0x63,0x61,0x6C,0x68,0x6F,0x73,0x74,0x82,
        0x09,0x00,0xB4,0x07,0x54,0x0D,0x21,0xE0,0xD5,0xA1,0x30,0x0C,0x06,0x03,0x55,0x1D,
        0x13,0x04,0x05,0x30,0x03,0x01,0x01,0xFF,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,
        0xF7,0x0D,0x01,0x01,0x05,0x05,0x00,0x03,0x81,0x81,0x00,0xAD,0x53,0x4F,0x71,0x12,
        0x9A,0xDE,0x7F,0xB0,0xEE,0xB2,0x90,0x31,0x30,0x49,0xD6,0x71,0xFC,0x2C,0x19,0xAF,
        0xDD,0x72,0x33,0x3F,0x83,0x1B,0x9F,0x16,0xEE,0x96,0xDF,0x7F,0xCE,0x9D,0x71,0xEA,
        0xD4,0x9F,0xD8,0x7E,0x89,0x1E,0xBF,0x99,0x1A,0x66,0x06,0xD7,0x6D,0xC5,0x29,0x90,
        0x87,0x92,0xDF,0x61,0x66,0x8D,0x19,0xD3,0x8A,0x9B,0x46,0x30,0x79,0x17,0x4F,0x7D,
        0x97,0x35,0x12,0x41,0x6C,0x6A,0x04,0x59,0x3C,0x7D,0x9A,0x13,0x05,0xE0,0xEA,0xFB,
        0x21,0x6A,0xA8,0x9B,0xAD,0x9F,0xA3,0x45,0xBE,0xCC,0xD2,0x5D,0xA2,0x0C,0x80,0x0C,
        0xA8,0xBF,0x0C,0xAB,0x9D,0x1C,0xF5,0x88,0xB0,0x0A,0xD8,0x74,0x38,0xCB,0x79,0x3E,
        0xAA,0xCC,0x6A,0x4E,0xB1,0xAC,0x26,0xD1,0x6C,0x77,0x0B,
    };
    NSData *expectedDerFormattedData = [NSData dataWithBytes:expectedDerFormattedDataArray length:sizeof(expectedDerFormattedDataArray) / sizeof(uint8_t)];
    
    NSData *derFormattedData = [QredoCertificateUtils convertPemCertificateToDer:certificateChainPemString];
    
    XCTAssertNotNil(derFormattedData,@"Returned data should not be nil.");
    XCTAssertTrue([derFormattedData isEqualToData:expectedDerFormattedData],@"Converted data is incorrect.");
}


-(void)testConvertPemCertificateToDer_RsaCert {
    //RSA Security Inc CA cert from Firefox
    NSString *certificateChainPemString = RsaSecurityIncRootCertPem;
    
    unsigned char expectedDerFormattedDataArray[869] = {
        0x30,0x82,0x03,0x61,0x30,0x82,0x02,0x49,0xA0,0x03,0x02,0x01,0x02,0x02,0x10,0x0A,
        0x01,0x01,0x01,0x00,0x00,0x02,0x7C,0x00,0x00,0x00,0x0A,0x00,0x00,0x00,0x02,0x30,
        0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x05,0x05,0x00,0x30,0x3A,
        0x31,0x19,0x30,0x17,0x06,0x03,0x55,0x04,0x0A,0x13,0x10,0x52,0x53,0x41,0x20,0x53,
        0x65,0x63,0x75,0x72,0x69,0x74,0x79,0x20,0x49,0x6E,0x63,0x31,0x1D,0x30,0x1B,0x06,
        0x03,0x55,0x04,0x0B,0x13,0x14,0x52,0x53,0x41,0x20,0x53,0x65,0x63,0x75,0x72,0x69,
        0x74,0x79,0x20,0x32,0x30,0x34,0x38,0x20,0x56,0x33,0x30,0x1E,0x17,0x0D,0x30,0x31,
        0x30,0x32,0x32,0x32,0x32,0x30,0x33,0x39,0x32,0x33,0x5A,0x17,0x0D,0x32,0x36,0x30,
        0x32,0x32,0x32,0x32,0x30,0x33,0x39,0x32,0x33,0x5A,0x30,0x3A,0x31,0x19,0x30,0x17,
        0x06,0x03,0x55,0x04,0x0A,0x13,0x10,0x52,0x53,0x41,0x20,0x53,0x65,0x63,0x75,0x72,
        0x69,0x74,0x79,0x20,0x49,0x6E,0x63,0x31,0x1D,0x30,0x1B,0x06,0x03,0x55,0x04,0x0B,
        0x13,0x14,0x52,0x53,0x41,0x20,0x53,0x65,0x63,0x75,0x72,0x69,0x74,0x79,0x20,0x32,
        0x30,0x34,0x38,0x20,0x56,0x33,0x30,0x82,0x01,0x22,0x30,0x0D,0x06,0x09,0x2A,0x86,
        0x48,0x86,0xF7,0x0D,0x01,0x01,0x01,0x05,0x00,0x03,0x82,0x01,0x0F,0x00,0x30,0x82,
        0x01,0x0A,0x02,0x82,0x01,0x01,0x00,0xB7,0x8F,0x55,0x71,0xD2,0x80,0xDD,0x7B,0x69,
        0x79,0xA7,0xF0,0x18,0x50,0x32,0x3C,0x62,0x67,0xF6,0x0A,0x95,0x07,0xDD,0xE6,0x1B,
        0xF3,0x9E,0xD9,0xD2,0x41,0x54,0x6B,0xAD,0x9F,0x7C,0xBE,0x19,0xCD,0xFB,0x46,0xAB,
        0x41,0x68,0x1E,0x18,0xEA,0x55,0xC8,0x2F,0x91,0x78,0x89,0x28,0xFB,0x27,0x29,0x60,
        0xFF,0xDF,0x8F,0x8C,0x3B,0xC9,0x49,0x9B,0xB5,0xA4,0x94,0xCE,0x01,0xEA,0x3E,0xB5,
        0x63,0x7B,0x7F,0x26,0xFD,0x19,0xDD,0xC0,0x21,0xBD,0x84,0xD1,0x2D,0x4F,0x46,0xC3,
        0x4E,0xDC,0xD8,0x37,0x39,0x3B,0x28,0xAF,0xCB,0x9D,0x1A,0xEA,0x2B,0xAF,0x21,0xA5,
        0xC1,0x23,0x22,0xB8,0xB8,0x1B,0x5A,0x13,0x87,0x57,0x83,0xD1,0xF0,0x20,0xE7,0xE8,
        0x4F,0x23,0x42,0xB0,0x00,0xA5,0x7D,0x89,0xE9,0xE9,0x61,0x73,0x94,0x98,0x71,0x26,
        0xBC,0x2D,0x6A,0xE0,0xF7,0x4D,0xF0,0xF1,0xB6,0x2A,0x38,0x31,0x81,0x0D,0x29,0xE1,
        0x00,0xC1,0x51,0x0F,0x4C,0x52,0xF8,0x04,0x5A,0xAA,0x7D,0x72,0xD3,0xB8,0x87,0x2A,
        0xBB,0x63,0x10,0x03,0x2A,0xB3,0xA1,0x4F,0x0D,0x5A,0x5E,0x46,0xB7,0x3D,0x0E,0xF5,
        0x74,0xEC,0x99,0x9F,0xF9,0x3D,0x24,0x81,0x88,0xA6,0xDD,0x60,0x54,0xE8,0x95,0x36,
        0x3D,0xC6,0x09,0x93,0x9A,0xA3,0x12,0x80,0x00,0x55,0x99,0x19,0x47,0xBD,0xD0,0xA5,
        0x7C,0xC3,0xBA,0xFB,0x1F,0xF7,0xF5,0x0F,0xF8,0xAC,0xB9,0xB5,0xF4,0x37,0x98,0x13,
        0x18,0xDE,0x85,0x5B,0xB7,0x0C,0x82,0x3B,0x87,0x6F,0x95,0x39,0x58,0x30,0xDA,0x6E,
        0x01,0x68,0x17,0x22,0xCC,0xC0,0x0B,0x02,0x03,0x01,0x00,0x01,0xA3,0x63,0x30,0x61,
        0x30,0x0F,0x06,0x03,0x55,0x1D,0x13,0x01,0x01,0xFF,0x04,0x05,0x30,0x03,0x01,0x01,
        0xFF,0x30,0x0E,0x06,0x03,0x55,0x1D,0x0F,0x01,0x01,0xFF,0x04,0x04,0x03,0x02,0x01,
        0x06,0x30,0x1F,0x06,0x03,0x55,0x1D,0x23,0x04,0x18,0x30,0x16,0x80,0x14,0x07,0xC3,
        0x51,0x30,0xA4,0xAA,0xE9,0x45,0xAE,0x35,0x24,0xFA,0xFF,0x24,0x2C,0x33,0xD0,0xB1,
        0x9D,0x8C,0x30,0x1D,0x06,0x03,0x55,0x1D,0x0E,0x04,0x16,0x04,0x14,0x07,0xC3,0x51,
        0x30,0xA4,0xAA,0xE9,0x45,0xAE,0x35,0x24,0xFA,0xFF,0x24,0x2C,0x33,0xD0,0xB1,0x9D,
        0x8C,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x05,0x05,0x00,
        0x03,0x82,0x01,0x01,0x00,0x5F,0x3E,0x86,0x76,0x6E,0xB8,0x35,0x3C,0x4E,0x36,0x1C,
        0x1E,0x79,0x98,0xBF,0xFD,0xD5,0x12,0x11,0x79,0x52,0x0E,0xEE,0x31,0x89,0xBC,0xDD,
        0x7F,0xF9,0xD1,0xC6,0x15,0x21,0xE8,0x8A,0x01,0x54,0x0D,0x3A,0xFB,0x54,0xB9,0xD6,
        0x63,0xD4,0xB1,0xAA,0x96,0x4D,0xA2,0x42,0x4D,0xD4,0x53,0x1F,0x8B,0x10,0xDE,0x7F,
        0x65,0xBE,0x60,0x13,0x27,0x71,0x88,0xA4,0x73,0xE3,0x84,0x63,0xD1,0xA4,0x55,0xE1,
        0x50,0x93,0xE6,0x1B,0x0E,0x79,0xD0,0x67,0xBC,0x46,0xC8,0xBF,0x3F,0x17,0x0D,0x95,
        0xE6,0xC6,0x90,0x69,0xDE,0xE7,0xB4,0x2F,0xDE,0x95,0x7D,0xD0,0x12,0x3F,0x3D,0x3E,
        0x7F,0x4D,0x3F,0x14,0x68,0xF5,0x11,0x50,0xD5,0xC1,0xF4,0x90,0xA5,0x08,0x1D,0x31,
        0x60,0xFF,0x60,0x8C,0x23,0x54,0x0A,0xAF,0xFE,0xA1,0x6E,0xC5,0xD1,0x7A,0x2A,0x68,
        0x78,0xCF,0x1E,0x82,0x0A,0x20,0xB4,0x1F,0xAD,0xE5,0x85,0xB2,0x6A,0x68,0x75,0x4E,
        0xAD,0x25,0x37,0x94,0x85,0xBE,0xBD,0xA1,0xD4,0xEA,0xB7,0x0C,0x4B,0x3C,0x9D,0xE8,
        0x12,0x00,0xF0,0x5F,0xAC,0x0D,0xE1,0xAC,0x70,0x63,0x73,0xF7,0x7F,0x79,0x9F,0x32,
        0x25,0x42,0x74,0x05,0x80,0x28,0xBF,0xBD,0xC1,0x24,0x96,0x58,0x15,0xB1,0x17,0x21,
        0xE9,0x89,0x4B,0xDB,0x07,0x88,0x67,0xF4,0x15,0xAD,0x70,0x3E,0x2F,0x4D,0x85,0x3B,
        0xC2,0xB7,0xDB,0xFE,0x98,0x68,0x23,0x89,0xE1,0x74,0x0F,0xDE,0xF4,0xC5,0x84,0x63,
        0x29,0x1B,0xCC,0xCB,0x07,0xC9,0x00,0xA4,0xA9,0xD7,0xC2,0x22,0x4F,0x67,0xD7,0x77,
        0xEC,0x20,0x05,0x61,0xDE,
    };
    NSData *expectedDerFormattedData = [NSData dataWithBytes:expectedDerFormattedDataArray length:sizeof(expectedDerFormattedDataArray) / sizeof(uint8_t)];
    
    NSData *derFormattedData = [QredoCertificateUtils convertPemCertificateToDer:certificateChainPemString];
    
    XCTAssertNotNil(derFormattedData,@"Returned data should not be nil.");
    XCTAssertTrue([derFormattedData isEqualToData:expectedDerFormattedData],@"Converted data is incorrect.");
}


-(void)testConvertPemCertificateToDer_NilCertificate {
    NSString *certificateChainPemString = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils convertPemCertificateToDer:certificateChainPemString],NSException,NSInvalidArgumentException,@"Passed nil certificate string and expected exception not thrown.");
}


-(void)testConvertPemCertificateToDer_EmptyCert {
    NSString *certificateChainPemString = @"";
    
    NSData *derFormattedData = [QredoCertificateUtils convertPemCertificateToDer:certificateChainPemString];
    
    XCTAssertNil(derFormattedData,@"Returned data should be nil.");
}


-(void)testConvertPemCertificateToDer_IncorrectHeader {
    //DH localhost root CA with space missing in header
    NSString *certificateChainPemString = @"-----BEGINCERTIFICATE-----\n"
    "MIIDNzCCAqCgAwIBAgIJALQHVA0h4NWhMA0GCSqGSIb3DQEBBQUAMHExCzAJBgNV"
    "BAYTAkdCMQ8wDQYDVQQIEwZTdXJyZXkxEjAQBgNVBAcTCUd1aWxkZm9yZDETMBEG"
    "A1UEChMKREggVGVzdGluZzEUMBIGA1UECxMLRGV2ZWxvcG1lbnQxEjAQBgNVBAMT"
    "CWxvY2FsaG9zdDAeFw0xNDEwMjMxMDEwMzFaFw0yNDEwMjAxMDEwMzFaMHExCzAJ"
    "BgNVBAYTAkdCMQ8wDQYDVQQIEwZTdXJyZXkxEjAQBgNVBAcTCUd1aWxkZm9yZDET"
    "MBEGA1UEChMKREggVGVzdGluZzEUMBIGA1UECxMLRGV2ZWxvcG1lbnQxEjAQBgNV"
    "BAMTCWxvY2FsaG9zdDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAyHfptwhm"
    "XSjM8iR26kzjeDHoLEG9g1Mwe8SQhFcFIOSJF82ZgtCb3IjFBFFk8zeX1/jXK3TN"
    "oLIrB65xWIKGMz+TYmdkezN2oRFwMOyfxdo9Gg3YQZwOLytmlIGrGIlTbuzRaUiS"
    "zt2s0vPabTSzAfEVCfD+QwI/kdcbNaRRK/8CAwEAAaOB1jCB0zAdBgNVHQ4EFgQU"
    "xpVYMh1qB6ha9pwbam6obJ0H9y4wgaMGA1UdIwSBmzCBmIAUxpVYMh1qB6ha9pwb"
    "am6obJ0H9y6hdaRzMHExCzAJBgNVBAYTAkdCMQ8wDQYDVQQIEwZTdXJyZXkxEjAQ"
    "BgNVBAcTCUd1aWxkZm9yZDETMBEGA1UEChMKREggVGVzdGluZzEUMBIGA1UECxML"
    "RGV2ZWxvcG1lbnQxEjAQBgNVBAMTCWxvY2FsaG9zdIIJALQHVA0h4NWhMAwGA1Ud"
    "EwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEArVNPcRKa3n+w7rKQMTBJ1nH8LBmv"
    "3XIzP4Mbnxbult9/zp1x6tSf2H6JHr+ZGmYG123FKZCHkt9hZo0Z04qbRjB5F099"
    "lzUSQWxqBFk8fZoTBeDq+yFqqJutn6NFvszSXaIMgAyovwyrnRz1iLAK2HQ4y3k+"
    "qsxqTrGsJtFsdws=\n"
    "-----END CERTIFICATE-----\n";
    
    NSData *derFormattedData = [QredoCertificateUtils convertPemCertificateToDer:certificateChainPemString];
    
    XCTAssertNil(derFormattedData,@"Returned data should be nil.");
}


-(void)testConvertPemCertificateToDer_IncorrectFooter {
    //DH localhost root CA with space missing in footer
    NSString *certificateChainPemString = @"-----BEGIN CERTIFICATE-----\n"
    "MIIDNzCCAqCgAwIBAgIJALQHVA0h4NWhMA0GCSqGSIb3DQEBBQUAMHExCzAJBgNV"
    "BAYTAkdCMQ8wDQYDVQQIEwZTdXJyZXkxEjAQBgNVBAcTCUd1aWxkZm9yZDETMBEG"
    "A1UEChMKREggVGVzdGluZzEUMBIGA1UECxMLRGV2ZWxvcG1lbnQxEjAQBgNVBAMT"
    "CWxvY2FsaG9zdDAeFw0xNDEwMjMxMDEwMzFaFw0yNDEwMjAxMDEwMzFaMHExCzAJ"
    "BgNVBAYTAkdCMQ8wDQYDVQQIEwZTdXJyZXkxEjAQBgNVBAcTCUd1aWxkZm9yZDET"
    "MBEGA1UEChMKREggVGVzdGluZzEUMBIGA1UECxMLRGV2ZWxvcG1lbnQxEjAQBgNV"
    "BAMTCWxvY2FsaG9zdDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAyHfptwhm"
    "XSjM8iR26kzjeDHoLEG9g1Mwe8SQhFcFIOSJF82ZgtCb3IjFBFFk8zeX1/jXK3TN"
    "oLIrB65xWIKGMz+TYmdkezN2oRFwMOyfxdo9Gg3YQZwOLytmlIGrGIlTbuzRaUiS"
    "zt2s0vPabTSzAfEVCfD+QwI/kdcbNaRRK/8CAwEAAaOB1jCB0zAdBgNVHQ4EFgQU"
    "xpVYMh1qB6ha9pwbam6obJ0H9y4wgaMGA1UdIwSBmzCBmIAUxpVYMh1qB6ha9pwb"
    "am6obJ0H9y6hdaRzMHExCzAJBgNVBAYTAkdCMQ8wDQYDVQQIEwZTdXJyZXkxEjAQ"
    "BgNVBAcTCUd1aWxkZm9yZDETMBEGA1UEChMKREggVGVzdGluZzEUMBIGA1UECxML"
    "RGV2ZWxvcG1lbnQxEjAQBgNVBAMTCWxvY2FsaG9zdIIJALQHVA0h4NWhMAwGA1Ud"
    "EwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEArVNPcRKa3n+w7rKQMTBJ1nH8LBmv"
    "3XIzP4Mbnxbult9/zp1x6tSf2H6JHr+ZGmYG123FKZCHkt9hZo0Z04qbRjB5F099"
    "lzUSQWxqBFk8fZoTBeDq+yFqqJutn6NFvszSXaIMgAyovwyrnRz1iLAK2HQ4y3k+"
    "qsxqTrGsJtFsdws=\n"
    "-----ENDCERTIFICATE-----\n";
    
    NSData *derFormattedData = [QredoCertificateUtils convertPemCertificateToDer:certificateChainPemString];
    
    XCTAssertNil(derFormattedData,@"Returned data should be nil.");
}


-(void)testGetFirstPemCertificateFromString_2CertsWithNewLinesBetween {
    //DH localhost root CA
    //DH localhost generated cert with own root CA
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@\n%@",TestCertDHTestingLocalhostRootPem,TestCertDHTestingLocalhostClientPem];
    
    NSString *firstCertificate = [QredoCertificateUtils getFirstPemCertificateFromString:certificateChainPemString];
    
    XCTAssertNotNil(firstCertificate,@"Returned data should not be nil.");
    XCTAssertTrue([firstCertificate isEqualToString:TestCertDHTestingLocalhostRootPem]);
}


-(void)testGetFirstPemCertificateFromString_Invalid_NoPemCertPresent {
    NSString *certificateChainPemString = [NSString stringWithFormat:@"This is not a PEM certificate"];
    
    NSString *firstCertificate = [QredoCertificateUtils getFirstPemCertificateFromString:certificateChainPemString];
    
    XCTAssertNil(firstCertificate,@"Returned data should be nil.");
}


-(void)testSplitPemCertificateChain_2CertsWithNewLinesBetween {
    //DH localhost root CA
    //DH localhost generated cert with own root CA
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@\n%@",TestCertDHTestingLocalhostRootPem,TestCertDHTestingLocalhostClientPem];
    
    int expectedNumberOfCertificates = 2;
    
    NSArray *certificates = [QredoCertificateUtils splitPemCertificateChain:certificateChainPemString];
    
    XCTAssertNotNil(certificates,@"Returned data should not be nil.");
    XCTAssertEqual(certificates.count,expectedNumberOfCertificates,@"Wrong number of certificates returned.");
}


-(void)testSplitPemCertificateChain_4CertsWithoutNewLinesBetween {
    //DH localhost root CA
    //DH localhost generated cert with own root CA
    //DH localhost root CA
    //DH localhost generated cert with own root CA
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@%@%@",TestCertDHTestingLocalhostRootPem,TestCertDHTestingLocalhostClientPem,TestCertDHTestingLocalhostRootPem,TestCertDHTestingLocalhostClientPem];
    
    int expectedNumberOfCertificates = 4;
    
    NSArray *certificates = [QredoCertificateUtils splitPemCertificateChain:certificateChainPemString];
    
    XCTAssertNotNil(certificates,@"Returned data should not be nil.");
    XCTAssertEqual(certificates.count,expectedNumberOfCertificates,@"Wrong number of certificates returned.");
}


-(void)testSplitPemCertificateChain_2CertsSecondCorruptedFooter_Invalid {
    //DH localhost root CA
    //DH localhost generated cert with own root CA, but with footer missing part of required string
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@\n%@",
                                           TestCertDHTestingLocalhostRootPem,
                                           @"-----BEGIN CERTIFICATE-----\n"
                                           "MIIC2zCCAkQCCQDsrMSTG/EiqTANBgkqhkiG9w0BAQUFADBxMQswCQYDVQQGEwJH"
                                           "QjEPMA0GA1UECBMGU3VycmV5MRIwEAYDVQQHEwlHdWlsZGZvcmQxEzARBgNVBAoT"
                                           "CkRIIFRlc3RpbmcxFDASBgNVBAsTC0RldmVsb3BtZW50MRIwEAYDVQQDEwlsb2Nh"
                                           "bGhvc3QwHhcNMTQxMDIzMTAxNjUyWhcNMTUxMDIzMTAxNjUyWjBvMQswCQYDVQQG"
                                           "EwJHQjEPMA0GA1UECBMGTG9uZG9uMREwDwYDVQQHEwhSaWNobW9uZDEWMBQGA1UE"
                                           "ChMNUXJlZG8gVGVzdGluZzEQMA4GA1UECxMHRGV2aWNlczESMBAGA1UEAxMJbG9j"
                                           "YWxob3N0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuEAhSZt2ymqj"
                                           "NI4PIc8BPwhYPEjv5EIldZcQuuh3Vk1MRwiOGukGlKjx7SrewUMIxju1LHPL+zHK"
                                           "UrevmJ4zR5lX6rrhcUEkM0c18Fc4hxzP7JmFoHTKGbmJPrYDgTMp36E6ePcE7hoL"
                                           "hDhR0fqeMMyP4sM6+lV0f7o/mmgl0uWHbxpc/B5RpFK72Of9Q6ejnL1FpaeIAGmg"
                                           "tmwQMYQMsyaIvlVtJr0XyQg8hhyEobsHEAVJCt4k0mqxo1KkzDT7al5NgUfRu7xU"
                                           "nFheexOw06SWeCVteuWtO8IwgQPxcP5wN889O+tyd1NN5v1pif83dwhAcK0n4njp"
                                           "evRHDBBNOQIDAQABMA0GCSqGSIb3DQEBBQUAA4GBADp62/jJkQ6SptfX1eB2AmKH"
                                           "4X4/mSvUS7A2vtJmprPKk2sEp6dlNIWDahdNUiJnaG5+8a/InDExKwa72U9/KiIg"
                                           "wX8WceRcqBisWWkMz9DK+qRx0UtZlC3xkLP6FNAJKCxzBfKVJ7rKK33IwBA9vf30"
                                           "kQ74bYo9Fhz692vq2rXx\n"
                                           "-----END"];
    
    //Invalid cert chain should return nil to prevent continuation with corrupt certs.
    NSArray *certificates = [QredoCertificateUtils splitPemCertificateChain:certificateChainPemString];
    
    XCTAssertNil(certificates,@"Returned data should be nil.");
}


-(void)testGetCertificateRefsFromPemCertificates_OneCert {
    //DH localhost root CA
    NSString *certificatesPemString = TestCertDHTestingLocalhostRootPem;
    int expectedNumberOfCertificateRefs = 1;
    
    NSArray *certificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:certificatesPemString];
    
    XCTAssertNotNil(certificateRefs,@"Returned data should not be nil.");
    XCTAssertEqual(certificateRefs.count,expectedNumberOfCertificateRefs,@"Wrong number of certificate refs returned.");
}


-(void)testGetCertificateRefsFromPemCertificates_TwoCerts {
    //DH localhost root CA
    //DH localhost generated cert with own root CA
    NSString *certificatesPemString = [NSString stringWithFormat:@"%@%@",
                                       TestCertDHTestingLocalhostRootPem,
                                       TestCertDHTestingLocalhostClientPem];
    int expectedNumberOfCertificateRefs = 2;
    
    NSArray *certificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:certificatesPemString];
    
    XCTAssertNotNil(certificateRefs,@"Returned data should not be nil.");
    XCTAssertEqual(certificateRefs.count,expectedNumberOfCertificateRefs,@"Wrong number of certificate refs returned.");
}


-(void)testGetCertificateRefsFromPemCertificates_NilCerts {
    NSString *certificatesPemString = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils getCertificateRefsFromPemCertificates:certificatesPemString],NSException,NSInvalidArgumentException,@"Passed nil certificates string and expected exception not thrown.");
}


-(void)testGetCertificateRefsFromPemCertificates_EmptyCertString {
    NSString *certificatesPemString = @"";
    
    NSArray *certificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:certificatesPemString];
    
    XCTAssertNil(certificateRefs,@"Returned data should be nil.");
}


-(void)testValidateCertificateChain_ValidChainWithRoot_qredoTestCA {
    /*
     Test steps:
     1.) Create NSArray containing certificate chain refs
     2.) Create NSArray containing root certificate refs
     3.) Validate certificate chain against root certificates
     */
    
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@",cert,intermediateCert];
    int expectedNumberOfCertificateRefsInChain = 2;
    
    NSString *rootCertificatesPemString = rootCert;
    XCTAssertNotNil(rootCertificatesPemString);
    XCTAssertNil(error);
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificateRefs,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificateRefs.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSArray *certificateChainRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:certificateChainPemString];
    XCTAssertNotNil(certificateChainRefs,@"Certificate chain array should not be nil.");
    XCTAssertEqual(certificateChainRefs.count,expectedNumberOfCertificateRefsInChain,@"Wrong number of certificate chain refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validateCertificateChain:certificateChainRefs
                                                            rootCertificateRefs:rootCertificateRefs];
    XCTAssertNotNil((__bridge id)validatedKeyRef);
}


-(void)testValidateCertificateChain_ValidChainWithWrongRoot {
    /*
     Test steps:
     1.) Create NSArray containing certificate chain refs
     2.) Create NSArray containing root certificate refs
     3.) Validate certificate chain against root certificates
     */
    
    //Java-SDK cert chain with 4096 bit client cert and intermediate cert
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@",
                                           TestCertJavaSdkClient4096Pem,
                                           TestCertJavaSdkIntermediatePem];
    int expectedNumberOfCertificateRefsInChain = 2;
    
    //DH generated root - incorrect for chain
    NSString *rootCertificatesPemString = TestCertDHTestingLocalhostRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificateRefs,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificateRefs.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSArray *certificateChainRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:certificateChainPemString];
    XCTAssertNotNil(certificateChainRefs,@"Certificate chain array should not be nil.");
    XCTAssertEqual(certificateChainRefs.count,expectedNumberOfCertificateRefsInChain,@"Wrong number of certificate chain refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validateCertificateChain:certificateChainRefs
                                                            rootCertificateRefs:rootCertificateRefs];
    XCTAssertNil((__bridge id)validatedKeyRef);
}


-(void)testValidateCertificateChain_EmptyChain {
    /*
     Test steps:
     1.) Create NSArray containing certificate chain refs
     2.) Create NSArray containing root certificate refs
     3.) Validate certificate chain against root certificates
     */
    
    int expectedNumberOfCertificateRefsInChain = 0;
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = TestCertJavaSdkRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificateRefs,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificateRefs.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSArray *certificateChainRefs = [[NSArray alloc] init];
    XCTAssertNotNil(certificateChainRefs,@"Certificate chain array should not be nil.");
    XCTAssertEqual(certificateChainRefs.count,expectedNumberOfCertificateRefsInChain,@"Wrong number of certificate chain refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validateCertificateChain:certificateChainRefs
                                                            rootCertificateRefs:rootCertificateRefs];
    XCTAssertNil((__bridge id)validatedKeyRef);
}


-(void)testValidateCertificateChain_EmptyRoot {
    /*
     Test steps:
     1.) Create NSArray containing certificate chain refs
     2.) Create NSArray containing root certificate refs
     3.) Validate certificate chain against root certificates
     */
    
    //Java-SDK cert chain with 4096 bit client cert and intermediate cert
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@",
                                           TestCertJavaSdkClient4096Pem,
                                           TestCertJavaSdkIntermediatePem];
    int expectedNumberOfCertificateRefsInChain = 2;
    
    int expectedNumberOfRootCertificateRefs = 0;
    
    NSArray *rootCertificateRefs = [[NSArray alloc] init];
    
    XCTAssertNotNil(rootCertificateRefs,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificateRefs.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSArray *certificateChainRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:certificateChainPemString];
    XCTAssertNotNil(certificateChainRefs,@"Certificate chain array should not be nil.");
    XCTAssertEqual(certificateChainRefs.count,expectedNumberOfCertificateRefsInChain,@"Wrong number of certificate chain refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validateCertificateChain:certificateChainRefs
                                                            rootCertificateRefs:rootCertificateRefs];
    XCTAssertNil((__bridge id)validatedKeyRef);
}


-(void)testValidateCertificateChain_NilRoot {
    /*
     Test steps:
     1.) Create NSArray containing certificate chain refs
     2.) Create NSArray containing root certificate refs
     3.) Validate certificate chain against root certificates
     */
    
    //Java-SDK cert chain with 4096 bit client cert and intermediate cert
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@",
                                           TestCertJavaSdkClient4096Pem,
                                           TestCertJavaSdkIntermediatePem];
    int expectedNumberOfCertificateRefsInChain = 2;
    
    NSArray *rootCertificateRefs = nil;
    
    NSArray *certificateChainRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:certificateChainPemString];
    
    XCTAssertNotNil(certificateChainRefs,@"Certificate chain array should not be nil.");
    XCTAssertEqual(certificateChainRefs.count,expectedNumberOfCertificateRefsInChain,@"Wrong number of certificate chain refs returned.");
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils validateCertificateChain:certificateChainRefs
                                                             rootCertificateRefs:rootCertificateRefs],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testValidateCertificateChain_NilChain {
    /*
     Test steps:
     1.) Create NSArray containing certificate chain refs
     2.) Create NSArray containing root certificate refs
     3.) Validate certificate chain against root certificates
     */
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = TestCertJavaSdkRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificateRefs,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificateRefs.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSArray *certificateChainRefs = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils validateCertificateChain:certificateChainRefs
                                                             rootCertificateRefs:rootCertificateRefs],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate data and expected exception not thrown.");
}


-(void)testValidatePemCertificateChain_RsaAsCertAndRoot_Valid {
    //RSA Security Inc CA from Firefox
    NSString *certificateChainPemString = RsaSecurityIncRootCertPem;
    
    //RSA Security Inc CA from Firefox
    NSString *rootCertificatesPemString = RsaSecurityIncRootCertPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNotNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned valid SecKeyRef.");
}



-(void)testValidatePemCertificateChain_JavaSdkChain4096_Valid {
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    //Java-SDK cert chain with 4096 bit client cert
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@",cert,intermediateCert];
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = rootCert;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNotNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned valid SecKeyRef.");
}


-(void)testValidatePemCertificateChain_JavaSdkChain2048_Valid {
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert2.2048.IntCA1cert" error:&error];
    
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    //Java-SDK cert chain with 2048 bit client cert
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@",cert,intermediateCert];
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = rootCert;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNotNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned valid SecKeyRef.");
}


-(void)testValidatePemCertificateChain_JavaSdkChain2048_MissingIntermediate_Invalid {
    //Java-SDK 2048 bit client cert without intermediate certificate (broken chain)
    NSString *certificateChainPemString = TestCertJavaSdkClient2048Pem;
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = TestCertJavaSdkRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned nil SecKeyRef.");
}


-(void)testValidatePemCertificateChain_JavaSdkChain2048_IncorrectRoot_Invalid {
    //Java-SDK cert chain with 2048 bit client cert
    NSString *certificateChainPemString = [NSString stringWithFormat:@"%@%@",TestCertJavaSdkClient2048Pem,TestCertJavaSdkIntermediatePem];
    
    //Incorrect root cert
    NSString *rootCertificatesPemString = TestCertDHTestingLocalhostRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned nil SecKeyRef.");
}


-(void)testValidatePemCertificateChain_JavaSdkChain2048_IntermediateAsRoot_Valid {
    //Java-SDK cert chain with 2048 bit client cert
    NSError *error = nil;
    
    NSString *certificateChainPemString = [TestCertificates fetchPemForResource:@"clientCert2.2048.IntCA1cert" error:&error];
    
    //Incorrect root cert
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNotNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned nil SecKeyRef.");
}


//TODO: DH - Add test for invalid certificate length (e.g. 1024 bit key) when we can detect/check key length
//TODO: DH - Add test for invalid certificate crypto type (e.g. DSA) when we can crypto type in certs

-(void)testValidatePemCertificateChain_CertWithoutRoot_NoRootsProvided_Invalid {
    //DH localhost root CA
    NSString *certificateChainPemString = TestCertDHTestingLocalhostRootPem;
    
    int expectedNumberOfRootCertificateRefs = 0;
    
    //Empty array (no root certs)
    NSArray *rootCertificates = [[NSArray alloc] init];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned nil SecKeyRef.");
}


-(void)testValidatePemCertificateChain_CertWithRoot_IncorrectRoot_Invalid {
    //DH localhost generated cert with own root CA
    NSString *certificateChainPemString = TestCertDHTestingLocalhostClientPem;
    
    //RSA Security Inc CA from Firefox
    NSString *rootCertificatesPemString = RsaSecurityIncRootCertPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned nil SecKeyRef.");
}


-(void)testValidatePemCertificateChain_SingleCertWithRoot_MissingRoot_Invalid {
    //DH localhost generated cert with own root CA
    NSString *certificateChainPemString = TestCertDHTestingLocalhostClientPem;
    
    //No root certificates, just empty array
    NSArray *rootCertificates = [[NSArray alloc] init];
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    
    XCTAssertNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned nil SecKeyRef.");
}


-(void)testValidatePemCertificateChain_RootAndCertSwitched_Invalid {
    //DH localhost root CA
    NSString *certificateChainPemString = TestCertDHTestingLocalhostRootPem;
    
    //DH localhost generated cert with own root CA
    NSString *rootCertificatesPemString = TestCertDHTestingLocalhostClientPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates];
    XCTAssertNil((__bridge id)validatedKeyRef,@"Incorrect certificate validation result. Should have returned nil SecKeyRef.");
}


-(void)testValidatePemCertificateChain_NilCertChain {
    NSString *certificateChainPemString = nil;
    
    //DH localhost root CA
    NSString *rootCertificatesPemString = TestCertDHTestingLocalhostRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates],NSException,NSInvalidArgumentException,@"Passed nil certificate chain and expected exception not thrown.");
}


-(void)testValidatePemCertificateChain_NilRootCerts {
    //DH localhost generated cert with own root CA
    NSString *certificateChainPemString = TestCertDHTestingLocalhostClientPem;
    
    NSArray *rootCertificates = nil;
    
    XCTAssertThrowsSpecificNamed([QredoCertificateUtils validatePemCertificateChain:certificateChainPemString rootCertificateRefs:rootCertificates],NSException,NSInvalidArgumentException,@"Passed nil certificate chain and expected exception not thrown.");
}



-(void)testCreateAndValidateIdentityFromPkcs12Data_qredoTestCA_4096 {
    NSError *error = nil;
    
    NSString *pkcs12Password = @"password";
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert3.4096.IntCA1" error:&error];
    
    XCTAssertNotNil(pkcs12Data);
    XCTAssertNil(error);
    int expectedNumberOfCertsInCertChain = 2;
    
    //QredoTestCA root
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCertificatesPemString);
    XCTAssertNil(error);
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary,@"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecTrustRef trustRef = (SecTrustRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemTrust);
    XCTAssertNotNil((__bridge id)trustRef,@"Incorrect identity validation result dictionary contents. Should contain valid trust ref.");
    
    NSArray *certChain = (NSArray *)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemCertChain);
    XCTAssertNotNil(certChain,@"Incorrect identity validation result dictionary contents. Should contain valid cert chain array.");
    XCTAssertEqual(certChain.count,expectedNumberOfCertsInCertChain,@"Incorrect identity validation result dictionary contents. Wrong number of certificate refs in cert chain.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef,@"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
}


-(void)testCreateAndValidateIdentityFromPkcs12Data_Inavlid_qredoTestCA_WrongRoot {
    NSError *error = nil;
    
    NSString *pkcs12Password = @"password";
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert3.4096.IntCA1" error:&error];
    
    XCTAssertNotNil(pkcs12Data);
    XCTAssertNil(error);
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = TestCertJavaSdkRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertTrue(identityDictionary.count == 0,@"Incorrect identity validation result. Should have returned nil NSDictionary.");
}


-(void)testCreateAndValidateIdentityFromPkcs12Data_JavaSDK2048ClientWithIntermediate {
    NSError *error = nil;
    
    //Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert2.2048.IntCA1" error:&error];
    NSString *pkcs12Password = @"password";
    int expectedNumberOfCertsInCertChain = 2;
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary,@"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecTrustRef trustRef = (SecTrustRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemTrust);
    XCTAssertNotNil((__bridge id)trustRef,@"Incorrect identity validation result dictionary contents. Should contain valid trust ref.");
    
    NSArray *certChain = (NSArray *)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemCertChain);
    XCTAssertNotNil(certChain,@"Incorrect identity validation result dictionary contents. Should contain valid cert chain array.");
    XCTAssertEqual(certChain.count,expectedNumberOfCertsInCertChain,@"Incorrect identity validation result dictionary contents. Wrong number of certificate refs in cert chain.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef,@"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
}


-(void)testCreateAndValidateIdentityFromPkcs12Data_JavaSDK2048ClientWithIntermediate_IncorrectRoot {
    //Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    NSData *pkcs12Data = [NSData dataWithBytes:TestCertJavaSdkClient2048WithIntermediatePkcs12Array
                                        length:sizeof(TestCertJavaSdkClient2048WithIntermediatePkcs12Array) / sizeof(uint8_t)];
    NSString *pkcs12Password = @"password";
    
    //DH localhost root CA
    NSString *rootCertificatesPemString = TestCertDHTestingLocalhostRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertTrue(identityDictionary.count == 0,@"Incorrect identity validation result. Should have returned nil NSDictionary.");
}


-(void)testCreateAndValidateIdentityFromPkcs12Data_JavaSDK2048ClientWithIntermediate_InvalidPassword {
    //Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    NSData *pkcs12Data = [NSData dataWithBytes:TestCertJavaSdkClient2048WithIntermediatePkcs12Array
                                        length:sizeof(TestCertJavaSdkClient2048WithIntermediatePkcs12Array) / sizeof(uint8_t)];
    NSString *pkcs12Password = @"wrongPassword";
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = TestCertJavaSdkRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertNil(identityDictionary,@"Incorrect identity validation result. Should have returned nil NSDictionary.");
}


-(void)testCreateAndValidateIdentityFromPkcs12Data_InvalidData {
    //DH localhost root CA DER data (not PKCS#12 formatted)
    NSData *pkcs12Data = [NSData dataWithBytes:TestCertDHTestingLocalhostClientDerArray length:sizeof(TestCertDHTestingLocalhostClientDerArray) / sizeof(uint8_t)];
    NSString *pkcs12Password = @"";
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = TestCertJavaSdkRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertNil(identityDictionary,@"Incorrect identity validation result. Should have returned nil NSDictionary.");
}


-(void)testPKCS12ImportThenSigning_JavaSDK2048ClientWithIntermediate {
    //Import some PKCS#12 data and then use the private key to sign some data.  Then use the public key to verify the signature.
    
    NSError *error = nil;
    
    //1.) Create identity
    
    //Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert3.4096.IntCA1" error:&error];
    NSString *pkcs12Password = @"password";
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary,@"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef,@"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
    
    
    //2.) Get key refs
    const int messageLength = 64;
    const int saltLen = 32;
    NSData *message = [NSData dataWithRandomBytesOfLength:messageLength];
    
    SecKeyRef privateKeyRef = [QredoCryptoTestUtilities getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)privateKeyRef);
    SecKeyRef publicKeyRef = [QredoCryptoTestUtilities getPublicKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)publicKeyRef);
    
    //3.) Sign data
    NSData *signature = [QredoCrypto rsaPssSignMessage:message saltLength:saltLen keyRef:privateKeyRef];
    XCTAssertNotNil(signature);
    
    //4.) Verify data
    BOOL verified = [QredoCryptoTestUtilities rsaPssVerifySignature:signature forMessage:message saltLength:saltLen keyRef:publicKeyRef];
    XCTAssertTrue(verified);
}


-(void)testPKCS12ImportThenSigning_qredoTestCA {
    //Import some PKCS#12 data and then use the private key to sign some data.  Then use the public key to verify the signature.
    
    //1.) Create identity
    
    NSError *error = nil;
    
    NSString *pkcs12Password = @"password";
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert3.4096.IntCA1" error:&error];
    
    XCTAssertNotNil(pkcs12Data);
    XCTAssertNil(error);
    
    //QredoTestCA root
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCertificatesPemString);
    XCTAssertNil(error);
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary,@"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef,@"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
    
    
    //2.) Get key refs
    const int messageLength = 64;
    const int saltLen = 32;
    NSData *message = [NSData dataWithRandomBytesOfLength:messageLength];
    
    SecKeyRef privateKeyRef = [QredoCryptoTestUtilities getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)privateKeyRef);
    SecKeyRef publicKeyRef = [QredoCryptoTestUtilities getPublicKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)publicKeyRef);
    
    //3.) Sign data
    NSData *signature = [QredoCrypto rsaPssSignMessage:message saltLength:saltLen keyRef:privateKeyRef];
    XCTAssertNotNil(signature);
    
    //4.) Verify data
    BOOL verified = [QredoCryptoTestUtilities rsaPssVerifySignature:signature forMessage:message saltLength:saltLen keyRef:publicKeyRef];
    XCTAssertTrue(verified);
}


@end
