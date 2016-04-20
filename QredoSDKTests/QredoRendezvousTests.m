/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoRendezvousTests.h"
#import "QredoTestUtils.h"
#import "QredoRendezvousEd25519Helper.h"
#import "QredoRendezvousHelpers.h"
#import "QredoClient.h"

#import "QredoCrypto.h"
#import "CryptoImplV1.h"
#import "QredoBase58.h"
#import "TestCertificates.h"
#import "QredoCertificateUtils.h"
#import "QredoLoggerPrivate.h"
#import "QredoPrivate.h"
#import "SSLTimeSyncServer.h"

#import <objc/runtime.h>

static int kRendezvousTestDurationSeconds = 120; // 2 minutes

@interface RendezvousListener :NSObject <QredoRendezvousObserver>

@property XCTestExpectation *expectation;

@end

@implementation RendezvousListener


XCTestExpectation *timeoutExpectation;


-(void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation {
    if (self.expectation) {
        [self.expectation fulfill];
    }
}


@end


void swizleMethodsForSelectorsInClass(SEL originalSelector, SEL swizzledSelector, Class class) {
    // When swizzling an instance method, use the following:
    //Class class = [self class];
    
    // When swizzling a class method, use the following:
    // Class class = object_getClass((id)self);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


@interface QredoRendezvousEd25519CreateHelper (QredoRendezvousTests)
+(void)swizleSigningMethod;
@end

@implementation QredoRendezvousEd25519CreateHelper (QredoRendezvousTests)

-(QLFRendezvousAuthSignature *)QredoRendezvousTests_signatureWithData:(NSData *)data error:(NSError **)error {
    QLFRendezvousAuthSignature *signature = [self QredoRendezvousTests_signatureWithData:data error:error];
    
    __block NSData *signatureData = nil;
    
    [signature ifRendezvousAuthX509_PEM:^(NSData *signature) {
        NSAssert(FALSE, @"Wrong signature type");
    } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {
        NSAssert(FALSE, @"Wrong signature type");
    } ifRendezvousAuthED25519:^(NSData *signature) {
        signatureData = signature;
    } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {
        NSAssert(FALSE, @"Wrong signature type");
    } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
        NSAssert(FALSE, @"Wrong signature type");
    }];
    
    NSMutableData *forgedSignatureData = [signatureData mutableCopy];
    unsigned char *forgedSignatureDataBytes = [forgedSignatureData mutableBytes];
    forgedSignatureDataBytes[0] = ~forgedSignatureDataBytes[0];
    
    QLFRendezvousAuthSignature *forgedSignature = [QLFRendezvousAuthSignature rendezvousAuthED25519WithSignature:forgedSignatureData];
    
    return forgedSignature;
}


+(void)swizleSigningMethod {
    Class class = self;
    SEL origSEL = @selector(signatureWithData:error:);
    SEL newSEL = @selector(QredoRendezvousTests_signatureWithData:error:);
    swizleMethodsForSelectorsInClass(origSEL, newSEL, class);
}


@end





@interface QredoRendezvousTests ()
{
    QredoClient *client;
    QredoClient *client2;
}

@property (nonatomic) id<CryptoImpl> cryptoImpl;
@property (nonatomic) NSArray *trustedRootPems;
@property (nonatomic) NSArray *crlPems;
@property (nonatomic) SecKeyRef privateKeyRef;
@property (nonatomic, copy) NSString *publicKeyCertificateChainPem;
@property  NSString *randomlyCreatedTag;


@end

@implementation QredoRendezvousTests

-(void)setUp {
    [super setUp];
    
    // Want tests to abort if error occurrs
    self.continueAfterFailure = NO;
    
    // Trusted root refs are required for X.509 tests, and form part of the CryptoImpl
    [self setupRootCertificates];
    [self setupCrls];
    self.cryptoImpl = [[CryptoImplV1 alloc] init];
    
    // Must remove any existing keys before starting
    [QredoCrypto deleteAllKeysInAppleKeychain];
    
    [self authoriseClient];
    [self authoriseClient2];
}


-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
    }
    // Should remove any existing keys after finishing
    [QredoCrypto deleteAllKeysInAppleKeychain];
}


-(QredoSecKeyRefPair *)setupKeypairForPublicKeyData:(NSData *)publicKeyData privateKeyData:(NSData *)privateKeyData keySizeBits:(NSInteger)keySizeBits {
    // Import a known Public Key and Private Key into Keychain
    
    // NOTE: This will fail if the key has already been imported (even with different identifier)
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyImport1";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKeyImport1";
    
    XCTAssertNotNil(publicKeyData);
    
    XCTAssertNotNil(privateKeyData);
    
    SecKeyRef publicKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyData
                                               keyLengthBits:keySizeBits
                                               keyIdentifier:publicKeyIdentifier
                                                   isPrivate:NO];
    XCTAssertTrue((__bridge id)publicKeyRef, @"Public Key import failed.");
    
    SecKeyRef privateKeyRef = [QredoCrypto importPkcs1KeyData:privateKeyData
                                                keyLengthBits:keySizeBits
                                                keyIdentifier:privateKeyIdentifier
                                                    isPrivate:YES];
    XCTAssertTrue((__bridge id)privateKeyRef, @"Private Key import failed.");
    
    QredoSecKeyRefPair *keyRefPair = [[QredoSecKeyRefPair alloc] initWithPublicKeyRef:publicKeyRef privateKeyRef:privateKeyRef];
    
    return keyRefPair;
}


