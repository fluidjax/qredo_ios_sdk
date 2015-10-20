/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import <Foundation/Foundation.h>

#import "MQTTSession.h"
#import "SRWebSocket.h"
#import <Security/Security.h>


MQTTSessionTrustValidator trustValidatorWithTrustedCert(SecCertificateRef trustedCert);

NSURLCredential *credentialForTrustUsingPinnedCertificate(SecTrustRef trust, SecCertificateRef trustedCert);

SRWebSocketTrustValidator webSocketTrustValidatorWithTrustedCert(SecCertificateRef trustedCert);


