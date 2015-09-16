/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
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
#import "QredoLogging.h"

#import <objc/runtime.h>

static NSString *const kRendezvousTestConversationType = @"test.chat";
static long long kRendezvousTestDurationSeconds = 120; // 2 minutes

@interface RendezvousListener : NSObject <QredoRendezvousObserver>

@property XCTestExpectation *expectation;

@end

@implementation RendezvousListener

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    NSLog(@"Rendezvous listener (%p) notified via qredoRendezvous:didReceiveReponse:  Rendezvous (hashed) Tag: %@. Conversation details: Type:%@, ID:%@, HWM:%@", self, rendezvous.metadata.tag, conversation.metadata.type, conversation.metadata.conversationId, conversation.highWatermark);

    if (self.expectation) {
        NSLog(@"Rendezvous listener (%p) fulfilling expectation (%p)", self, self.expectation);
        [self.expectation fulfill];
    } else {
        NSLog(@"No expectation configured.");
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
+ (void)swizleSigningMethod;
@end

@implementation QredoRendezvousEd25519CreateHelper (QredoRendezvousTests)

- (QLFRendezvousAuthSignature *)QredoRendezvousTests_signatureWithData:(NSData *)data error:(NSError **)error {
    
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

+ (void)swizleSigningMethod {
    Class class = self;
    SEL origSEL = @selector(signatureWithData:error:);
    SEL newSEL = @selector(QredoRendezvousTests_signatureWithData:error:);
    swizleMethodsForSelectorsInClass(origSEL, newSEL, class);
}

@end





@interface QredoRendezvousTests ()
{
    QredoClient *client;
}

@property (nonatomic) id<CryptoImpl> cryptoImpl;
@property (nonatomic) NSArray *trustedRootPems;
@property (nonatomic) NSArray *crlPems;
@property (nonatomic) SecKeyRef privateKeyRef;
@property (nonatomic, copy) NSString *publicKeyCertificateChainPem;

@end

@implementation QredoRendezvousTests

- (void)setUp {
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
}

-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
    }
    // Should remove any existing keys after finishing
    [QredoCrypto deleteAllKeysInAppleKeychain];
}