-(void)setupRootCertificates {
    NSError *error = nil;
    
    // Test certs root CA cert
    NSString *rootCert = [TestCertificates fetchPemCertificateFromResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    self.trustedRootPems = [NSArray arrayWithObjects:rootCert, nil];
    XCTAssertNotNil(self.trustedRootPems);
}


-(void)setupCrls {
    NSError *error = nil;
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    self.crlPems = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
}


-(void)setupTestPublicCertificateAndPrivateKey4096Bit {
    // iOS only supports importing a private key in PKC#12 format, so some pain required in getting from PKCS#12 to
    // raw private RSA key, and the PEM public certificates
    
    // Import some PKCS#12 data and then get the certificate chain refs from the identity.
    // Use SecCertificateRefs to create a PEM which is then processed (to confirm validity)
    
    
    // 1.) Create identity - Test client certificate + priv key from QredoTestCA, with intermediate cert
    NSError *error = nil;
    
    NSString *pkcs12Password = @"password";
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert3.4096.IntCA1" error:&error];
    XCTAssertNotNil(pkcs12Data);
    XCTAssertNil(error);
    int expectedNumberOfCertsInCertChain = 2;
    
    // QredoTestCA root
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCertificatesPemString);
    XCTAssertNil(error);
    int expectedNumberOfRootCertificateRefs = 1;
    
    // Get the SecCertificateRef array for the root cert
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificates, @"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count, expectedNumberOfRootCertificateRefs, @"Wrong number of root certificate refs returned.");
    
    // Create an Identity using the PKCS#12 data, validated with the root certificate ref
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data
                                                                                             password:pkcs12Password
                                                                                  rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary, @"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    // Extract the SecTrustRef from the Identity Dictionary result to ensure trust was successful
    SecTrustRef trustRef = (SecTrustRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary, kSecImportItemTrust);
    XCTAssertNotNil((__bridge id)trustRef, @"Incorrect identity validation result dictionary contents. Should contain valid trust ref.");
    
    // Extract the certificate chain refs (client and intermediate certs) from the Identity Dictionary result to ensure chain is correct
    NSArray *certChain = (NSArray *)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary, kSecImportItemCertChain);
    XCTAssertNotNil(certChain, @"Incorrect identity validation result dictionary contents. Should contain valid cert chain array.");
    XCTAssertEqual(certChain.count, expectedNumberOfCertsInCertChain, @"Incorrect identity validation result dictionary contents. Wrong number of certificate refs in cert chain.");
    
    // Extract the SecIdentityRef from Identity Dictionary, this enables us to get the private SecKeyRef out, which is needed for RSA operations in tests
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary, kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef, @"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
    
    // Extract the SecKeyRef from the identity
    self.privateKeyRef = [QredoCrypto getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)self.privateKeyRef);
    
    // 2.) Create Certificate Refs from Identity Dictionary and convert to PEM string
    NSArray *certificateChainRefs = (NSArray *)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,
                                                                    kSecImportItemCertChain);
    XCTAssertNotNil(certificateChainRefs, @"Incorrect identity validation result dictionary contents. Should contain valid certificate chain array.");
    XCTAssertEqual(certificateChainRefs.count, expectedNumberOfCertsInCertChain, @"Incorrect identity validation result dictionary contents. Should contain expected number of certificate chain refs.");
    
    // The PEM certs for the full chain becomes the authentication tag in the tests.
    self.publicKeyCertificateChainPem = [QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateChainRefs];
    XCTAssertNotNil(self.publicKeyCertificateChainPem);
}


-(QredoClientOptions *)clientOptions:(BOOL)resetData {
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
    return clientOptions;
}


-(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}


-(void)authoriseClient {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:[QredoTestUtils randomPassword]
                                 options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
}


-(void)authoriseClient2 {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:[QredoTestUtils randomPassword]
                                 options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client2 = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
}


-(void)verifyRendezvous:(QredoRendezvous *)rendezvous randomTag:(NSString *)randomTag {
    XCTAssertEqual(rendezvous.duration, kRendezvousTestDurationSeconds);
    
    __block QredoClient *anotherClient = nil;
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:[QredoTestUtils randomPassword]
                             options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           anotherClient = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    [rendezvous addRendezvousObserver:listener];
    
    // Give time for the subscribe/getResponses process to complete before we respond. Avoid any previous responses being included in the respondExpectation
    [NSThread sleepForTimeInterval:2];
    
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:randomTag
                completionHandler:^(QredoConversation *conversation, NSError *error) {
                    XCTAssertNil(error);
                    [respondExpectation fulfill];
                }];
    
    [self waitForExpectationsWithTimeout:20.0 handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [rendezvous removeRendezvousObserver:listener];
    
    // Nil the listener expectation afterwards because have seen times when a different call to this method for the same Rendezvous has triggered fulfill twice, which throws an exception.  Wasn't a duplicate response, as it had a different ResponderPublicKey.
    listener.expectation = nil;
    
    // Making sure that we can enumerate responses
    __block BOOL found = false;
    __block XCTestExpectation *didEnumerateExpectation = [self expectationWithDescription:@"verify: enumerate conversation from loaded rendezvous"];
    [rendezvous enumerateConversationsWithBlock:^(QredoConversation *conversation, BOOL *stop) {
        XCTAssertNotNil(conversation);
        *stop = YES;
        found = YES;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [didEnumerateExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didEnumerateExpectation = nil;
    }];
    XCTAssertTrue(found);
    
    [anotherClient closeSession];
    
    // Remove the listener, to avoid any possibilty of the listener being held/called after exiting
    [rendezvous removeRendezvousObserver:listener];
}

-(void)testQuickCreateRandomRandezvous{
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [client createAnonymousRendezvousWithRandomTagCompletionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous.tag);
                               XCTAssertNotNil(rendezvous);
                               createdRendezvous = rendezvous;
                               [createExpectation fulfill];
                           }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
}


