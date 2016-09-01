/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoSecKeyRefPair.h"
#import "QredoCrypto.h"
#import "QredoLoggerPrivate.h"
#import "TestCertificates.h"
#import "QredoCertificateUtils.h"

@interface QredoSecKeyRefPairTests : XCTestCase

@end

@implementation QredoSecKeyRefPairTests

- (void)setUp {
    [super setUp];

    // Must remove any existing keys before starting
    [QredoCrypto deleteAllKeysInAppleKeychain];
}

- (void)tearDown {
    [super tearDown];
    
    // Must remove any existing keys after finishing
    [QredoCrypto deleteAllKeysInAppleKeychain];
}

- (void)testInitFromKeyGen
{
    // Note: SecKeyGeneratePair returns SecKeyRefs which needs to be released afterwards. QredoSecKeyRefPair does this in dealloc.
    
    // Key gen options
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger lengthBits = 1024;
    BOOL persistKeys = NO;
    
    NSString *plainText = @"This is the plain text.";
    NSData *plainTextData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    // Generate the keys
    //Allocate dictionaries used for attributes in the SecKeyGeneratePair function
    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
    
    // NSData of the string attributes, used for finding keys easier
    NSData* publicTag = [publicKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    NSData* privateTag = [privateKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    SecKeyRef publicKeyRef = NULL;
    SecKeyRef privateKeyRef = NULL;
    
    // Set key-type and key-size
    keyPairAttr[(__bridge id) kSecAttrKeyType] = (__bridge id) kSecAttrKeyTypeRSA;
    keyPairAttr[(__bridge id) kSecAttrKeySizeInBits] = [NSNumber numberWithInteger:lengthBits];
    
    // Specifies whether private/public key is stored permanently (i.e. in keychain)
    privateKeyAttr[(__bridge id) kSecAttrIsPermanent] = [NSNumber numberWithBool:persistKeys];
    publicKeyAttr[(__bridge id) kSecAttrIsPermanent] = [NSNumber numberWithBool:persistKeys];
    
    // Set the identifier name for private/public key
    privateKeyAttr[(__bridge id) kSecAttrApplicationTag] = privateTag;
    publicKeyAttr[(__bridge id) kSecAttrApplicationTag] = publicTag;
    
    // Sets the private/public key attributes just built up
    keyPairAttr[(__bridge id) kSecPrivateKeyAttrs] = privateKeyAttr;
    keyPairAttr[(__bridge id) kSecPublicKeyAttrs] = publicKeyAttr;
    
    // Generate the keypair
    OSStatus status = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKeyRef, &privateKeyRef);
    XCTAssertTrue(status == errSecSuccess);
    XCTAssertNotNil((__bridge id)publicKeyRef);
    XCTAssertNotNil((__bridge id)privateKeyRef);
    
    // Encrypt some data using the public key
    NSData *cipherText = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:QredoPaddingOaep keyRef:publicKeyRef];
    XCTAssertNotNil(cipherText);
    XCTAssertEqual(cipherText.length, lengthBits / 8);

    // Attempt to decrypt the data using the private key (before dealloc)
    NSData *returnedPlainTextData = [QredoCrypto rsaDecryptCipherTextData:cipherText padding:QredoPaddingOaep keyRef:privateKeyRef];
    XCTAssertNotNil(returnedPlainTextData);
    XCTAssertTrue([returnedPlainTextData isEqualToData:plainTextData]);
    returnedPlainTextData = nil;
}

- (void)testInitFromImport
{
    // Note: SecItemAdd returns SecKeyRef, but no mention on needing to be released afterwards. QredoSecKeyRefPair does this in dealloc.  This test attempts to confirm release does not cause any unexpected behaviour.

    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyImport1";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKeyImport1";
    NSInteger keySizeBits = 2048;
    
    NSString *plainText = @"This is the plain text.";
    NSData *plainTextData = [plainText dataUsingEncoding:NSUTF8StringEncoding];

    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient2048X509DerArray
                                           length:sizeof(TestPubKeyJavaSdkClient2048X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient2048Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient2048Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    SecKeyRef publicKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyPkcs1Data
                                               keyLengthBits:keySizeBits
                                               keyIdentifier:publicKeyIdentifier
                                                   isPrivate:NO];
    XCTAssertTrue((__bridge id)publicKeyRef, @"Public Key import failed.");
    
    SecKeyRef privateKeyRef = [QredoCrypto importPkcs1KeyData:privateKeyData
                                                keyLengthBits:keySizeBits
                                                keyIdentifier:privateKeyIdentifier
                                                    isPrivate:YES];
    XCTAssertTrue((__bridge id)privateKeyRef, @"Private Key import failed.");

    // Confirm keys imported are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    // Encrypt some data using the public key
    QredoPadding encryptPaddingType = QredoPaddingPkcs1;
    QredoPadding decryptPaddingType = QredoPaddingPkcs1;
    NSData *cipherText = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:encryptPaddingType keyRef:publicKeyRef];
    XCTAssertNotNil(cipherText);
    XCTAssertEqual(cipherText.length, keySizeBits / 8);
    
    // Attempt to decrypt the data using the private key (before dealloc)
    NSData *returnedPlainTextData = [QredoCrypto rsaDecryptCipherTextData:cipherText padding:decryptPaddingType keyRef:privateKeyRef];
    XCTAssertNotNil(returnedPlainTextData);
    XCTAssertTrue([returnedPlainTextData isEqualToData:plainTextData]);
    
    returnedPlainTextData = nil;
    
}

@end
