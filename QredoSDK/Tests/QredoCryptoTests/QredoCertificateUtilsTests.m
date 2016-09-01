/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoCertificateUtils.h"
#import "QredoCertificateUtils_Private.h"
#import "TestCertificates.h"
#import "NSData+QredoRandomData.h"
#import "QredoCrypto.h"
#import "QredoLoggerPrivate.h"

@interface QredoCertificateUtilsTests :XCTestCase

@end

@implementation QredoCertificateUtilsTests

-(void)setUp {
    [super setUp];
    
    //Must remove any existing keys before starting
    [QredoCrypto deleteAllKeysInAppleKeychain];
}

-(void)tearDown {
    //Must remove any keys after completing
    [QredoCrypto deleteAllKeysInAppleKeychain];
    
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
    SecCertificateRef certificateRef = [QredoCrypto getCertificateRefFromIdentityRef:identityRef];
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
    
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits
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
    
    SecKeyRef keyRef = [QredoCrypto importPkcs1KeyData:pkcs1Data
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

-(void)testValidatePemCertificateChain_CertWithRoot_Valid {
    //DH localhost generated cert with own root CA
    
    //Creation of Root Certificate Authority and self-signed certificate
    
    //IMPORTANT -> Add following line at the end of your openssl.cnf file
    //subjectAltName = DNS:example.com
    //otherwise you'll face "kSecTrustResultRecoverableTrustFailure" validation result
    //
    //NOTE: On OS X openssl.cnf is here: /System/Library/OpenSSL/openssl.cnf
    
    //Create a Root Certificate Authority certificate and private key
    
    //$ openssl req -config -config openssl.cnf -new -x509 -keyout test_root_ca_key.pem -out test_root_ca.crt -days 3650
    //Generating a 1024 bit RSA private key
    //...++++++
    //........................................++++++
    //writing new private key to 'test_client_cakey.pem'
    //Enter PEM pass phrase:
    //Verifying - Enter PEM pass phrase:
    //-----
    //You are about to be asked to enter information that will be incorporated
    //into your certificate request.
    //What you are about to enter is what is called a Distinguished Name or a DN.
    //There are quite a few fields but you can leave some blank
    //For some fields there will be a default value,
    //If you enter '.', the field will be left blank.
    //-----
    //Country Name (2 letter code) [AU]:
    //State or Province Name (full name) [Some-State]:
    //Locality Name (eg, city) []:
    //Organization Name (eg, company) [Internet Widgits Pty Ltd]:
    //Organizational Unit Name (eg, section) []:
    //Common Name (e.g. server FQDN or YOUR name) []:
    //Email Address []:
    
    //Create Client CSR
    
    //$ openssl req -new -out test_client.csr
    //Generating a 1024 bit RSA private key
    //...++++++
    //............++++++
    //writing new private key to 'privkey.pem'
    //Enter PEM pass phrase:
    //Verifying - Enter PEM pass phrase:
    //-----
    //You are about to be asked to enter information that will be incorporated
    //into your certificate request.
    //What you are about to enter is what is called a Distinguished Name or a DN.
    //There are quite a few fields but you can leave some blank
    //For some fields there will be a default value,
    //If you enter '.', the field will be left blank.
    //-----
    //Country Name (2 letter code) [AU]:
    //State or Province Name (full name) [Some-State]:
    //Locality Name (eg, city) []:
    //Organization Name (eg, company) [Internet Widgits Pty Ltd]:
    //Organizational Unit Name (eg, section) []:
    //Common Name (e.g. server FQDN or YOUR name) []:
    //Email Address []:
    
    //Please enter the following 'extra' attributes
    //to be sent with your certificate request
    //A challenge password []:
    //An optional company name []:
    
    //$ openssl x509 -req -days 365 -in test_client.csr -CA test_root_ca.crt -CAkey test_root_ca_key.pem -set_serial 01 -out test_client.crt
    //Signature ok
    //subject=/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd
    //Getting CA Private Key
    //Enter pass phrase for test_cakey.pem:
    
    
    NSString *newRootCertificatesPemString = @"-----BEGIN CERTIFICATE-----\n"
    "MIICsDCCAhmgAwIBAgIJANcISDG0V6EwMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV\n"
    "BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX\n"
    "aWRnaXRzIFB0eSBMdGQwHhcNMTUxMjExMTUzNzM0WhcNMjUxMjA4MTUzNzM0WjBF\n"
    "MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50\n"
    "ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB\n"
    "gQC+bEnE6V1zmhTp3jxfjdANSuDHJ8au26GRhirDuQ5S4aeGxJ2M3iKawjvS4J/H\n"
    "F4Voc8qyDM12DfkuqCjk4FbQaTsOrKZPW+M61w5qvvXqsE6y7sTqRZ2QJbc9avUG\n"
    "CQgo8cHsXAdpUKJynIl65tPcQNu7Rd8FCkGPngBvidwjNwIDAQABo4GnMIGkMB0G\n"
    "A1UdDgQWBBSDWtue1RiI4cN0R2zHx4rqu82z1zB1BgNVHSMEbjBsgBSDWtue1RiI\n"
    "4cN0R2zHx4rqu82z16FJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt\n"
    "U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJANcISDG0\n"
    "V6EwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAd3e0o6E4EG1/iFbu\n"
    "PlZhWE7Nw7puAfhYTB4oIqc/DBcooHYtcpUYOUyTlRYd7/dlFqjfgD5/0ppAvIEI\n"
    "iu6UD6O6J0uycPQTQnOa4u1gjrQ8EtYkN4tDFuqQjxl5Pg/iGbtg823wqGlJXrUW\n"
    "bciyRqxp5WnZOvqD6n8z0haN+LE=\n"
    "-----END CERTIFICATE-----\n"; //From test_root_ca.crt
    
    NSString *newCertificateChainPemString = @"-----BEGIN CERTIFICATE-----\n"
    "MIIB+TCCAWICAQEwDQYJKoZIhvcNAQEFBQAwRTELMAkGA1UEBhMCQVUxEzARBgNV\n"
    "BAgTClNvbWUtU3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0\n"
    "ZDAeFw0xNTEyMTExNTUwNDhaFw0xNjEyMTAxNTUwNDhaMEUxCzAJBgNVBAYTAkFV\n"
    "MRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBXaWRnaXRz\n"
    "IFB0eSBMdGQwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALk9gNSSLs1asDG0\n"
    "54Zep4RuXzRDmkfw398ebPo8WKvf/WQlKmbra504+AAfpfOj3/w0X6LwVZMGzuTa\n"
    "4YfGf55USUbZG2xbOk0PJOWyGzs8b3jHGGN6QBCNPZipxQRZHBZqerzIMFSx6AS0\n"
    "t9HoqHP1PnUr262MKfHUklW/BCgLAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEAgTEO\n"
    "vbwQydp85ak2GfPxKGuAui1qoA7NvYGPBxn6pET70yPitpm8VBnh2ReoI5WBpVg6\n"
    "NWXOGwDfzknk6k49iDb+dPoNbPbzx2+KUchV0o3qSJNxciiGHOJFc7iripZVEUNi\n"
    "1SN/uRPlMdXuSPOzY5t/94l9OFVjQLBawxUTcUs=\n"
    "-----END CERTIFICATE-----\n"; //From test_client.crt
    
    NSString *certificateChainPemString = TestCertDHTestingLocalhostClientPem;
    
    //DH localhost root CA
    NSString *rootCertificatesPemString = TestCertDHTestingLocalhostRootPem;
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:newRootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count,expectedNumberOfRootCertificateRefs,@"Wrong number of root certificate refs returned.");
    
    SecKeyRef validatedKeyRef = [QredoCertificateUtils validatePemCertificateChain:newCertificateChainPemString rootCertificateRefs:rootCertificates];
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

-(void)testCreateAndValidateIdentityFromPkcs12Data_DHTestCert {
    //https://gist.github.com/mtigas/952344
    //$ openssl pkcs12 -export -clcerts -in test_client.crt -inkey test_client_private.pem -out test_client.p12
    //Enter pass phrase for test_client_private.pem:
    //Enter Export Password:
    //Verifying - Enter Export Password:
    
    NSString *newRootCertificatesPemString = @"-----BEGIN CERTIFICATE-----\n"
    "MIICsDCCAhmgAwIBAgIJANcISDG0V6EwMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV\n"
    "BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX\n"
    "aWRnaXRzIFB0eSBMdGQwHhcNMTUxMjExMTUzNzM0WhcNMjUxMjA4MTUzNzM0WjBF\n"
    "MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50\n"
    "ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB\n"
    "gQC+bEnE6V1zmhTp3jxfjdANSuDHJ8au26GRhirDuQ5S4aeGxJ2M3iKawjvS4J/H\n"
    "F4Voc8qyDM12DfkuqCjk4FbQaTsOrKZPW+M61w5qvvXqsE6y7sTqRZ2QJbc9avUG\n"
    "CQgo8cHsXAdpUKJynIl65tPcQNu7Rd8FCkGPngBvidwjNwIDAQABo4GnMIGkMB0G\n"
    "A1UdDgQWBBSDWtue1RiI4cN0R2zHx4rqu82z1zB1BgNVHSMEbjBsgBSDWtue1RiI\n"
    "4cN0R2zHx4rqu82z16FJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt\n"
    "U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJANcISDG0\n"
    "V6EwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAd3e0o6E4EG1/iFbu\n"
    "PlZhWE7Nw7puAfhYTB4oIqc/DBcooHYtcpUYOUyTlRYd7/dlFqjfgD5/0ppAvIEI\n"
    "iu6UD6O6J0uycPQTQnOa4u1gjrQ8EtYkN4tDFuqQjxl5Pg/iGbtg823wqGlJXrUW\n"
    "bciyRqxp5WnZOvqD6n8z0haN+LE=\n"
    "-----END CERTIFICATE-----\n"; //From test_root_ca.crt
    
    unsigned char newTestCertDHTestingLocalhostClientPkcs12Array[3205] = {
        0x30,0x82,0x05,0xf1,0x02,0x01,0x03,0x30,0x82,0x05,0xb7,0x06,0x09,0x2a,0x86,0x48,
        0x86,0xf7,0x0d,0x01,0x07,0x01,0xa0,0x82,0x05,0xa8,0x04,0x82,0x05,0xa4,0x30,0x82,
        0x05,0xa0,0x30,0x82,0x02,0x9f,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x07,
        0x06,0xa0,0x82,0x02,0x90,0x30,0x82,0x02,0x8c,0x02,0x01,0x00,0x30,0x82,0x02,0x85,
        0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x07,0x01,0x30,0x1c,0x06,0x0a,0x2a,
        0x86,0x48,0x86,0xf7,0x0d,0x01,0x0c,0x01,0x06,0x30,0x0e,0x04,0x08,0x3e,0xbe,0xbb,
        0xbf,0xfa,0xbe,0xa9,0x86,0x02,0x02,0x08,0x00,0x80,0x82,0x02,0x58,0x23,0x5c,0x45,
        0x74,0x7e,0x9d,0x5c,0x63,0x92,0x1e,0x13,0x93,0xf1,0xb9,0x36,0xbb,0x61,0x51,0x04,
        0xc0,0x58,0x74,0x7f,0xa4,0x95,0xc5,0xcf,0xfc,0x1a,0x25,0xd4,0x79,0x0f,0x78,0x0e,
        0x3e,0xcd,0x99,0xf4,0xff,0xed,0x84,0xdc,0x51,0x98,0x5f,0xf6,0x86,0x69,0xd2,0xc6,
        0xe0,0x08,0xfd,0x30,0xd5,0x3f,0x02,0x34,0x08,0x2b,0x71,0x36,0xa8,0x90,0x8f,0xf6,
        0xdd,0x31,0xfb,0x62,0x10,0x47,0x52,0xff,0x2e,0x49,0x71,0xd1,0x77,0xe4,0x52,0xae,
        0x6a,0x7f,0x11,0xf2,0xde,0x90,0xab,0x05,0xfa,0x89,0x30,0x51,0xab,0x5b,0xdd,0xcd,
        0x1c,0x25,0x83,0x9e,0xef,0x2d,0xf7,0x52,0xc0,0xef,0x3b,0x9f,0x22,0x47,0x9f,0x3c,
        0x7f,0x0b,0x34,0xfe,0x2b,0xe2,0xb8,0x49,0x04,0x0c,0xcb,0xbf,0x0e,0x51,0x05,0x76,
        0x44,0x77,0xe9,0xe5,0x4f,0x69,0x52,0xca,0x3f,0x3f,0xd5,0x99,0x49,0x82,0xf2,0xc8,
        0x80,0x81,0xdb,0xd7,0x68,0xbc,0xda,0x83,0xad,0x04,0x9c,0x62,0x2a,0x89,0x9d,0x8b,
        0x5f,0x47,0xac,0xf3,0xcd,0x91,0x53,0x04,0xd8,0x70,0x13,0xcf,0x87,0x0f,0x63,0x5c,
        0x0b,0x9c,0x07,0x3d,0x8f,0x90,0xeb,0x33,0x14,0x90,0x07,0x2d,0x10,0x09,0x43,0x40,
        0x37,0x18,0x0f,0x3f,0x74,0x77,0x25,0x08,0xea,0xa6,0x44,0x59,0x58,0x71,0x3e,0x71,
        0xad,0xbd,0x64,0xd2,0x92,0x45,0x61,0x04,0xc4,0xbf,0x3c,0xb3,0x11,0xa8,0xc1,0xcf,
        0x28,0xf7,0x1b,0x93,0x72,0x1c,0xbb,0x23,0x50,0x86,0xc2,0x89,0x5e,0x68,0x60,0xd0,
        0xb5,0x56,0xd7,0x9c,0x87,0xd9,0x97,0x79,0xcb,0x54,0x7c,0x0d,0x1b,0x78,0xdc,0x0d,
        0xb4,0xc2,0xb7,0xaf,0x57,0x14,0x85,0x3c,0x42,0xc5,0x22,0x25,0x96,0x0a,0x9d,0x86,
        0x3b,0x20,0xef,0x82,0x31,0x01,0xea,0xc6,0xb8,0xe8,0xc8,0x7a,0xa0,0x43,0x2c,0xcd,
        0xd2,0xc9,0x30,0xc9,0xb9,0xea,0xef,0x6b,0x72,0x6c,0x2e,0xbc,0x02,0x74,0x4d,0x79,
        0x69,0x6b,0xe5,0x73,0xe3,0x60,0x53,0x59,0x64,0x06,0x38,0xdc,0x36,0x70,0x14,0xcb,
        0x10,0x64,0x3b,0x91,0xbd,0x6d,0x1f,0x0f,0x3d,0x1a,0x0a,0xcc,0x0d,0xe8,0xfa,0x14,
        0x64,0x73,0xe0,0x27,0xf0,0xc2,0xe5,0xe0,0xc4,0x60,0xe8,0x09,0xdd,0x72,0x80,0x62,
        0x60,0x92,0x48,0x93,0xdb,0x9c,0x07,0xae,0x88,0xa5,0x34,0x95,0xd3,0xb5,0x27,0x49,
        0x2c,0xc7,0xe9,0xe4,0x5c,0x51,0x69,0x80,0x32,0xfa,0x8a,0x29,0xaa,0x69,0x65,0x25,
        0x46,0xc1,0x7c,0xfd,0xb5,0xea,0x37,0x5c,0xe9,0xfe,0x5c,0x7c,0xa4,0xc9,0x33,0x73,
        0x2e,0x5d,0xfe,0x69,0x06,0x11,0xf2,0xf0,0x1b,0xa4,0x1f,0x22,0x4a,0x59,0xa0,0xea,
        0x5d,0x47,0x0e,0xe5,0x9d,0xa3,0x97,0xbf,0xf0,0x82,0x6c,0x1d,0x34,0x04,0x42,0x0a,
        0x44,0x19,0xb1,0xac,0x6e,0x35,0xb6,0xc1,0x48,0x27,0x61,0x42,0xe6,0x0b,0x24,0x08,
        0x7f,0x51,0xba,0xaa,0xae,0xb6,0x52,0xe6,0x62,0xb6,0x42,0x20,0x2d,0x72,0x57,0xa3,
        0xc8,0x73,0x21,0x60,0x69,0x07,0x7a,0xfc,0x2b,0xd6,0x8a,0xe9,0xac,0xd5,0xc1,0xac,
        0x3c,0xcd,0xb6,0x36,0x55,0x8f,0x43,0x98,0x3e,0x6a,0x0d,0x8d,0x98,0x56,0x01,0x0d,
        0x34,0x29,0xf5,0x13,0x1a,0x5d,0x0b,0xf5,0x84,0xd7,0x7f,0x81,0x9e,0x4c,0xe4,0x3e,
        0x86,0x84,0x21,0xda,0xec,0x2a,0xfa,0x11,0x18,0x9b,0x39,0x6d,0x84,0xd7,0x27,0xad,
        0x2b,0x1e,0xb8,0x41,0x9b,0x69,0x09,0xc8,0xff,0xc7,0x1a,0x96,0x0a,0xa8,0xbe,0xce,
        0x96,0xef,0x74,0x43,0x55,0xee,0x07,0x90,0xda,0xbf,0x02,0x67,0xd9,0x29,0x29,0xe1,
        0x80,0xca,0xf6,0xa7,0x3b,0x95,0x46,0x4b,0xdc,0xe4,0xc2,0x93,0x71,0xd0,0x0a,0x07,
        0xfb,0x40,0x41,0x8b,0xba,0xff,0x98,0xaf,0xe2,0x30,0x45,0x63,0x9d,0x78,0x55,0xf0,
        0xb1,0x2e,0x0a,0x53,0x25,0x30,0x82,0x02,0xf9,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,
        0x0d,0x01,0x07,0x01,0xa0,0x82,0x02,0xea,0x04,0x82,0x02,0xe6,0x30,0x82,0x02,0xe2,
        0x30,0x82,0x02,0xde,0x06,0x0b,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x0c,0x0a,0x01,
        0x02,0xa0,0x82,0x02,0xa6,0x30,0x82,0x02,0xa2,0x30,0x1c,0x06,0x0a,0x2a,0x86,0x48,
        0x86,0xf7,0x0d,0x01,0x0c,0x01,0x03,0x30,0x0e,0x04,0x08,0xb4,0xcb,0xb1,0x28,0x1f,
        0x6c,0x13,0xac,0x02,0x02,0x08,0x00,0x04,0x82,0x02,0x80,0x7f,0x95,0x27,0xcc,0xf0,
        0x36,0x73,0x2a,0xcf,0x83,0x96,0xf7,0xd9,0xa5,0xc8,0xc5,0x4f,0xf2,0x56,0x4d,0xbb,
        0x3c,0x00,0x91,0xf3,0x3b,0x35,0x6f,0xdb,0xe1,0x8d,0x88,0x0e,0x3d,0x44,0x60,0x36,
        0x57,0x5c,0x46,0x3d,0x5c,0x5b,0x7f,0x6b,0xd1,0x24,0x50,0x6e,0xaa,0x24,0x57,0xdd,
        0x41,0xa6,0x7f,0x9e,0x27,0x8d,0x19,0x8d,0x8c,0x0b,0x3e,0x4c,0xf4,0x50,0xff,0xd5,
        0xd0,0x26,0x94,0x51,0xeb,0xab,0x8d,0xa4,0x30,0x42,0x4e,0x31,0x8a,0x5d,0x18,0xb0,
        0x24,0x9e,0x6b,0x28,0x73,0xe6,0xdb,0x45,0xdb,0xc3,0xdb,0xc7,0x81,0xaf,0xd5,0x06,
        0x55,0x2c,0x64,0x6b,0x31,0xab,0xc3,0x8b,0xc5,0x88,0x49,0x07,0xc3,0x31,0x16,0x24,
        0x4f,0x86,0x69,0x96,0x92,0x22,0xe8,0x61,0x70,0x1c,0xa9,0x46,0x1e,0x7d,0xc4,0xd2,
        0xd2,0x3f,0x70,0xfb,0x3a,0x93,0xe3,0x90,0x0b,0x0d,0x67,0x59,0x83,0x93,0x29,0xf8,
        0x93,0xec,0x2b,0xe3,0xf3,0x39,0xb5,0xc6,0xb2,0x5b,0x95,0xe2,0x99,0x1b,0x5b,0x62,
        0xfa,0xc4,0x68,0x7b,0x1f,0x81,0x41,0x9d,0x32,0x2d,0x44,0xe3,0xbe,0x98,0x20,0xc5,
        0x87,0xef,0xa2,0x80,0x76,0x35,0x8a,0x8d,0xa2,0xcf,0x54,0x6b,0xec,0x30,0x12,0xdd,
        0x0e,0x4f,0x26,0x75,0xd4,0xe1,0x44,0x48,0x49,0xa7,0x09,0x47,0xa8,0x2f,0x9b,0x45,
        0xcf,0x42,0x8c,0x2b,0x23,0x5b,0x38,0xf9,0x41,0x70,0x0a,0xea,0xf4,0xe4,0x83,0x66,
        0x32,0x54,0xcc,0x9a,0x02,0x64,0xcf,0x09,0x00,0xbf,0xb8,0x90,0x2c,0xda,0x39,0xb2,
        0x73,0x0a,0xe2,0x50,0x94,0x33,0x84,0x65,0x2d,0xa6,0x7c,0xcf,0x8c,0x52,0xf9,0x0f,
        0x61,0x03,0xcd,0x0a,0x6d,0xd6,0x03,0xb7,0x1b,0x48,0x21,0xb2,0xd9,0x71,0x05,0xaa,
        0xb6,0xdc,0xb7,0x0a,0xf9,0xff,0x26,0x04,0x90,0x88,0x93,0xf9,0x7b,0xc1,0x19,0x77,
        0xae,0xc8,0x59,0x84,0x63,0xec,0x4b,0xe9,0xf4,0xcb,0x97,0x04,0x70,0xf7,0xca,0x5f,
        0xa6,0x92,0x50,0x44,0x2b,0xb1,0x82,0xee,0x72,0x59,0xef,0x88,0x1f,0xcd,0xb9,0x92,
        0xb7,0xc4,0x42,0xf7,0x15,0x02,0xf5,0xda,0xd1,0xbe,0x39,0xf0,0x95,0x28,0xdf,0xfe,
        0xd7,0x3d,0x17,0xa2,0x43,0x57,0x23,0x24,0x33,0x6e,0x38,0x9e,0xcb,0xe4,0xec,0x90,
        0x43,0x12,0xba,0x34,0x8d,0x2c,0x20,0x25,0x4c,0xee,0xf6,0x80,0x75,0x3e,0x31,0xa7,
        0xa1,0x92,0x1d,0x7f,0x09,0xa5,0xdf,0xec,0x92,0x1d,0x6a,0x25,0xa7,0x70,0x37,0x1e,
        0x5d,0xd0,0x44,0x93,0x1b,0x79,0x06,0xc1,0xf4,0x33,0x49,0xd5,0x58,0x6c,0xd6,0xb6,
        0xbe,0x52,0x85,0xb3,0x1c,0xb5,0x43,0xf6,0x0c,0x48,0x5c,0xa3,0xbf,0x16,0xbc,0x9c,
        0xa5,0xf9,0x15,0x20,0x1f,0x29,0xce,0x60,0x5d,0x43,0xf4,0x43,0x10,0x07,0xa9,0x8d,
        0x81,0xc9,0x9c,0x13,0xc8,0xe8,0x26,0xc8,0x3e,0x5c,0x71,0x6e,0x4f,0xbb,0x68,0xd8,
        0x17,0xb2,0x9f,0x14,0x47,0xc3,0xfb,0x0c,0xbb,0xb9,0xac,0x1d,0x87,0x5c,0x23,0x32,
        0xbe,0x15,0x25,0x54,0x8e,0x61,0x18,0xe0,0xc8,0x12,0xb4,0x08,0x3c,0x50,0x78,0x16,
        0x2b,0x54,0x3a,0x5b,0xfa,0x2a,0x4e,0x10,0xab,0x60,0x5c,0xe4,0x29,0x6e,0xd3,0x4b,
        0xa3,0xe6,0x1b,0xa9,0x5d,0x7e,0x54,0x39,0xd3,0x1c,0xc3,0xe7,0xbf,0x71,0x81,0x9d,
        0xb6,0x03,0x0d,0xa8,0xfc,0x6d,0x76,0x07,0x9c,0x16,0x52,0x96,0x5e,0x2f,0x4c,0x14,
        0x08,0xfb,0x5e,0x3e,0xc8,0x66,0xf8,0x04,0x09,0xc9,0x64,0x47,0x54,0xda,0x0e,0x45,
        0x8d,0x9e,0xd4,0xf1,0x1b,0xeb,0xb8,0x3f,0xfe,0x81,0xff,0xdc,0xee,0x4e,0xb5,0x8e,
        0x6d,0x2a,0x88,0x74,0xf6,0x58,0xce,0x7f,0x24,0x5a,0xc3,0xda,0x5e,0x4b,0xd7,0x9b,
        0xe3,0x67,0x56,0xbb,0x11,0x8a,0x3d,0x8d,0xeb,0x16,0x30,0x9f,0xe0,0xe0,0x30,0xc5,
        0xee,0xfa,0xa0,0xf4,0x35,0xd9,0x37,0x8f,0x60,0x86,0xfb,0x5c,0x99,0x86,0x3d,0x45,
        0x93,0xe7,0x18,0xce,0xa3,0x2b,0xbd,0x93,0x7d,0xbe,0x31,0xb4,0xf1,0x8c,0xf5,0x3a,
        0x33,0x12,0xe2,0x26,0x1a,0x57,0xd1,0xe5,0xc5,0x2c,0xf6,0x31,0x25,0x30,0x23,0x06,
        0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x09,0x15,0x31,0x16,0x04,0x14,0x3d,0xe0,
        0x3b,0xda,0xb1,0x39,0x99,0x1d,0xce,0x7d,0x5c,0xab,0x96,0x24,0x1f,0x60,0xba,0xf8,
        0xd3,0xe4,0x30,0x31,0x30,0x21,0x30,0x09,0x06,0x05,0x2b,0x0e,0x03,0x02,0x1a,0x05,
        0x00,0x04,0x14,0x8c,0x41,0x22,0xd8,0x56,0x7d,0x8f,0x16,0xd8,0xa5,0x76,0x88,0x0a,
        0xb7,0x28,0xed,0xc4,0xb7,0x23,0xe4,0x04,0x08,0x3f,0xb0,0xac,0x92,0x8f,0x8f,0xe7,
        0x53,0x02,0x02,0x08,0x00
    };
    
    //DH localhost generated cert with own root CA (CA included in data)
    NSData *pkcs12Data = [NSData dataWithBytes:newTestCertDHTestingLocalhostClientPkcs12Array length:sizeof(newTestCertDHTestingLocalhostClientPkcs12Array) / sizeof(uint8_t)];
    NSString *pkcs12Password = @"password";
    int expectedNumberOfCertsInCertChain = 1;
    
    //DH localhost root CA
    int expectedNumberOfRootCertificateRefs = 1;
    
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:newRootCertificatesPemString];
    
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
    
    SecKeyRef privateKeyRef = [QredoCrypto getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)privateKeyRef);
    SecKeyRef publicKeyRef = [QredoCrypto getPublicKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)publicKeyRef);
    
    //3.) Sign data
    NSData *signature = [QredoCrypto rsaPssSignMessage:message saltLength:saltLen keyRef:privateKeyRef];
    XCTAssertNotNil(signature);
    
    //4.) Verify data
    BOOL verified = [QredoCrypto rsaPssVerifySignature:signature forMessage:message saltLength:saltLen keyRef:publicKeyRef];
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
    
    SecKeyRef privateKeyRef = [QredoCrypto getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)privateKeyRef);
    SecKeyRef publicKeyRef = [QredoCrypto getPublicKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)publicKeyRef);
    
    //3.) Sign data
    NSData *signature = [QredoCrypto rsaPssSignMessage:message saltLength:saltLen keyRef:privateKeyRef];
    XCTAssertNotNil(signature);
    
    //4.) Verify data
    BOOL verified = [QredoCrypto rsaPssVerifySignature:signature forMessage:message saltLength:saltLen keyRef:publicKeyRef];
    XCTAssertTrue(verified);
}

@end