-(void)testQuickCreateRendezvousExpiresAt{
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [client createAnonymousRendezvousWithTag:[[QredoQUID QUID] QUIDString]
                                    duration:100
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error){
                               XCTAssertNil(error);
                               
                               long expires = [[rendezvous expiresAt] timeIntervalSince1970];
                               long now     = [[SSLTimeSyncServer date] timeIntervalSince1970];
                               long timeUntilExpiry = expires-now;
                               XCTAssert(timeUntilExpiry>80 && timeUntilExpiry<101,@"Expiry time not correctly set after creation");
                               
                               
                               XCTAssertNotNil(rendezvous);
                               createdRendezvous = rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
}

-(void)testQuickCreateRendezvousLongType{
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [client createAnonymousRendezvousWithTag:[[QredoQUID QUID] QUIDString]
                                    duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error){
         XCTAssertNil(error);
         XCTAssertNotNil(rendezvous);
         XCTAssertTrue(rendezvous.duration ==kRendezvousTestDurationSeconds,@"Duration not set");
         XCTAssertTrue(rendezvous.unlimitedResponses ==YES,@"Unlimited Responses not set");
                               
                               
                               
         createdRendezvous = rendezvous;
         [createExpectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];

}

-(void)testQuickCreateRendezvousShortType{
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [client createAnonymousRendezvousWithTag:[[QredoQUID QUID] QUIDString]
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error){
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous);
                               createdRendezvous = rendezvous;
                               [createExpectation fulfill];
                           }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
}


-(void)testCreateRendezvousAndGetResponses {
    self.continueAfterFailure = NO;
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(rendezvous);
         createdRendezvous = rendezvous;
         [createExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    
    __block XCTestExpectation *enumerationExpectation = [self expectationWithDescription:@"enumerate responses"];
    
    [createdRendezvous enumerateConversationsWithBlock:^(QredoConversation *conversation, BOOL *stop) {
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [enumerationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        enumerationExpectation = nil;
    }];
}


-(void)testCreateAndFetchAnonymousRendezvous {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous);
                               
                               XCTAssertNotNil(rendezvous.metadata);
                               XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
                               
                               rendezvousRef = rendezvous.metadata.rendezvousRef;
                               
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    __block XCTestExpectation *failCreateExpectation = [self expectationWithDescription:@"create rendezvous with the same tag"];
    
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNotNil(error);
                               XCTAssertNil(rendezvous);
                               
                               XCTAssertEqual(error.code, QredoErrorCodeRendezvousAlreadyExists);
                               
                               [failCreateExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        failCreateExpectation = nil;
    }];
    
    
    // Enumerating stored rendezvous
    __block XCTestExpectation *didFindStoredRendezvousMetadataExpecttion = [self expectationWithDescription:@"find stored rendezvous metadata"];
    __block QredoRendezvousMetadata *rendezvousMetadataFromEnumeration = nil;
    
    __block int count = 0;
    [client enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        if ([rendezvousMetadata.tag isEqualToString:randomTag]) {
            rendezvousMetadataFromEnumeration = rendezvousMetadata;
            XCTAssertNotNil(rendezvousMetadata.rendezvousRef);
            count++;
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(count, 1);
        [didFindStoredRendezvousMetadataExpecttion fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didFindStoredRendezvousMetadataExpecttion = nil;
    }];
    
    XCTAssertNotNil(rendezvousMetadataFromEnumeration);
    
    // Fetching the full rendezvous object
    __block XCTestExpectation *didFindStoredRendezvous = [self expectationWithDescription:@"find stored rendezvous"];
    __block QredoRendezvous *rendezvousFromEnumeration = nil;
    
    XCTAssertEqualObjects(rendezvousMetadataFromEnumeration.rendezvousRef.data, rendezvousRef.data);
    
    [client fetchRendezvousWithMetadata:rendezvousMetadataFromEnumeration completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(rendezvous);
        rendezvousFromEnumeration = rendezvous;
        [didFindStoredRendezvous fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        didFindStoredRendezvous = nil;
    }];
    
    XCTAssertNotNil(rendezvousFromEnumeration);
    
    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];
    
    
    // Trying to load the rendezvous by tag, without enumeration
    __block XCTestExpectation *didFetchExpectation = [self expectationWithDescription:@"fetch rendezvous from vault by tag"];
    __block QredoRendezvous *rendezvousFromFetch = nil;
    [client fetchRendezvousWithRef:rendezvousRef completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNotNil(rendezvous);
        XCTAssertNil(error);
        
        rendezvousFromFetch = rendezvous;
        [didFetchExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        didFetchExpectation = nil;
    }];
    
    
    XCTAssertNotNil(rendezvousFromFetch);
    
    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
}


-(void)testCreateDuplicateAndFetchAnonymousRendezvous {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(rendezvous);
         rendezvousRef = rendezvous.metadata.rendezvousRef;
         [createExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    __block XCTestExpectation *failCreateExpectation = [self expectationWithDescription:@"create rendezvous with the same tag"];
    
    [client createAnonymousRendezvousWithTag:randomTag
                                     duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(rendezvous);
         
         XCTAssertEqual(error.code, QredoErrorCodeRendezvousAlreadyExists);
         
         [failCreateExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        failCreateExpectation = nil;
    }];
    
    XCTAssertNotNil(rendezvousRef);
    
    
    // Enumerating stored rendezvous
    __block XCTestExpectation *didFindStoredRendezvousMetadataExpecttion = [self expectationWithDescription:@"find stored rendezvous metadata"];
    __block QredoRendezvousMetadata *rendezvousMetadataFromEnumeration = nil;
    
    __block int count = 0;
    [client enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        if ([rendezvousMetadata.tag isEqualToString:randomTag]) {
            rendezvousMetadataFromEnumeration = rendezvousMetadata;
            count++;
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(count, 1);
        [didFindStoredRendezvousMetadataExpecttion fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didFindStoredRendezvousMetadataExpecttion = nil;
    }];
    
    XCTAssertNotNil(rendezvousMetadataFromEnumeration);
    
    // Fetching the full rendezvous object
    __block XCTestExpectation *didFindStoredRendezvous = [self expectationWithDescription:@"find stored rendezvous"];
    __block QredoRendezvous *rendezvousFromEnumeration = nil;
    
    [client fetchRendezvousWithMetadata:rendezvousMetadataFromEnumeration completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(rendezvous);
        rendezvousFromEnumeration = rendezvous;
        [didFindStoredRendezvous fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        didFindStoredRendezvous = nil;
    }];
    
    
    XCTAssertNotNil(rendezvousFromEnumeration);
    
    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];
    
    
    // Trying to load the rendezvous by tag, without enumeration
    __block XCTestExpectation *didFetchExpectation = [self expectationWithDescription:@"fetch rendezvous from vault by tag"];
    __block QredoRendezvous *rendezvousFromFetch = nil;
    [client fetchRendezvousWithRef:rendezvousRef completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNotNil(rendezvous);
        XCTAssertNil(error);
        
        rendezvousFromFetch = rendezvous;
        [didFetchExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        didFetchExpectation = nil;
    }];
    
    
    XCTAssertNotNil(rendezvousFromFetch);
    
    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
}


-(void)testCreateAndRespondAnonymousRendezvous {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [client createAnonymousRendezvousWithTag:randomTag
                                      duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous);
                               createdRendezvous = rendezvous;
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        createExpectation = nil;
    }];
    //        [NSThread sleepForTimeInterval:1];
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    [createdRendezvous addRendezvousObserver:listener];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNotNil(createdRendezvous);
    
    __block QredoClient *anotherClient = nil;
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    
    
    
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:[QredoTestUtils randomPassword]
                             options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           anotherClient = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    [NSThread sleepForTimeInterval:1];
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    
    
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    
    [anotherClient respondWithTag:randomTag
                completionHandler:^(QredoConversation *conversation, NSError *error) {
                    XCTAssertNil(error);
                    XCTAssertNotNil(conversation);
                    
                    [respondExpectation fulfill];
                }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    //   [NSThread sleepForTimeInterval:1];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous removeRendezvousObserver:listener];
    
    [anotherClient closeSession];
    //       [NSThread sleepForTimeInterval:1];
}


-(void)testCreateAndRespondAnonymousRendezvousPreCreate {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [client createAnonymousRendezvousWithTag:randomTag
                                      duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous);
                               createdRendezvous = rendezvous;
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    [createdRendezvous addRendezvousObserver:listener];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNotNil(createdRendezvous);
      listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    
    
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    
    [client2 respondWithTag:randomTag
          completionHandler:^(QredoConversation *conversation, NSError *error) {
              XCTAssertNil(error);
              [respondExpectation fulfill];
          }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    //    [NSThread sleepForTimeInterval:5];
    
    QLog(@"transport: %@", client.serviceInvoker.transport);
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous removeRendezvousObserver:listener];
}


//-(void)common_createAndRespondRendezvousForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
//                                                       prefix:(NSString *)prefix {
//    QredoRendezvousConfiguration *configuration
//    = [[QredoRendezvousConfiguration alloc]
//       initWithConversationType:kRendezvousTestConversationType
//       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//       isUnlimitedResponseCount:YES];
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    __block QredoRendezvous *createdRendezvous = nil;
//    
//    [client createAuthenticatedRendezvousWithPrefix:prefix
//                                 authenticationType:authenticationType
//                                      configuration:configuration
//                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                                      XCTAssertNil(error);
//                                      XCTAssertNotNil(rendezvous);
//                                      createdRendezvous = rendezvous;
//                                      [createExpectation fulfill];
//                                  }];
//    
//    // Takes approx 10 seconds to generate RSA 4096 keypair, so ensure timeout is sufficient for all cases
//    // TODO: DH - Seem 15 seconds not long enough for RSA 4096 keygen to complete, trying 30. Still failed once on 30.  Making 2 mins for test!
//    [self waitForExpectationsWithTimeout:120.0 handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//    
//    // Listening for responses and respond from another client
//    RendezvousListener *listener = [[RendezvousListener alloc] init];
//    [createdRendezvous addRendezvousObserver:listener];
//    [NSThread sleepForTimeInterval:0.1];
//    XCTAssertNotNil(createdRendezvous);
//    
//    NSString *fullTag = createdRendezvous.metadata.tag;
//    
//    __block QredoClient *anotherClient = nil;
//    
//    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
//    
//    [QredoClient initializeWithAppId:k_APPID
//                appSecret:k_APPSECRET
//                userId:k_USERID
//                userSecret:[QredoTestUtils randomPassword]
//
//                                 options:[self clientOptions:YES]
//                       completionHandler:^(QredoClient *clientArg, NSError *error) {
//                           XCTAssertNil(error);
//                           XCTAssertNotNil(clientArg);
//                           anotherClient = clientArg;
//                           [clientExpectation fulfill];
//                       }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        // avoiding exception when 'fulfill' is called after timeout
//        clientExpectation = nil;
//    }];
//    
//    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
//    
//    
//    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
//    [anotherClient respondWithTag:fullTag
//                  trustedRootPems:self.trustedRootPems
//                          crlPems:self.crlPems
//                completionHandler:^(QredoConversation *conversation, NSError *error) {
//                    XCTAssertNil(error);
//                    [respondExpectation fulfill];
//                }];
//    
//    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
//    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
//    //    [NSThread sleepForTimeInterval:5];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        respondExpectation = nil;
//        listener.expectation = nil;
//    }];
//    
//    [createdRendezvous removeRendezvousObserver:listener];
//    
//    [anotherClient closeSession];
//}


//-(void)common_createAndRespondRendezvousForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
//                                                       prefix:(NSString *)prefix
//                                                    publicKey:(NSString *)publicKey
//                                               signingHandler:(signDataBlock)signingHandler {
//    XCTAssertNotNil(publicKey);
//    
//    NSString *expectedFullTag = nil;
//    if (prefix) {
//        // Prefix and public key
//        expectedFullTag = [NSString stringWithFormat:@"%@@%@", prefix, publicKey];
//    }
//    else {
//        // No prefix, just public key
//        expectedFullTag = [NSString stringWithFormat:@"@%@", publicKey];
//    }
//    
//    QredoRendezvousConfiguration *configuration
//    = [[QredoRendezvousConfiguration alloc]
//       initWithConversationType:kRendezvousTestConversationType
//       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//       isUnlimitedResponseCount:YES];
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    __block QredoRendezvous *createdRendezvous = nil;
//    
//    [client createAuthenticatedRendezvousWithPrefix:prefix
//                                 authenticationType:authenticationType
//                                      configuration:configuration
//                                          publicKey:publicKey
//                                    trustedRootPems:self.trustedRootPems
//                                            crlPems:self.crlPems
//                                     signingHandler:signingHandler
//                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                                      XCTAssertNil(error);
//                                      XCTAssertNotNil(rendezvous);
//                                      createdRendezvous = rendezvous;
//                                      [createExpectation fulfill];
//                                  }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//    
//    XCTAssertNotNil(createdRendezvous);
//    
//    NSString *fullTag = createdRendezvous.metadata.tag;
//    XCTAssertNotNil(fullTag);
//    XCTAssertTrue([fullTag isEqualToString:expectedFullTag]);
//    
//    
//    __block QredoClient *anotherClient = nil;
//    
//    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
//    
//    [QredoClient initializeWithAppSecret:k_APPSECRET
//                                  userId:k_USERID
//                              userSecret:[QredoTestUtils randomPassword]
//                                 options:[self clientOptions:YES]
//                       completionHandler:^(QredoClient *clientArg, NSError *error) {
//                           XCTAssertNil(error);
//                           XCTAssertNotNil(clientArg);
//                           anotherClient = clientArg;
//                           [clientExpectation fulfill];
//                       }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        // avoiding exception when 'fulfill' is called after timeout
//        clientExpectation = nil;
//    }];
//    
//    // Listening for responses and respond from another client
//    RendezvousListener *listener = [[RendezvousListener alloc] init];
//    
//    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
//    [createdRendezvous addRendezvousObserver:listener];
//    [NSThread sleepForTimeInterval:0.1];
//    __block QredoConversation *createdConversation = nil;
//    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
//    [anotherClient respondWithTag:fullTag
//                  trustedRootPems:self.trustedRootPems
//                          crlPems:self.crlPems
//                completionHandler:^(QredoConversation *conversation, NSError *error) {
//                    XCTAssertNotNil(conversation);
//                    XCTAssertNil(error);
//                    createdConversation = conversation;
//                    [respondExpectation fulfill];
//                }];
//    
//    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
//    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
//    [NSThread sleepForTimeInterval:5];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        respondExpectation = nil;
//        listener.expectation = nil;
//    }];
//    
//    // Delete the conversation, to allow this test to be run again (external keys, without providing a prefix will result in 'rendezvous already exists' otherwise
//    // Delete any created conversations (to allow rendezvous reuse)
//    XCTAssertNotNil(createdConversation);
//    
//    __block XCTestExpectation *deleteExpectation = [self expectationWithDescription:@"Deleted conversation"];
//    
//    [createdConversation deleteConversationWithCompletionHandler:^(NSError *error) {
//        XCTAssertNil(error);
//        [deleteExpectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        // avoiding exception when 'fulfill' is called after timeout
//        deleteExpectation = nil;
//    }];
//    
//    [createdRendezvous removeRendezvousObserver:listener];
//    
//    [anotherClient closeSession];
//}
//
//
//// TODO: DH - do other authenticated rendezvous types (X.509?)
//-(void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:randomPrefix];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix {
//    NSString *emptyPrefix = @"";
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:emptyPrefix];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
//    
//    // Generate Ed25519 keypair
//    QredoED25519SigningKey *signingKey = [self.cryptoImpl qredoED25519SigningKey];
//    NSString *publicKey = [QredoBase58 encodeData:signingKey.verifyKey.data];
//    
//    __block NSError *error = nil;
//    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
//        XCTAssertNotNil(data);
//        NSData *signature = [self.cryptoImpl qredoED25519SignMessage:data withKey:signingKey error:&error];
//        XCTAssertNotNil(signature);
//        XCTAssertNil(error);
//        return signature;
//    };
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:randomPrefix
//                                                       publicKey:publicKey
//                                                  signingHandler:signingHandler];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix {
//    NSString *emptyPrefix = @"";
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
//    
//    // Generate Ed25519 keypair
//    QredoED25519SigningKey *signingKey = [self.cryptoImpl qredoED25519SigningKey];
//    NSString *publicKey = [QredoBase58 encodeData:signingKey.verifyKey.data];
//    
//    __block NSError *error = nil;
//    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
//        XCTAssertNotNil(data);
//        NSData *signature = [self.cryptoImpl qredoED25519SignMessage:data withKey:signingKey error:&error];
//        XCTAssertNotNil(signature);
//        XCTAssertNil(error);
//        return signature;
//    };
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:emptyPrefix
//                                                       publicKey:publicKey
//                                                  signingHandler:signingHandler];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa2048Pem;
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:randomPrefix];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix {
//    NSString *emptyPrefix = @"";
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa2048Pem;
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:emptyPrefix];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa2048Pem;
//    
//    // Import a known Public Key and Private Key into Keychain
//    // NOTE: This test will fail if the key has already been imported (even with different identifier)
//    NSInteger keySizeBits = 2048;
//    
//    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient2048X509DerArray
//                                               length:sizeof(TestPubKeyJavaSdkClient2048X509DerArray) / sizeof(uint8_t)];
//    XCTAssertNotNil(publicKeyX509Data);
//    
//    NSData *publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyX509Data];
//    XCTAssertNotNil(publicKeyPkcs1Data);
//    
//    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient2048Pkcs1DerArray
//                                            length:sizeof(TestPrivKeyJavaSdkClient2048Pkcs1DerArray) / sizeof(uint8_t)];
//    XCTAssertNotNil(privateKeyData);
//    
//    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
//                                                         privateKeyData:privateKeyData
//                                                            keySizeBits:keySizeBits];
//    XCTAssertNotNil(keyRefPair);
//    
//    NSString *publicKey = TestKeyJavaSdkClient2048PemX509;
//    
//    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
//        XCTAssertNotNil(data);
//        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:authenticationType];
//        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
//        XCTAssertNotNil(signature);
//        return signature;
//    };
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:randomPrefix
//                                                       publicKey:publicKey
//                                                  signingHandler:signingHandler];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa4096Pem;
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:randomPrefix];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix {
//    NSString *emptyPrefix = @"";
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa4096Pem;
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:emptyPrefix];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa4096Pem;
//    
//    // Import a known Public Key and Private Key into Keychain
//    // NOTE: This test will fail if the key has already been imported (even with different identifier)
//    NSInteger keySizeBits = 4096;
//    
//    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
//                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
//    XCTAssertNotNil(publicKeyX509Data);
//    
//    NSData *publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyX509Data];
//    XCTAssertNotNil(publicKeyPkcs1Data);
//    
//    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
//                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
//    XCTAssertNotNil(privateKeyData);
//    
//    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
//                                                         privateKeyData:privateKeyData
//                                                            keySizeBits:keySizeBits];
//    XCTAssertNotNil(keyRefPair);
//    
//    NSString *publicKey = TestKeyJavaSdkClient4096PemX509;
//    
//    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
//        XCTAssertNotNil(data);
//        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:authenticationType];
//        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
//        XCTAssertNotNil(signature);
//        return signature;
//    };
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:randomPrefix
//                                                       publicKey:publicKey
//                                                  signingHandler:signingHandler];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_WithPrefix_Invalid {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeX509Pem;
//    
//    QredoRendezvousConfiguration *configuration
//    = [[QredoRendezvousConfiguration alloc]
//       initWithConversationType:kRendezvousTestConversationType
//       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//       isUnlimitedResponseCount:YES];
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    
//    [client createAuthenticatedRendezvousWithPrefix:randomPrefix
//                                 authenticationType:authenticationType
//                                      configuration:configuration
//                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                                      XCTAssertNotNil(error);
//                                      XCTAssertNil(rendezvous);
//                                      [createExpectation fulfill];
//                                  }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_EmptyPrefix_Invalid {
//    NSString *emptyPrefix = @"";
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeX509Pem;
//    
//    QredoRendezvousConfiguration *configuration
//    = [[QredoRendezvousConfiguration alloc]
//       initWithConversationType:kRendezvousTestConversationType
//       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//       isUnlimitedResponseCount:YES];
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    
//    [client createAuthenticatedRendezvousWithPrefix:emptyPrefix
//                                 authenticationType:authenticationType
//                                      configuration:configuration
//                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                                      XCTAssertNotNil(error);
//                                      XCTAssertNil(rendezvous);
//                                      [createExpectation fulfill];
//                                  }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousX509Pem_ExternalKeys_WithPrefix {
//    [self setupTestPublicCertificateAndPrivateKey4096Bit];
//    
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeX509Pem;
//    NSString *publicKey = self.publicKeyCertificateChainPem;
//    
//    // X.509 always needs a signing handler
//    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
//        XCTAssertNotNil(data);
//        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
//        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
//        XCTAssertNotNil(signature);
//        return signature;
//    };
//    
//    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
//                                                          prefix:randomPrefix
//                                                       publicKey:publicKey
//                                                  signingHandler:signingHandler];
//}
//
//
//-(void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix {
//    NSString *nilPrefix = nil; // Invalid, nil prefix
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
//    
//    NSString *expectedGeneratedPrefix = @""; // Nil prefix becomes empty prefix
//    
//    QredoRendezvousConfiguration *configuration
//    = [[QredoRendezvousConfiguration alloc]
//       initWithConversationType:kRendezvousTestConversationType
//       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//       isUnlimitedResponseCount:YES];
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    __block QredoRendezvous *createdRendezvous = nil;
//    
//    [client createAuthenticatedRendezvousWithPrefix:nilPrefix
//                                 authenticationType:authenticationType
//                                      configuration:configuration
//                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                                      XCTAssertNil(error);
//                                      XCTAssertNotNil(rendezvous);
//                                      createdRendezvous = rendezvous;
//                                      [createExpectation fulfill];
//                                  }];
//    
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//    
//    XCTAssertNotNil(createdRendezvous);
//    
//    NSString *fullTag = createdRendezvous.metadata.tag;
//    
//    NSArray *splitTagParts = [[fullTag copy] componentsSeparatedByString:@"@"];
//    XCTAssertNotNil(splitTagParts);
//    NSUInteger separatorCount = splitTagParts.count - 1;
//    XCTAssertTrue(separatorCount == 1);
//    XCTAssertTrue([splitTagParts[0] isEqualToString:expectedGeneratedPrefix]);
//}
//
//
//-(void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature {
//    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
//    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
//    
//    QredoRendezvousConfiguration *configuration   = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
//                                                                                                   durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//                                                                                          isUnlimitedResponseCount:YES];
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    __block QredoRendezvous *createdRendezvous = nil;
//    
//    [QredoRendezvousEd25519CreateHelper swizleSigningMethod];
//    
//    [client createAuthenticatedRendezvousWithPrefix:randomPrefix
//                                 authenticationType:authenticationType
//                                      configuration:configuration
//                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                                      XCTAssertNil(error);
//                                      XCTAssertNotNil(rendezvous);
//                                      createdRendezvous = rendezvous;
//                                      [createExpectation fulfill];
//                                  }];
//    
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//    [QredoRendezvousEd25519CreateHelper swizleSigningMethod];
//    
//    XCTAssertNotNil(createdRendezvous);
//    
//    NSString *fullTag = createdRendezvous.metadata.tag;
//    
//    __block QredoClient *anotherClient = nil;
//    
//    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
//    
//    [QredoClient initializeWithAppSecret:k_APPSECRET
//                                  userId:k_USERID
//                              userSecret:[QredoTestUtils randomPassword]
//                                 options:[self clientOptions:YES]
//                       completionHandler:^(QredoClient *clientArg, NSError *error) {
//                           XCTAssertNil(error);
//                           XCTAssertNotNil(clientArg);
//                           anotherClient = clientArg;
//                           [clientExpectation fulfill];
//                       }];
//    
//    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
//        // avoiding exception when 'fulfill' is called after timeout
//        clientExpectation = nil;
//    }];
//    
//    // Listening for responses and respond from another client
//    RendezvousListener *listener = [[RendezvousListener alloc] init];
//    
//    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
//    [createdRendezvous addRendezvousObserver:listener];
//    [NSThread sleepForTimeInterval:0.1];
//    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
//    [anotherClient respondWithTag:fullTag
//                  trustedRootPems:self.trustedRootPems
//                          crlPems:self.crlPems
//                completionHandler:^(QredoConversation *conversation, NSError *error) {
//                    XCTAssert(error);
//                    [respondExpectation fulfill];
//                }];
//    
//    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
//    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
//    [NSThread sleepForTimeInterval:5];
//    
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        respondExpectation = nil;
//        listener.expectation = nil;
//    }];
//    
//    [createdRendezvous removeRendezvousObserver:listener];
//    
//    [anotherClient closeSession];
//}
//

