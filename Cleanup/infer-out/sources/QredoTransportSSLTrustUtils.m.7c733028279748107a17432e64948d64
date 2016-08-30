/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "QredoTransportSSLTrustUtils.h"


static NSString *const kAnchorAlreadyAdded = @"AnchorAlreadyAdded";

static SecTrustRef setAnchorForTrust(SecTrustRef trust, SecCertificateRef trustedCert);
static BOOL checkTrust(SecTrustRef trust);

static BOOL checkTrustOfStreamUsingCertificate(NSStream *aStream, SecCertificateRef trustedCert);



static SecTrustRef setAnchorForTrust(SecTrustRef trust, SecCertificateRef trustedCert)
{
    OSStatus osStatus = 0;
    
    CFMutableArrayRef newAnchorArray = CFArrayCreateMutable (kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    CFArrayAppendValue(newAnchorArray, trustedCert);
    
    osStatus = SecTrustSetAnchorCertificates(trust, newAnchorArray);
    
    CFRelease(newAnchorArray);
    
    
    if (osStatus) {
        return NULL;
    }
    
    osStatus = SecTrustSetAnchorCertificatesOnly(trust, true);
    if (osStatus) {
        return NULL;
    }
    
    return trust;
}


static BOOL checkTrust(SecTrustRef trust)
{
    if (!trust) {
        return NO;
    }
    
    SecTrustResultType res = kSecTrustResultInvalid;
    OSStatus osStatus = SecTrustEvaluate(trust, &res);
    if (osStatus) {
        /* The trust evaluation failed for some reason.
         This probably means your certificate was broken
         in some way or your code is otherwise wrong. */
        
        return NO;
    }
    
    if (res != kSecTrustResultProceed && res != kSecTrustResultUnspecified) {
        /* The host is not trusted. */
        
        return NO;
    }
    
    return YES;

}

static BOOL checkTrustOfStreamUsingCertificate(NSStream *aStream, SecCertificateRef trustedCert)
{
    SecTrustRef trust = (__bridge SecTrustRef)[aStream propertyForKey: (__bridge NSString *)kCFStreamPropertySSLPeerTrust];
    
    /* Because you don't want the array of certificates to keep
     growing, you should add the anchor to the trust list only
     upon the initial receipt of data (rather than every time).
     */
    NSNumber *alreadyAdded = [aStream propertyForKey: kAnchorAlreadyAdded];
    if (!alreadyAdded || ![alreadyAdded boolValue]) {
        trust = setAnchorForTrust(trust, trustedCert);
        [aStream setProperty: [NSNumber numberWithBool: YES] forKey: kAnchorAlreadyAdded];
    }
    
    return checkTrust(trust);
}

MQTTSessionTrustValidator trustValidatorWithTrustedCert(SecCertificateRef trustedCert)
{
    return ^BOOL(NSStream *stream) {
        return checkTrustOfStreamUsingCertificate(stream, trustedCert);
    };
}

NSURLCredential *credentialForTrustUsingPinnedCertificate(SecTrustRef trust, SecCertificateRef trustedCert)
{
    trust = setAnchorForTrust(trust, trustedCert);
    if (checkTrust(trust)) {
        return [NSURLCredential credentialForTrust:trust];
    }
    return nil;
}


