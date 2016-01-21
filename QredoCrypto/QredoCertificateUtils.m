/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoCertificateUtils.h"
#import "QredoLoggerPrivate.h"
#import "QredoCryptoError.h"
#import "QredoCrypto.h"
#import "QredoRsaPublicKey.h"
#import "QredoDerUtils.h"

@implementation QredoCertificateUtils

static NSString *const PEM_CERTIFICATE_START = @"-----BEGIN CERTIFICATE-----\n";
static NSString *const PEM_CERTIFICATE_END = @"\n-----END CERTIFICATE-----\n";
static NSString *const PEM_KEY_START = @"-----BEGIN PUBLIC KEY-----\n";
static NSString *const PEM_KEY_END = @"\n-----END PUBLIC KEY-----\n";

+ (SecCertificateRef)createCertificateWithPemCertificate:(NSString *)pemCertificate
{
    [QredoCryptoError throwArgExceptionIf:!pemCertificate reason:@"Certificate string argument is nil"];

    NSData *certificateData = [QredoCertificateUtils convertPemCertificateToDer:pemCertificate];
    if (!certificateData) {
        QredoLogError(@"Failed to convert PEM certificate to DER format.");
        return nil;
    }
    
    SecCertificateRef certificateRef = [QredoCertificateUtils createCertificateWithDerData:certificateData];
    if (!certificateRef) {
        QredoLogError(@"Failed to create certificate ref from DER data.");
    }
    
    return certificateRef;
}

+ (SecCertificateRef)createCertificateWithDerData:(NSData *)certificateData
{
    [QredoCryptoError throwArgExceptionIf:!certificateData reason:@"Certificate data argument is nil"];

    // Note: certificate data must be X.509 DER encoded.
    SecCertificateRef certificateRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData);
    if (certificateRef) {
        // TODO get rid of me
    } else {
        QredoLogError(@"Could not create certificate using provided data: %@.",
                 [QredoLogger hexRepresentationOfNSData:certificateData]);
    }
    
    return certificateRef;
}

+ (NSString *)convertCertificateRefsToPemCertificate:(NSArray *)certificateRefs
{
    [QredoCryptoError throwArgExceptionIf:!certificateRefs reason:@"Certificate refs argument is nil"];

    NSMutableString *pemCertificates = [[NSMutableString alloc] init];
    // Go through all certificate refs (in current order) and conver to PEM, appending them onto each other
    for (int i = 0; i < certificateRefs.count; i++) {
        SecCertificateRef certificateRef = (__bridge SecCertificateRef)certificateRefs[i];
        NSString *pemCertificate = [self convertCertificateRefToPemCertificate:certificateRef];
        [pemCertificates appendString:pemCertificate];
    }
    
    return pemCertificates;
}

+ (NSString *)convertCertificateRefToPemCertificate:(SecCertificateRef)certificateRef
{
    [QredoCryptoError throwArgExceptionIf:!certificateRef reason:@"Certificate ref argument is nil"];

    NSData *certificateData = (__bridge_transfer NSData *)SecCertificateCopyData(certificateRef);
    if (!certificateData) {
        QredoLogError(@"SecCertificateCopyData returned nil data.");
        return nil;
    }
    
    // Convert the raw DER data into Base64 and then wrap in PEM certificate markers
    // Wrap at 64 chars, and include just line feeds - matches common PEM formats
    NSString *certificateBase64 = [certificateData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength |
                                   NSDataBase64EncodingEndLineWithLineFeed];
    NSString *certificatePem = [NSString stringWithFormat:@"%@%@%@", PEM_CERTIFICATE_START, certificateBase64, PEM_CERTIFICATE_END];

    return certificatePem;
}

+ (NSString *)convertKeyIdentifierToPemKey:(NSString *)keyIdentifier
{
    [QredoCryptoError throwArgExceptionIf:!keyIdentifier reason:@"Key identifier argument is nil"];

    NSData *keyData = [QredoCrypto getKeyDataForIdentifier:keyIdentifier];

    // Convert the raw DER data into Base64 and then wrap in PEM key markers
    // Wrap at 64 chars, and include just line feeds - matches common PEM formats
    NSString *keyBase64 = [keyData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength |
                                   NSDataBase64EncodingEndLineWithLineFeed];
    NSString *keyPem = [NSString stringWithFormat:@"%@%@%@", PEM_KEY_START, keyBase64, PEM_KEY_END];
    
    return keyPem;
}