-(QredoRendezvousRef*)createRendezvousWithDuration:(int)testDuration {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:testDuration
                          unlimitedResponses:NO
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous);
                               
                               XCTAssertNotNil(rendezvous.metadata);
                               XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
                               
                               rendezvousRef = rendezvous.metadata.rendezvousRef;
                               
                               [createExpectation fulfill];
                           }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    self.randomlyCreatedTag = randomTag;
    return rendezvousRef;
}


-(void)testActivateExpiredRendezvous {
    int testDuration = 1;
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:1];
    XCTAssertNotNil(rendezvousRef);
    
    
    // now sleep until the rendezvous expires
    [NSThread sleepForTimeInterval:2];
    
    
    // check that it has expired
    // responding to the expired rendezvous should fail
    [client respondWithTag: self.randomlyCreatedTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        //
        XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse);
    }];
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    // now activate the rendezvous
    [client activateRendezvousWithRef:rendezvousRef duration:1000 completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        // check the responses
        XCTAssertNil(error);
        XCTAssertNotNil(rendezvous);
        
        XCTAssertNotNil(rendezvous.metadata);
        XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
        
        // ensure that the response count is unlimited and the duration is what we passed in
        XCTAssertTrue(rendezvous.unlimitedResponses==YES);
        XCTAssertTrue(rendezvous.duration == 1000);
        
        XCTAssert([self.randomlyCreatedTag isEqualToString:rendezvous.metadata.tag]);
        
        [createActivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createActivateExpectation = nil;
    }];
}


