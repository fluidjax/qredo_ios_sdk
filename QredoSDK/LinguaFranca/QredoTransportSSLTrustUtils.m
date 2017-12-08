/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoTransportSSLTrustUtils.h"
#pragma GCC diagnostic ignored "-Wunused-function"


static NSString *const kAnchorAlreadyAdded = @"AnchorAlreadyAdded";

static SecTrustRef setAnchorForTrust(SecTrustRef trust,SecCertificateRef trustedCert);
static BOOL checkTrust(SecTrustRef trust);

static BOOL checkTrustOfStreamUsingCertificate(NSStream *aStream,SecCertificateRef trustedCert);



static SecTrustRef setAnchorForTrust(SecTrustRef trust,SecCertificateRef trustedCert) {
    OSStatus osStatus = 0;
    
    CFMutableArrayRef newAnchorArray = CFArrayCreateMutable(kCFAllocatorDefault,0,&kCFTypeArrayCallBacks);
    
    CFArrayAppendValue(newAnchorArray,trustedCert);
    
    osStatus = SecTrustSetAnchorCertificates(trust,newAnchorArray);
    
    CFRelease(newAnchorArray);
    
    if (osStatus){
        return NULL;
    }
    
    osStatus = SecTrustSetAnchorCertificatesOnly(trust,true);
    
    if (osStatus){
        return NULL;
    }
    
    return trust;
}


static BOOL checkTrust(SecTrustRef trust) {
    if (!trust){
        return NO;
    }
    
    SecTrustResultType res = kSecTrustResultInvalid;
    OSStatus osStatus = SecTrustEvaluate(trust,&res);
    
    if (osStatus){
        /* The trust evaluation failed for some reason.
         This probably means your certificate was broken
         in some way or your code is otherwise wrong. */
        
        return NO;
    }
    
    if (res != kSecTrustResultProceed && res != kSecTrustResultUnspecified){
        /* The host is not trusted. */
        
        return NO;
    }
    
    return YES;
}