- (QredoSecKeyRefPair *)setupKeypairForPublicKeyData:(NSData *)publicKeyData privateKeyData:(NSData *)privateKeyData keySizeBits:(NSInteger)keySizeBits {
    
    // Import a known Public Key and Private Key into Keychain
    
    // NOTE: This will fail if the key has already been imported (even with different identifier)
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyImport1";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKeyImport1";
    
    XCTAssertNotNil(publicKeyData);
    NSLog(@"Public key (PKCS#1) data (%lu bytes): %@", (unsigned long)publicKeyData.length, [QredoLogging hexRepresentationOfNSData:publicKeyData]);
    
    XCTAssertNotNil(privateKeyData);
    NSLog(@"Private key data (%lu bytes): %@", (unsigned long)privateKeyData.length, [QredoLogging hexRepresentationOfNSData:privateKeyData]);
    
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

- (void)setupRootCertificates
{
    NSError *error = nil;
    
    // Test certs root CA cert
    NSString *rootCert = [TestCertificates fetchPemCertificateFromResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    self.trustedRootPems = [NSArray arrayWithObjects:rootCert, nil];
    XCTAssertNotNil(self.trustedRootPems);
}

- (void)setupCrls
{
    NSError *error = nil;
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    self.crlPems = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
}

- (void)setupTestPublicCertificateAndPrivateKey4096Bit
{
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

- (QredoClientOptions *)clientOptionsWithResetData:(BOOL)resetData
{
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
    clientOptions.resetData = resetData;
    
    return clientOptions;
}

- (void)authoriseClient
{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[self clientOptionsWithResetData:YES]
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

- (void)verifyRendezvous:(QredoRendezvous *)rendezvous randomTag:(NSString *)randomTag
{
    
    NSLog(@"Verifying rendezvous");
    
    XCTAssert([rendezvous.configuration.conversationType isEqualToString:kRendezvousTestConversationType]);
    XCTAssertEqual(rendezvous.configuration.durationSeconds.longLongValue, kRendezvousTestDurationSeconds);

    __block QredoClient *anotherClient = nil;

    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[self clientOptionsWithResetData:YES]
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
    NSLog(@"Created rendezvous listener (%p)", self);
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    [rendezvous addRendezvousObserver:listener];

    // Give time for the subscribe/getResponses process to complete before we respond. Avoid any previous responses being included in the respondExpectation
    [NSThread sleepForTimeInterval:2];

    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:randomTag
                  trustedRootPems:self.trustedRootPems
                          crlPems:self.crlPems
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        [respondExpectation fulfill];
        NSLog(@"Responded. Error = %@, Conversation = %@", error, conversation);
    }];

    [self waitForExpectationsWithTimeout:20.0 handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [rendezvous removeRendezvousObserver:listener];
    
    // Nil the listener expectation afterwards because have seen times when a different call to this method for the same Rendezvous has triggered fulfill twice, which throws an exception.  Wasn't a duplicate response, as it had a different ResponderPublicKey.
    listener.expectation = nil;
    
    // Making sure that we can enumerate responses
    NSLog(@"Enumerating conversations");
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

- (void)testCreateRendezvousAndGetResponses
{
    self.continueAfterFailure = NO;
    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
                                                                                                 durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
                                                                                                isUnlimitedResponseCount:YES];

    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    NSLog(@"Creating rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
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

- (void)testCreateAndFetchAnonymousRendezvous
{
    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
                                                                                                 durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
                                                                                                isUnlimitedResponseCount:YES];

    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];

    __block QredoRendezvousRef *rendezvousRef = nil;

    NSLog(@"Creating rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
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

    NSLog(@"Creating duplicate rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
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
    NSLog(@"Enumerating rendezvous");
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

    NSLog(@"Fetching rendezvous with metadata from enumeration");
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

    NSLog(@"Verifying rendezvous from enumeration");
    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];

    
    NSLog(@"Fetching rendezvous with ref");
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
    
    NSLog(@"Verifying rendezvous from fetch");
    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
}

- (void)testCreateDuplicateAndFetchAnonymousRendezvous
{
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
                                                                                                 durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
                                                                                        isUnlimitedResponseCount:YES
                                                   ];

    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    NSLog(@"Creating rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                      configuration:configuration
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
    
    NSLog(@"Creating duplicate rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
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
    NSLog(@"Enumerating rendezvous");
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
    
    NSLog(@"Fetching rendezvous with metadata from enumeration");
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
    
    NSLog(@"Verifying rendezvous from enumeration");
    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];
    
    
    NSLog(@"Fetching rendezvous with tag");
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
    
    NSLog(@"Verifying rendezvous from fetch");
    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
}

- (void)testCreateAndRespondAnonymousRendezvous
{
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       isUnlimitedResponseCount:YES];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSLog(@"Creating rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous);
                               createdRendezvous = rendezvous;
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    XCTAssertNotNil(createdRendezvous);

    NSLog(@"Verifying rendezvous");
    
    __block QredoClient *anotherClient = nil;
    
    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[self clientOptionsWithResetData:NO]
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
    NSLog(@"Created rendezvous listener (%p)", self);

    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    [createdRendezvous addRendezvousObserver:listener];
    
    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:randomTag
                  trustedRootPems:nil // Anonymous rendezvous, so technically not needed
                          crlPems:nil // Anonymous rendezvous, so technically not needed
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        [respondExpectation fulfill];
    }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    [NSThread sleepForTimeInterval:5];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous removeRendezvousObserver:listener];
    
    [anotherClient closeSession];

}


- (void)common_createAndRespondRendezvousForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                     prefix:(NSString *)prefix
{
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       isUnlimitedResponseCount:YES];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSLog(@"Creating authenticated rendezvous (generating internal keys)");
    [client createAuthenticatedRendezvousWithPrefix:prefix
                                 authenticationType:authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNil(error);
                                      XCTAssertNotNil(rendezvous);
                                      createdRendezvous = rendezvous;
                                      [createExpectation fulfill];
                                  }];
    
    // Takes approx 10 seconds to generate RSA 4096 keypair, so ensure timeout is sufficient for all cases
    // TODO: DH - Seem 15 seconds not long enough for RSA 4096 keygen to complete, trying 30. Still failed once on 30.  Making 2 mins for test!
    [self waitForExpectationsWithTimeout:120.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    XCTAssertNotNil(createdRendezvous);
    
    NSString *fullTag = createdRendezvous.metadata.tag;
    
    NSLog(@"Verifying rendezvous");
    
    __block QredoClient *anotherClient = nil;
    
    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[self clientOptionsWithResetData:NO]
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
    NSLog(@"Created rendezvous listener (%p)", self);
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    [createdRendezvous addRendezvousObserver:listener];
    
    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:fullTag
                  trustedRootPems:self.trustedRootPems
                          crlPems:self.crlPems
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        [respondExpectation fulfill];
    }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    [NSThread sleepForTimeInterval:5];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous removeRendezvousObserver:listener];
    
    [anotherClient closeSession];
}