-(void)testActivateExpiredRendezvousAndFetchFromNewRef {

    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:1];
    XCTAssertNotNil(rendezvousRef);
    
    // now sleep until the rendezvous expires
    [NSThread sleepForTimeInterval:2];
    
    // check that it has expired
    // responding to the expired rendezvous should fail
    [client respondWithTag: self.randomlyCreatedTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        //
        
        XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse,@"Error is %@",error);
    }];
 
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    // now activate the rendezvous
    [client activateRendezvousWithRef:rendezvousRef duration: 1000 completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        // check the responses
        XCTAssertNil(error);
        XCTAssertNotNil(rendezvous);
        
        XCTAssertNotNil(rendezvous.metadata);
        XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
        QredoRendezvousRef *newRendezvousRef = rendezvous.metadata.rendezvousRef;
        
        [client fetchRendezvousWithRef:newRendezvousRef completionHandler:^(QredoRendezvous *activatedRendezvous, NSError *error) {
            XCTAssertNil(error,@"Error %@",error);
            XCTAssertNotNil(activatedRendezvous);
            XCTAssertNotNil(activatedRendezvous.metadata);
            XCTAssertNotNil(activatedRendezvous.metadata.rendezvousRef);
            
            XCTAssertTrue(activatedRendezvous.unlimitedResponses==YES);
            
            XCTAssertTrue(activatedRendezvous.duration ==1000);
            
            XCTAssert([self.randomlyCreatedTag isEqualToString:rendezvous.metadata.tag]);
        }];
        
        [createActivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createActivateExpectation = nil;
    }];
}