+ (NSData *)convertPemWrappedStringToDer:(NSString *)pemEncodedData startMarker:(NSString *)startMarker endMarker:(NSString *)endMarker
{
    [QredoCryptoError throwArgExceptionIf:!pemEncodedData reason:@"PEM encoded data argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!startMarker reason:@"Start marker argument is nil" ];
    [QredoCryptoError throwArgExceptionIf:!endMarker reason:@"End marker argument is nil"];

    // Steps:
    // Strip off the 'Start Marker' and 'End Marker' wrapping
    // Reverse base64 to get DER format
    
    NSRange startRange = [pemEncodedData rangeOfString:startMarker];
    if (startRange.location == NSNotFound) {
        QredoLogError(@"Could not find start marker (%@).", startMarker);
        return nil;
    }
    
    NSRange endRange = [pemEncodedData rangeOfString:endMarker];
    if (endRange.location == NSNotFound) {
        QredoLogError(@"Could not find end marker (%@).", endMarker);
        return nil;
    }
    
    if (endRange.location < startRange.location) {
        // End marker was found before start marker, invalid!
        QredoLogError(@"End Marker appeared before Start Marker. Not valid data.");
        return nil;
    }
    
    unsigned long payloadStart = startRange.location + startRange.length;
    unsigned long payloadLength = endRange.location - payloadStart;
    
    NSRange payloadRange = NSMakeRange(payloadStart, payloadLength);
    NSString *payload = [pemEncodedData substringWithRange:payloadRange];
    
    // Ignore unknown characters as may have trailing newline
    NSData *derEncodedPayload = [[NSData alloc]
                                 initWithBase64EncodedString:payload
                                 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    if (!derEncodedPayload) {
        QredoLogError(@"Could reverse base64 to get DER encoded data.");
    }
    
    return derEncodedPayload;
}

+ (NSData *)getPkcs1PublicKeyDataFromUnknownPublicKeyData:(NSData *)unknownPublicKeyData
{
    [QredoCryptoError throwArgExceptionIf:!unknownPublicKeyData reason:@"Public key data argument is nil"];

    // This method will return PKCS#1 encoded Public Key data when provided with either PKCS#1 or X.509 (SubjectPublicKeyInfo) Public Key data
    
    NSData *pkcs1PublicKeyData = nil;
    
    NSRange objectIdentifierRange = [unknownPublicKeyData rangeOfData:[QredoDerUtils getRsaIdentifier]
                                                              options:0
                                                                range:NSMakeRange(0, unknownPublicKeyData.length)];
    if (objectIdentifierRange.location == NSNotFound) {
        // OID is not present, so looks like PKCS#1 format - check by trying to parse it
        if ([self checkIfPublicKeyDataIsPkcs1:unknownPublicKeyData]) {
            pkcs1PublicKeyData = unknownPublicKeyData;
        }
        else {
            QredoLogError(@"Data does not have X.509 header, but also does not appear to be PKCS#1 data. Invalid data.");
        }
    }
    else {
        // OID is present, so appears to be X.509/SubjectPublicKeyInfo format
        pkcs1PublicKeyData = [self convertX509PublicKeyToPkcs1PublicKey:unknownPublicKeyData];
    }
    
    return pkcs1PublicKeyData;
}

+ (BOOL)checkIfPublicKeyDataIsPkcs1:(NSData *)pkcs1PublicKeyData
{
    BOOL dataIsPkcs1 = YES;
    
    if (!pkcs1PublicKeyData)
    {
        // Nil data is not PKCS1 data
        dataIsPkcs1 = NO;
    }
    else {
        // Use QredoRsaPublicKey class to valid it's PKCS#1
        QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:pkcs1PublicKeyData];
        if (!publicKey) {
            QredoLogError(@"Could not create QredoRsaPublicKey object with PKCS#1 Public Key Data: %@", pkcs1PublicKeyData);
            dataIsPkcs1 = NO;
        }
    }
    
    return dataIsPkcs1;
}

+ (NSData *)convertX509PublicKeyToPkcs1PublicKey:(NSData *)x509PublicKeyData
{
    NSData *pkcs1PublicKeyData = nil;

    [QredoCryptoError throwArgExceptionIf:!x509PublicKeyData reason:@"X509 Public Key data argument is nil"];

    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithX509KeyData:x509PublicKeyData];
    if (!publicKey) {
        QredoLogError(@"Could not create QredoRsaPublicKey object with X.509 Public Key Data: %@", x509PublicKeyData);
    }
    else {
        pkcs1PublicKeyData = [publicKey convertToPkcs1Format];
        if (!pkcs1PublicKeyData) {
            QredoLogError(@"Could not create convert RSA key object to PKCS#1 format");
        }
    }
    
    return pkcs1PublicKeyData;
}