- (void)common_createAndRespondRendezvousForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                        prefix:(NSString *)prefix
                                                     publicKey:(NSString *)publicKey
                                                signingHandler:(signDataBlock)signingHandler
{
    XCTAssertNotNil(publicKey);
    
    NSString *expectedFullTag = nil;
    if (prefix) {
        // Prefix and public key
        expectedFullTag = [NSString stringWithFormat:@"%@@%@", prefix, publicKey];
    }
    else {
        // No prefix, just public key
        expectedFullTag = [NSString stringWithFormat:@"@%@", publicKey];
    }
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       isUnlimitedResponseCount:YES];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSLog(@"Creating authenticated rendezvous (external keys)");
    [client createAuthenticatedRendezvousWithPrefix:prefix
                                 authenticationType:authenticationType
                                      configuration:configuration
                                          publicKey:publicKey
                                    trustedRootPems:self.trustedRootPems
                                            crlPems:self.crlPems
                                     signingHandler:signingHandler
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNil(error);
                                      XCTAssertNotNil(rendezvous);
                                      createdRendezvous = rendezvous;
                                      [createExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    XCTAssertNotNil(createdRendezvous);
    
    NSString *fullTag = createdRendezvous.metadata.tag;
    XCTAssertNotNil(fullTag);
    XCTAssertTrue([fullTag isEqualToString:expectedFullTag]);
    
    NSLog(@"Verifying rendezvous");
    
    __block QredoClient *anotherClient = nil;
    
    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[self clientOptionsWithResetData:NO]
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
    NSLog(@"Created rendezvous listener (%p)", self);
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    [createdRendezvous addRendezvousObserver:listener];
    
    NSLog(@"Responding to Rendezvous");
    __block QredoConversation *createdConversation = nil;
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:fullTag
                  trustedRootPems:self.trustedRootPems
                          crlPems:self.crlPems
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNotNil(conversation);
        XCTAssertNil(error);
        createdConversation = conversation;
        [respondExpectation fulfill];
    }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    [NSThread sleepForTimeInterval:5];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    // Delete the conversation, to allow this test to be run again (external keys, without providing a prefix will result in 'rendezvous already exists' otherwise
    // Delete any created conversations (to allow rendezvous reuse)
    XCTAssertNotNil(createdConversation);
    
    __block XCTestExpectation *deleteExpectation = [self expectationWithDescription:@"Deleted conversation"];
    
    [createdConversation deleteConversationWithCompletionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [deleteExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        deleteExpectation = nil;
    }];
    
    [createdRendezvous removeRendezvousObserver:listener];
    
    [anotherClient closeSession];
}


// TODO: DH - do other authenticated rendezvous types (X.509?)
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:randomPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix
{
    NSString *emptyPrefix = @"";
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:emptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
    
    // Generate Ed25519 keypair
    QredoED25519SigningKey *signingKey = [self.cryptoImpl qredoED25519SigningKey];
    NSString *publicKey = [QredoBase58 encodeData:signingKey.verifyKey.data];
    
    __block NSError *error = nil;
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSData *signature = [self.cryptoImpl qredoED25519SignMessage:data withKey:signingKey error:&error];
        XCTAssertNotNil(signature);
        XCTAssertNil(error);
        return signature;
    };
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:randomPrefix
                                                       publicKey:publicKey
                                                  signingHandler:signingHandler];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix
{
    NSString *emptyPrefix = @"";
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;

    // Generate Ed25519 keypair
    QredoED25519SigningKey *signingKey = [self.cryptoImpl qredoED25519SigningKey];
    NSString *publicKey = [QredoBase58 encodeData:signingKey.verifyKey.data];
    
    __block NSError *error = nil;
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSData *signature = [self.cryptoImpl qredoED25519SignMessage:data withKey:signingKey error:&error];
        XCTAssertNotNil(signature);
        XCTAssertNil(error);
        return signature;
    };
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:emptyPrefix
                                                       publicKey:publicKey
                                                  signingHandler:signingHandler];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa2048Pem;
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:randomPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix
{
    NSString *emptyPrefix = @"";
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa2048Pem;
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:emptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa2048Pem;
    
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 2048;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient2048X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient2048X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient2048Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient2048Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSString *publicKey = TestKeyJavaSdkClient2048PemX509;
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:authenticationType];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:randomPrefix
                                                       publicKey:publicKey
                                                  signingHandler:signingHandler];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa4096Pem;
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:randomPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix
{
    NSString *emptyPrefix = @"";
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa4096Pem;
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:emptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeRsa4096Pem;
    
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 4096;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSString *publicKey = TestKeyJavaSdkClient4096PemX509;
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:authenticationType];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:randomPrefix
                                                       publicKey:publicKey
                                                  signingHandler:signingHandler];
}

- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_WithPrefix_Invalid
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeX509Pem;
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       isUnlimitedResponseCount:YES];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    NSLog(@"Creating authenticated rendezvous (generating internal keys)");
    [client createAuthenticatedRendezvousWithPrefix:randomPrefix
                                 authenticationType:authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNotNil(error);
                                      XCTAssertNil(rendezvous);
                                      [createExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        createExpectation = nil;
    }];
}

- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_EmptyPrefix_Invalid
{
    NSString *emptyPrefix = @"";
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeX509Pem;
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       isUnlimitedResponseCount:YES];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    NSLog(@"Creating authenticated rendezvous (generating internal keys)");
    [client createAuthenticatedRendezvousWithPrefix:emptyPrefix
                                 authenticationType:authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNotNil(error);
                                      XCTAssertNil(rendezvous);
                                      [createExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        createExpectation = nil;
    }];
}

- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_ExternalKeys_WithPrefix
{
    [self setupTestPublicCertificateAndPrivateKey4096Bit];
    
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeX509Pem;
    NSString *publicKey = self.publicKeyCertificateChainPem;

    // X.509 always needs a signing handler
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };

    [self common_createAndRespondRendezvousForAuthenticationType:authenticationType
                                                          prefix:randomPrefix
                                                       publicKey:publicKey
                                                  signingHandler:signingHandler];
}

- (void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix
{
    NSString *nilPrefix = nil; // Invalid, nil prefix
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;

    NSString *expectedGeneratedPrefix = @""; // Nil prefix becomes empty prefix
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       isUnlimitedResponseCount:YES];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSLog(@"Creating rendezvous");
    [client createAuthenticatedRendezvousWithPrefix:nilPrefix
                                 authenticationType:authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNil(error);
                                      XCTAssertNotNil(rendezvous);
                                      createdRendezvous = rendezvous;
                                      [createExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    XCTAssertNotNil(createdRendezvous);
    
    NSString *fullTag = createdRendezvous.metadata.tag;
    
    NSArray *splitTagParts = [[fullTag copy] componentsSeparatedByString:@"@"];
    XCTAssertNotNil(splitTagParts);
    NSUInteger separatorCount = splitTagParts.count - 1;
    XCTAssertTrue(separatorCount == 1);
    XCTAssertTrue([splitTagParts[0] isEqualToString:expectedGeneratedPrefix]);
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    QredoRendezvousAuthenticationType authenticationType = QredoRendezvousAuthenticationTypeEd25519;
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       isUnlimitedResponseCount:YES];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [QredoRendezvousEd25519CreateHelper swizleSigningMethod];
    
    NSLog(@"Creating rendezvous");
    [client createAuthenticatedRendezvousWithPrefix:randomPrefix
                                 authenticationType:authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNil(error);
                                      XCTAssertNotNil(rendezvous);
                                      createdRendezvous = rendezvous;
                                      [createExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    [QredoRendezvousEd25519CreateHelper swizleSigningMethod];
    
    XCTAssertNotNil(createdRendezvous);
    
    NSString *fullTag = createdRendezvous.metadata.tag;
    
    NSLog(@"Verifying rendezvous");
    
    __block QredoClient *anotherClient = nil;
    
    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[self clientOptionsWithResetData:NO]
                              completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  anotherClient = clientArg;
                                  [clientExpectation fulfill];
                                  
                              }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    NSLog(@"Created rendezvous listener (%p)", self);
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    [createdRendezvous addRendezvousObserver:listener];
    
    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:fullTag
                  trustedRootPems:self.trustedRootPems
                          crlPems:self.crlPems
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssert(error);
        [respondExpectation fulfill];
    }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    [NSThread sleepForTimeInterval:5];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous removeRendezvousObserver:listener];
    
    [anotherClient closeSession];
}

@end