-(void)testActivateUnexpiredRendezvous {
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    // now activate the rendezvous
    [client activateRendezvousWithRef:rendezvousRef duration:1000 completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        // check the responses
        XCTAssertNil(error);
        XCTAssertNotNil(rendezvous);
        
        XCTAssertNotNil(rendezvous.metadata);
        XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
        XCTAssertTrue(rendezvous.unlimitedResponses==YES);
        XCTAssertTrue(rendezvous.duration == 1000);
        XCTAssert([self.randomlyCreatedTag isEqualToString:rendezvous.metadata.tag]);
        
        
        [createActivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createActivateExpectation = nil;
    }];
}


-(void)testActivateUnknownRendezvous {
    // create an invalid rendezvousRef
    QredoRendezvousRef *rendezvousRef = [self createUnknownRendezvousRef];
    XCTAssertNotNil(rendezvousRef);
   
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    // now activate the rendezvous.
    [client activateRendezvousWithRef:rendezvousRef duration:1000 completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        // check the response. it should return an error since the rendezvous cannot be found
        XCTAssertNotNil(error);
        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
        
        [createActivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createActivateExpectation = nil;
    }];
}


-(void)testActivateNilRendezvous {
    QredoRendezvousRef *rendezvousRef = NULL;
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    // now activate the rendezvous
    [client activateRendezvousWithRef:rendezvousRef duration:1000 completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        // check the responses. we expect an error
        XCTAssertNotNil(error);
        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
        
        [createActivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createActivateExpectation = nil;
    }];
}