+ (NSData *)convertPemPublicKeyToDer:(NSString *)pemEncodedPublicKey
{
    [QredoCryptoError throwArgExceptionIf:!pemEncodedPublicKey reason:@"PEM Public Key argument is nil"];

    NSData *derEncodedPayload = [self convertPemWrappedStringToDer:pemEncodedPublicKey
                                                       startMarker:PEM_KEY_START
                                                         endMarker:PEM_KEY_END];
    if (!derEncodedPayload) {
        QredoLogError(@"Could convert PEM key to DER.");
    }
    
    return derEncodedPayload;
}

+ (NSData *)convertPemCertificateToDer:(NSString *)pemEncodedCertificate
{
    [QredoCryptoError throwArgExceptionIf:!pemEncodedCertificate reason:@"Certificate argument is nil"];

    NSData *derEncodedPayload = [self convertPemWrappedStringToDer:pemEncodedCertificate
                                                       startMarker:PEM_CERTIFICATE_START
                                                         endMarker:PEM_CERTIFICATE_END];
    if (!derEncodedPayload) {
        QredoLogError(@"Could convert PEM certificate to DER.");
    }
    
    return derEncodedPayload;

}

+ (NSString *)getFirstPemCertificateFromString:(NSString *)string
{
    [QredoCryptoError throwArgExceptionIf:!string reason:@"String argument is nil"];

    NSRange searchRange = NSMakeRange(0, string.length);
    NSString *certificate = nil;
    
    NSRange certificateRange = [self getRangeOfPemCertificateInString:string searchRange:searchRange];
    
    if (certificateRange.location != NSNotFound) {
        certificate = [string substringWithRange:certificateRange];
    }
    
    return certificate;
}

+ (NSRange)getRangeOfPemCertificateInString:(NSString *)string searchRange:(NSRange)searchRange
{
    [QredoCryptoError throwArgExceptionIf:!string reason:@"String argument is nil"];
    [QredoCryptoError throwArgExceptionIf:searchRange.location >= string.length
                                   reason:@"Search range exceeds length of string being searched"];

    BOOL searchSuccessful = YES;
    
    NSRange startRange = [string rangeOfString:PEM_CERTIFICATE_START options:0 range:searchRange];
    if (startRange.location == NSNotFound) {
        QredoLogError(@"Could not find PEM start marker.");
        searchSuccessful = NO;
    }

    NSRange endRange;
    if (searchSuccessful) {
        endRange = [string rangeOfString:PEM_CERTIFICATE_END options:0 range:searchRange];
        if (endRange.location == NSNotFound) {
            QredoLogError(@"Could not find PEM end marker.");
            searchSuccessful = NO;
        }
    }
    
    if (searchSuccessful) {
        // Ensure start was before end
        if (startRange.location > endRange.location) {
            QredoLogError(@"PEM end marker was found before start marker.");
            searchSuccessful = NO;
        }
    }
    
    if (searchSuccessful) {
        // Need to include the header/footer in the certificate as well
        NSRange certificateRange = NSMakeRange(startRange.location,
                                               endRange.location - startRange.location + endRange.length);
        return certificateRange;
    }
    else {
        QredoLogError(@"Failed to get PEM certificate from string: %@", string);
        
        return NSMakeRange(NSNotFound, 0);
    }
}

// Splits a string containing multiple PEM encoded certificates into array of PEM encoded certificates
+ (NSArray *)splitPemCertificateChain:(NSString *)pemCertificateChain
{
    [QredoCryptoError throwArgExceptionIf:!pemCertificateChain reason:@"Certificate chain argument is nil"];

    // Break the certificate chain into individual certificates
    
    NSMutableArray *certificates = [[NSMutableArray alloc] init];
    
    // Start by searching the entire string, then narrow it as certificates are found.
    NSRange searchRange = NSMakeRange(0, pemCertificateChain.length);
    
    BOOL chainSplitSuccessful = YES;
    
    while (searchRange.length > 0) {

        NSRange certificateRange = [self getRangeOfPemCertificateInString:pemCertificateChain searchRange:searchRange];
        
        if (certificateRange.location == NSNotFound) {
            QredoLogError(@"Failed to find any PEM certificates.");
            chainSplitSuccessful = NO;
            break;
        }
        
        NSString *certificate = [pemCertificateChain substringWithRange:certificateRange];
        
        [certificates addObject:certificate];
        
        unsigned long certificateEndPoint = certificateRange.location + certificateRange.length;
        searchRange = NSMakeRange(certificateEndPoint, pemCertificateChain.length - certificateEndPoint);
    }
    
    if (!chainSplitSuccessful) {
        // If the chain could not be split correctly, return nil chain. Do not want to mask certificate errors.
        QredoLogError(@"Chain split was not successful, returning nil certificate array.");
        certificates = nil;
    }
    
    return certificates;
}

+ (NSArray*)getCertificateRefsFromPemCertificates:(NSString *)pemCertificates
{
    [QredoCryptoError throwArgExceptionIf:!pemCertificates reason:@"Certificates argument is nil"];

    /*
     Steps:
     1.) Split PEM chain into array of PEM certs
     2.) Create Cert for each PEM cert (loop through array, converting PEM to DER and creating cert from DER, add to CFArrayRef)
     */
    
    BOOL certificateValid = YES;
    NSArray *pemCertificateStrings = [self splitPemCertificateChain:pemCertificates];
    
    if (!pemCertificateStrings) {
        QredoLogError(@"PEM cert split returned nil array.");
        certificateValid = NO;
    }
    
    if (certificateValid) {
        if (pemCertificateStrings.count <= 0) {
            QredoLogError(@"PEM cert split returned 0 certificates in array.");
            certificateValid = NO;
        }
    }
    
    NSArray *certificateRefs = nil;
    
    if (certificateValid) {
        certificateRefs = [self getCertificateRefsFromPemCertificatesArray:pemCertificateStrings];
    }
    
    return certificateRefs;
}

+ (NSArray*)getCertificateRefsFromPemCertificatesArray:(NSArray *)pemCertificatesArray
{
    [QredoCryptoError throwArgExceptionIf:!pemCertificatesArray reason:@"Certificates array argument is nil"];

    /*
     Create Cert for each PEM cert in array (loop through array, converting PEM to DER and creating cert from DER, add to CFArrayRef)
     */
    
    BOOL certificateValid = YES;
    
    NSMutableArray *certificateRefs = [[NSMutableArray alloc] init];
    
    for (NSString *pemCertificate in pemCertificatesArray) {
        
        SecCertificateRef certificateRef = [self createCertificateWithPemCertificate:pemCertificate];
        
        if (!certificateRef) {
            QredoLogError(@"Certificate creation returned nil.");
            certificateValid = NO;
            break;
        }
        
        [certificateRefs addObject:(__bridge id)certificateRef];
    }
    
    if (certificateRefs.count <= 0) {
        QredoLogError(@"No certificates created.");
        certificateValid = NO;
    }
    
    if (!certificateValid) {
        return nil;
    }
    
    return certificateRefs;
}