-(void)testActivateUnexpiredRendezvousNilCompletionHandler {
   
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    XCTAssertNotNil(rendezvousRef);
    
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    @try {
        // activate the rendezvous with a nil completion handler
        [client activateRendezvousWithRef:rendezvousRef duration:1000 completionHandler: nil];
    }
    
    @catch (NSException *e) {
        // we are expecting an error. check it's the right one
        XCTAssert([e.reason isEqualToString:@"CompletionHandlerisNil"]);
        [createActivateExpectation fulfill];
    }
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createActivateExpectation = nil;
    }];
}


-(void)testActivateInvalidDuration {
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    // now activate the rendezvous
    [client activateRendezvousWithRef:rendezvousRef duration:-201 completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        // check the responses
        XCTAssertNotNil(error);
        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
        
        [createActivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createActivateExpectation = nil;
    }];
}


-(void)testDeactivateRendezvous {
   
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous"];
    
    
    // now deactivate the rendezvous
    [client deactivateRendezvousWithRef:rendezvousRef completionHandler:^(NSError *error) {
        //
        // check the response. Should just complete with no error
        XCTAssertNil(error);
        
        [deactivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        deactivateExpectation = nil;
    }];
}


-(void)testDeactivateExpiredRendezvous {
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:1];
    XCTAssertNotNil(rendezvousRef);
    
    // now sleep until the rendezvous expires
    [NSThread sleepForTimeInterval:2];
    
    
    // check that it has expired
    // responding to the expired rendezvous should fail
    [client respondWithTag: self.randomlyCreatedTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        //
        XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse);
    }];
    
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous"];
    
    
    // now deactivate the rendezvous
    [client deactivateRendezvousWithRef:rendezvousRef completionHandler:^(NSError *error) {
        //
        // check the response. Should just complete with no error
        XCTAssertNil(error);
        
        [deactivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        deactivateExpectation = nil;
    }];
}