/** Validates the X.509 certificate chain (as NSArray of SecCertificateRefs) using the provided root certificates.  If the chain validates successfully, then this method returns a valid SecKeyRef for the validated certificate (i.e. the first certificate provided in the chain).  If the validation failed, then nil is returned.
 NOTE: The certificate being validated is the first present in the array.  The rest of the chain is expected to be the intermediate certificates required to validate the chain.  The root certificates are used as anchors to validate the full chain.
 
 @param certificateChainRefs NSArray containing SecCertificateRefs of X.509 certificate chain
 @param rootCertificateRefs NSArray containing the root/anchor certificates refs needed to validate the PEM certificate chain.  Use [QredoCertificateUtils getCertificateRefsFromPemCertificates:] to get the refs from PEM encoded X.509 certificates string.
 */
+ (SecKeyRef)validateCertificateChain:(NSArray*)certificateChainRefs rootCertificateRefs:(NSArray*)rootCertificateRefs
{
    [QredoCryptoError throwArgExceptionIf:!certificateChainRefs reason:@"Certificate chain refs argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!rootCertificateRefs reason:@"Root certificates argument is nil"];

    // TODO: DH - how to only permit RSA certificates in range 2048-4096 bits?
    
    BOOL certificateValid = YES;
    SecKeyRef validatedCertificatePublicKeyRef = nil;
    
    SecTrustRef trustRef = nil;
    
    SecPolicyRef policyRef = SecPolicyCreateBasicX509();
    
    OSStatus status = SecTrustCreateWithCertificates((__bridge CFArrayRef)certificateChainRefs, policyRef, &trustRef);
    
    if (status != noErr) {
        certificateValid = NO;
    }
    
    if (certificateValid) {
        certificateValid = [self evaluateTrustRef:trustRef rootCertificateRefs:rootCertificateRefs];
        
        if (certificateValid) {
            validatedCertificatePublicKeyRef = SecTrustCopyPublicKey(trustRef);
        }
    }
    
    if (policyRef) {
        CFRelease(policyRef);
    }
    
    if (trustRef) {
        CFRelease(trustRef);
    }
    
    return validatedCertificatePublicKeyRef;
}

+ (BOOL)evaluateTrustRef:(SecTrustRef)trustRef rootCertificateRefs:(NSArray*)rootCertificateRefs
{
    [QredoCryptoError throwArgExceptionIf:!trustRef reason:@"Trust ref argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!rootCertificateRefs reason:@"Root certificates argument is nil"];

    // TODO: DH - Deal with revocation checks. Seems iOS may not do this: http://stackoverflow.com/questions/5625642/crl-and-ocsp-behavior-of-ios-security-framework
    
    BOOL trustEvaluatedSuccesfully = YES;
    
    /*
     Need to specify which root/anchor certificates to use (by default, it's none):
         "Although SecTrustEvaluate searches the user’s keychain (or the application keychain in iOS)
         for intermediate certificates, it does not search those keychains for anchor (root) certificates.
         To add an anchor certificate, you must call SecTrustSetAnchorCertificates."
     
     You can also use SecTrustSetAnchorCertificatesOnly() enable trusting of built-in anchor certificates
     (boolean argument sets whether ONLY build-in anchor certificates).
     */
    CFArrayRef anchorCertificates = (__bridge CFArrayRef)rootCertificateRefs;
    
    OSStatus status = SecTrustSetAnchorCertificates(trustRef, anchorCertificates);
    
    if (status != noErr) {
        
        QredoLogError(@"Setting anchor certificates failed: %@", [QredoLogger stringFromOSStatus:status]);
        trustEvaluatedSuccesfully = NO;
    }
    
    if (trustEvaluatedSuccesfully) {
        SecTrustResultType trustResult;
        
        OSStatus status = SecTrustEvaluate(trustRef, &trustResult);
        
        if (status != noErr) {
            
            QredoLogError(@"Trust evaluation returned error: %@", [QredoLogger stringFromOSStatus:status]);
            trustEvaluatedSuccesfully = NO;
        }
        else  {
            // kSecTrustResultUnspecified means that validation was successful using an implicitly trusted anchor (most common result)
            // kSecTrustResultProceed means user explicitly trusted a certificate in the chain
            if ((trustResult == kSecTrustResultUnspecified) ||
                (trustResult == kSecTrustResultProceed)) {
            }
            else {
                trustEvaluatedSuccesfully = NO;
            }
        }
    }
    
    return trustEvaluatedSuccesfully;
}

/** Validates the PEM encoded X.509 certificate chain using the provided root certificates.  If the chain validates successfully, then this method returns a valid SecKeyRef for the validated certificate (i.e. the first certificate provided in the chain).  If the validation failed, then nil is returned.
    NOTE: The certificate being validated is the first present in the PEM certificate chain.  The rest of the chain is expected to be the intermediate certificates required to validate the chain.  The root certificates are used as anchors to validate the full chain.
 
 @param pemCertificateChain String containing PEM encoded X.509 certificate chain (i.e. with -----BEGIN CERTIFICATE-----/-----END CERTIFICATE----- markers)
 @param rootCertificateRefs NSArray containing the root/anchor certificates refs needed to validate the PEM certificate chain.  Use [QredoCertificateUtils getCertificateRefsFromPemCertificates:] to get the refs from PEM encoded X.509 certificates string.
 */
+ (SecKeyRef)validatePemCertificateChain:(NSString*)pemCertificateChain rootCertificateRefs:(NSArray*)rootCertificateRefs
{
    [QredoCryptoError throwArgExceptionIf:!pemCertificateChain reason:@"Certificate chain argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!rootCertificateRefs reason:@"Root certificates argument is nil"];
    
    // TODO: DH - hwo to only permit RSA certificates in range 2048-4096 bits?

    /*
     Steps:
     1.) Split PEM chain into array of PEM certs
     2.) Create Cert for each PEM cert (loop through array, converting PEM to DER and creating cert from DER, add to CFArrayRef)
     3.) Create policy, trust and evaluate
     */
    
    BOOL certificateValid = YES;
    SecKeyRef validatedCertificatePublicKeyRef = nil;
    
    NSArray *certificateRefs = [self getCertificateRefsFromPemCertificates:pemCertificateChain];
    
    if (!certificateRefs) {
        QredoLogError(@"Creation of certificates failed.");
        certificateValid = NO;
    }
    else {
        validatedCertificatePublicKeyRef = [self validateCertificateChain:certificateRefs
                                                      rootCertificateRefs:rootCertificateRefs];
    }
    
    return validatedCertificatePublicKeyRef;
}

+ (NSDictionary *)createAndValidateIdentityFromPkcs12Data:(NSData *)pkcs12Data password:(NSString *)password rootCertificateRefs:(NSArray*)rootCertificateRefs
{
    [QredoCryptoError throwArgExceptionIf:!pkcs12Data reason:@"PKCS#12 data argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!password reason:@"Password argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!rootCertificateRefs reason:@"Root certificates argument is nil"];

    CFDictionaryRef identityDictionary = nil;
    NSDictionary *returningIdentityDictionary = nil;
    
    NSDictionary *options = @{(__bridge id)kSecImportExportPassphrase: password};
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)pkcs12Data, (__bridge CFDictionaryRef)options, &items);
    
    if (status == errSecSuccess) {
        CFIndex identityCount = CFArrayGetCount(items);
        
        // We only support importing 1 identity
        if (identityCount == 1) {
            identityDictionary = CFArrayGetValueAtIndex(items, 0);;
        }
        else {
            QredoLogError(@"Invalid number of imported identities (%ld).  Must have only 1 identity in PKCS#12 blob.", identityCount);
        }
    }
    else {
        QredoLogError(@"Importing PKCS#12 data failed: %@", [QredoLogger stringFromOSStatus:status]);
    }
    
    if (identityDictionary) {
        // Successfully imported 1 identity, now must validate that identity
        SecTrustRef trustRef = (SecTrustRef)CFDictionaryGetValue(identityDictionary, kSecImportItemTrust);
        
        BOOL identityIsTrusted = [self evaluateTrustRef:trustRef rootCertificateRefs:rootCertificateRefs];
        
        if (identityIsTrusted) {
            // Create a copy of the dictionary to be returned
            returningIdentityDictionary = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)identityDictionary];
        } else {
            returningIdentityDictionary = @{};
        }
    }
    
    if (items) {
        CFRelease(items);
    }
    
    return returningIdentityDictionary;
}
@end