-(void)testDeactivateAndRespondToRendezvous {
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:300];
    XCTAssertNotNil(rendezvousRef);
    
    
    // should not be able to respond to a deactivated rendezvous
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous"];
    
    
    [client deactivateRendezvousWithRef:rendezvousRef completionHandler:^(NSError *error) {
        //
        // check the response. Should just complete with no error
        XCTAssertNil(error);
        
        // responding to the deactivated rendezvous should fail
        [client respondWithTag: self.randomlyCreatedTag completionHandler:^(QredoConversation *conversation, NSError *error) {
            //
            XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse);
        }];
        
        [deactivateExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        deactivateExpectation = nil;
    }];
}


-(void)testDeactivateRendezvousNilCompletionHandler {
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous nil completion handler"];
    
    @try {
        // now deactivate the rendezvous
        [client deactivateRendezvousWithRef:rendezvousRef completionHandler: nil ];
    }
    
    @catch (NSException *e) {
        // we are expecting an error. check it's the right one
        XCTAssert([e.reason isEqualToString:@"CompletionHandlerisNil"]);
        [deactivateExpectation fulfill];
    }
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        deactivateExpectation = nil;
    }];
}


-(void)testDeactivateNilRendezvous {
    QredoRendezvousRef *rendezvousRef = nil;
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate nil rendezvous"];
    
    
    // now deactivate the rendezvous
    [client deactivateRendezvousWithRef:rendezvousRef completionHandler:^(NSError *error) {
        // check the responses. we expect an error
        XCTAssertNotNil(error);
        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
        
        [deactivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        deactivateExpectation = nil;
    }];
}


-(void)testDeactivateUnknownRendezvous {
    QredoRendezvousRef *newRef = [self createUnknownRendezvousRef];
    XCTAssertNotNil(newRef);
    
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate unknown rendezvous"];
    
    
    // now deactivate the rendezvous
    [client deactivateRendezvousWithRef:newRef completionHandler:^(NSError *error) {
        // check the responses. we expect an error. for this test it will be QredoErrorCodeRendezvousInvalidData
        XCTAssertNotNil(error);
        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
        [deactivateExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        deactivateExpectation = nil;
    }];
}


-(QredoRendezvousRef*)createUnknownRendezvousRef {
    QredoVault *vault = [client systemVault];
    
    NSDictionary *item1SummaryValues = @{@"name": @"Joe Bloggs"};
    QredoVaultItem *item1 =  [QredoVaultItem vaultItemWithMetadata: [QredoVaultItemMetadata   vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                    value:[@"item name" dataUsingEncoding:NSUTF8StringEncoding]];
    
    __block XCTestExpectation *createRendezvousRefExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    [vault putItem:item1 completionHandler:
     ^(QredoVaultItemMetadata  *newVaultItemMetadata, NSError *error)
     {
         rendezvousRef = [[QredoRendezvousRef alloc] initWithVaultItemDescriptor:newVaultItemMetadata.descriptor
                                                                           vault: vault];
         
         [createRendezvousRefExpectation fulfill];
     }];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createRendezvousRefExpectation = nil;
    }];
    
    return rendezvousRef;
}


@end
