/* HEADER GOES HERE */
#import "QredoOpenSSLCertificateUtils.h"
#import "QredoCertificateUtils.h"
#import "QredoLoggerPrivate.h"
#import "QredoCrypto.h"
#import "QredoCryptoError.h"
#import <openssl/err.h>
#import <openssl/pem.h>



@implementation QredoOpenSSLCertificateUtils

static const NSUInteger kMinX509RsaKeyLengthBits = 2048;
static const NSUInteger kMaxX509RsaKeyLengthBits = 4096;

+(void)initialize {
    //Makes sure this isn't executed more than once
    if (self == [QredoOpenSSLCertificateUtils class]){
        //Do the necessary initialisation of OpenSSL
        
        //TODO: DH - may be possible to limit the algorithms supported? Is something that we want to do?
        OpenSSL_add_all_algorithms();
        ERR_load_BIO_strings();
        ERR_load_crypto_strings();
    }
}


#pragma mark - External methods

//TODO: DH - Any need to check CRL for self-signed? If private key compromised, then why trust it to sign the CRL?
+(BOOL)validateSelfSignedCertificate:(NSString *)pemCertificate error:(NSError **)error {
    //Create empty intermediate array
    NSArray *intermediateCertificates = [[NSArray alloc] init];
    
    //Use the certificate being validated as the root
    NSArray *rootCertificates = [NSArray arrayWithObject:pemCertificate];
    
    return [self validateCertificate:pemCertificate
                skipRevocationChecks:YES
                chainPemCertificates:intermediateCertificates
                 rootPemCertificates:rootCertificates
                             pemCrls:nil
                               error:error];
}


+(BOOL)validateCertificate:(NSString *)pemCertificate
      skipRevocationChecks:(BOOL)skipRevocationChecks
      chainPemCertificates:(NSArray *)chainPemCertificates
       rootPemCertificates:(NSArray *)rootPemCertificates
                   pemCrls:(NSArray *)pemCrls
                     error:(NSError **)error {
    //Other arguments are validated by internal method
    
    if (skipRevocationChecks){
        QredoLogError(@"Caller opted to skip revocation checks. Not recommended.");
    }
    
    return [self validateCertificate:pemCertificate
             performRevocationChecks:!skipRevocationChecks
                chainPemCertificates:chainPemCertificates
                 rootPemCertificates:rootPemCertificates
                             pemCrls:pemCrls
                               error:error];
}


#pragma mark - Internal methods

+(BOOL) validateCertificate:(NSString *)pemCertificate
    performRevocationChecks:(BOOL)performRevocationChecks
       chainPemCertificates:(NSArray *)chainPemCertificates
        rootPemCertificates:(NSArray *)rootPemCertificates
                    pemCrls:(NSArray *)pemCrls
                      error:(NSError **)error {
    [QredoCryptoError throwArgExceptionIf:!pemCertificate reason:@"Certificate argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!chainPemCertificates reason:@"Chain certificates argument is nil"];
    [QredoCryptoError throwArgExceptionIf:!rootPemCertificates reason:@"Root certificates argument is nil"];
    [QredoCryptoError throwArgExceptionIf:(performRevocationChecks && !pemCrls) reason:@"Revocation checks requested yet CRLs argument is nil"];
    
    BOOL certificateValid = YES;
    
    //From this point do not return early, or could have memory leaks on OpenSSL objects
    
    //OpenSSL objects which require freeing later
    X509 *certificateToValidate = NULL;
    EVP_PKEY *publicKey = NULL;
    STACK_OF(X509) * intermediateCertStack = NULL;
    STACK_OF(X509) * rootCertStack = NULL;
    STACK_OF(X509_CRL) * crlStack = NULL;
    X509_STORE *store = NULL;
    X509_STORE_CTX *verifyContext = NULL;
    
    if (certificateValid){
        store = X509_STORE_new();
        
        if (!store){
            certificateValid = NO;
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslMemoryAllocationFailure
                                description:@"Could not create X509 store"];
        }
    }
    
    if (certificateValid){
        certificateToValidate = [self x509FromPemCertificate:pemCertificate error:error];
        
        if (!certificateToValidate){
            certificateValid = NO;
            QredoLogError(@"Could not create certificate to validate");
        }
    }
    
    //Validate that public key within the certificate meets our restrictions (2048/4096 RSA key)
    if (certificateValid){
        publicKey = [self getValidatedPublicKeyFromX509Certificate:certificateToValidate error:error];
        
        if (!publicKey){
            certificateValid = NO;
            QredoLogError(@"Could not get valid public key from certificate.");
        }
    }
    
    //Now validate the certificate chain
    
    if (certificateValid){
        intermediateCertStack = [self createStackFromPemCertificates:chainPemCertificates error:error];
        
        if (!intermediateCertStack){
            //Not populating NSError as failed method does that
            certificateValid = NO;
            QredoLogError(@"Failed to create intermediate certificate stack");
        }
    }
    
    if (certificateValid){
        //TODO: DH - May be possible to create the root certificate stack and keep for life of application?  Or just pass in on each call, allowing different root certs to be used for different rendezvous etc
        rootCertStack = [self createStackFromPemCertificates:rootPemCertificates error:error];
        
        if (!rootCertStack){
            //Not populating NSError as failed method does that
            certificateValid = NO;
            QredoLogError(@"Failed to create root certificate stack");
        }
    }
    
    if (certificateValid){
        if (performRevocationChecks){
            crlStack = [self createStackFromPemOrDerCrls:pemCrls error:error];
            
            if (!crlStack){
                //Not populating NSError as failed method does that
                certificateValid = NO;
                QredoLogError(@"Failed to create CRL stack");
            }
        }
    }
    
    if (certificateValid){
        verifyContext = X509_STORE_CTX_new();
        
        if (!verifyContext){
            certificateValid = NO;
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslMemoryAllocationFailure
                                description:@"Failed to create verify context"];
        }
    }
    
    if (certificateValid){
        //Configure the context with certificate, chain and root. We won't directly use store as using X509_STORE_CTX_set_chain()
        X509_STORE_CTX_init(verifyContext,store,certificateToValidate,NULL);
        
        //Configure a callback for certificate verification, to allow greater logging on verify failures
        X509_STORE_CTX_set_verify_cb(verifyContext,verify_callback);
        
        //Enable CRL checks if we have a valid CRL stack
        if (crlStack){
            //Check the full chain
            X509_STORE_CTX_set_flags(verifyContext,X509_V_FLAG_CRL_CHECK | X509_V_FLAG_CRL_CHECK_ALL);
            
            //Specify the CRLs to use
            X509_STORE_CTX_set0_crls(verifyContext,crlStack);
        }
        
        //Specify any intermediate certificates (the chain)
        X509_STORE_CTX_set_chain(verifyContext,intermediateCertStack);
        
        //Specify which certificates are the trusted root certificates
        X509_STORE_CTX_trusted_stack(verifyContext,rootCertStack);
        
        //Returns 1 for successful verification, anything else is a failure.
        //0 is explicit verification failure, and negative indicates context problem - incorrectly configured?
        int verifyResult = X509_verify_cert(verifyContext);
        
        if (verifyResult == 1){
            //TODO delete me
        } else {
            certificateValid = NO;
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeCertificateIsNotValid
                                description:@"Certificate is not valid"];
        }
    }
    
#ifdef QREDO_LOG_DEBUG
    
    if (certificateToValidate){
        char *subjectString = X509_NAME_oneline(X509_get_subject_name(certificateToValidate),NULL,0);
        OPENSSL_free(subjectString);
    }
    
#endif
    
    //Clean up the OpenSSL objects
    EVP_PKEY_free(publicKey);
    X509_STORE_free(store);
    
    if (verifyContext){
        //This one doesn't like freeing NULL
        X509_STORE_CTX_free(verifyContext);
    }
    
    X509_free(certificateToValidate);
    sk_X509_pop_free(intermediateCertStack,X509_free);
    sk_X509_pop_free(rootCertStack,X509_free);
    sk_X509_CRL_pop_free(crlStack,X509_CRL_free);
    
    return certificateValid;
}


int verify_callback(int ok,X509_STORE_CTX *ctx) {
#ifdef QREDO_LOG_INFO
    X509 *certificate;
    int err,depth;
    
    certificate = X509_STORE_CTX_get_current_cert(ctx);
    err =       X509_STORE_CTX_get_error(ctx);
    //depth =     X509_STORE_CTX_get_error_depth(ctx);
    
    NSString *certificateSubject = @"<No certificate>";
    NSString *errorDetails = @""; //Empty so nothing displayed if no error
    
    if (certificate){
        char *subjectString = X509_NAME_oneline(X509_get_subject_name(certificate),NULL,0);
        //certificateSubject = [NSString stringWithCString:subjectString encoding:NSASCIIStringEncoding];
        OPENSSL_free(subjectString);
    }
    
    if (!ok){
        errorDetails = [NSString stringWithFormat:@"Error num = %d (%s).",err,X509_verify_cert_error_string(err)];
        NSLog(@"Error : %@",errorDetails);
    }
    
#endif //ifdef QREDO_LOG_INFO
    
    //Do not alter the verification result
    return ok;
}


+(X509 *)x509FromPemCertificate:(NSString *)pemCertificate error:(NSError **)error {
    //TODO: DH - Validate inputs
    
    X509 *certificate = NULL;
    
    NSData *pemCertificateData = [pemCertificate dataUsingEncoding:NSUTF8StringEncoding];
    
    //BIO needs to be freed after use, even on error
    BIO *certificateBio = BIO_new_mem_buf((void *)pemCertificateData.bytes,(int)pemCertificateData.length);
    
    if (!certificateBio){
        [QredoCryptoError populateError:error
                              errorCode:QredoCryptoErrorCodeOpenSslMemoryAllocationFailure
                            description:@"Could not create BIO from certificate"];
    } else {
        certificate = PEM_read_bio_X509(certificateBio,NULL,0,NULL);
        
        if (!certificate){
            //NOTE: This may happen if the PEM doesn't have newlines in the base64 (adding them fixed it)
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslCertificateReadFailure
                                description:@"Could not load certificate"];
        }
    }
    
    //Clean up the BIO
    BIO_free_all(certificateBio);
    
    return certificate;
}


+(EVP_PKEY *)getValidatedPublicKeyFromX509Certificate:(X509 *)certificate error:(NSError **)error {
    BOOL errorOccurred = NO;
    BOOL publicKeyValid = YES;
    
    //Validate that public key within the certificate meets our restrictions (2048/4096 RSA key)
    
    //Get the public key so we can validate it
    EVP_PKEY *publicKey = X509_get_pubkey(certificate);
    
    if (!publicKey){
        errorOccurred = YES;
        [QredoCryptoError populateError:error
                              errorCode:QredoCryptoErrorCodeOpenSslFailedToGetPublicKey
                            description:@"Could not get public key from certificate"];
    } else {
        //Validate public key type and length
        int keySize = 0;
        switch (publicKey->type){
            case EVP_PKEY_RSA:
                keySize = BN_num_bits(publicKey->pkey.rsa->n);
                
                if (keySize < kMinX509RsaKeyLengthBits){
                    QredoLogError(@"Certificate rejected. Public key length too short.");
                    publicKeyValid = NO;
                } else if (keySize > kMaxX509RsaKeyLengthBits){
                    QredoLogError(@"Certificate rejected. Public key length too long.");
                    publicKeyValid = NO;
                }
                
                break;
                
            default:
                QredoLogError(@"Certificate contains an unsupported public key type (%d).",publicKey->type);
                publicKeyValid = NO;
                break;
        }
    }
    
    if (publicKeyValid && !errorOccurred){
        return publicKey;
    } else {
        [QredoCryptoError populateError:error
                              errorCode:QredoCryptoErrorCodePublicKeyInvalid
                            description:@"Public key in certificate is invalid"];
        
        return NULL;
    }
}


+(STACK_OF(X509)*)createStackFromPemCertificates:(NSArray *)pemCertificates error:(NSError **)error {
    [QredoCryptoError throwArgExceptionIf:!pemCertificates reason:@"Certificates argument is nil"];
    
    //Create empty STACK_OF(X509)
    STACK_OF(X509) * certificatesStack = sk_X509_new_null();
    
    if (!certificatesStack){
        QredoLogError(@"Failed to create new X509 stack");
        return NULL;
    }
    
    BOOL completedSuccessfully = YES;
    int certificateIndex = 0;
    
    //Create an X509 object for each certificate and add to the stack
    for (NSString *pemCertificate in pemCertificates){
        //TODO: DH - validate that the data is of the correct type (e.g. NSString)
        
        X509 *certificate = [self x509FromPemCertificate:pemCertificate error:error];
        
        if (!certificate){
            QredoLogError(@"Could not create certificate at index %d",certificateIndex);
            break;
        }
        
        //Push cert onto stack
        if (!sk_X509_push(certificatesStack,certificate)){
            completedSuccessfully = NO;
            NSString *message = [NSString stringWithFormat:@"Could not push certificate (index = %d) onto stack",certificateIndex];
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslStackPushFailure
                                description:message];
            break;
        }
        
        certificateIndex++;
    }
    
    //Perform any clean up needed
    if (!completedSuccessfully){
        //Only clean up the stack if we're had an error and are returning NULL
        if (certificatesStack){
            sk_X509_pop_free(certificatesStack,X509_free);
        }
        
        return NULL;
    }
    
    return certificatesStack;
}


//TODO: DH - any way of commoning up some of these methods, as apart from the type (X509_CRL/X509), code is simiar
+(STACK_OF(X509_CRL)*)createStackFromPemOrDerCrls:(NSArray *)derCrls error:(NSError **)error {
    [QredoCryptoError throwArgExceptionIf:!derCrls reason:@"CRLs argument is nil"];
    
    //Create empty STACK_OF(X509_CRL)
    STACK_OF(X509_CRL) * crlsStack = sk_X509_CRL_new_null();
    
    if (!crlsStack){
        QredoLogError(@"Failed to create new X509 CRL stack");
        return NULL;
    }
    
    BOOL completedSuccessfully = YES;
    int crlIndex = 0;
    
    //Create an X509 CRL object for each CRL and add to the stack
    for (NSString *derCrl in derCrls){
        //TODO: DH - validate that the data is of the correct type (e.g. NSString)
        NSData *pemCrlData = [derCrl dataUsingEncoding:NSUTF8StringEncoding];
        
        //BIO needs to be freed after use, even on error
        BIO *crlBio = BIO_new_mem_buf((void *)pemCrlData.bytes,(int)pemCrlData.length);
        
        if (!crlBio){
            completedSuccessfully = NO;
            NSString *message = [NSString stringWithFormat:@"Could not create BIO from CRL (index = %d)",crlIndex];
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslMemoryAllocationFailure
                                description:message];
            break;
        }
        
        //Try PEM format first, if that fails, try DER
        X509_CRL *crl = PEM_read_bio_X509_CRL(crlBio,NULL,0,NULL);
        
        if (!crl){
            //Might be a DER encoded CRL rather than PEM
            crl = d2i_X509_CRL_bio(crlBio,NULL);
        }
        
        if (!crl){
            completedSuccessfully = NO;
            NSString *message = [NSString stringWithFormat:@"Could not load CRL (index = %d), tried both PEM and DER formats. Invalid CRL? ",crlIndex];
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslCertificateReadFailure
                                description:message];
            BIO_free_all(crlBio);
            break;
        }
        
        //Push cert onto stack
        if (!sk_X509_CRL_push(crlsStack,crl)){
            completedSuccessfully = NO;
            NSString *message = [NSString stringWithFormat:@"Could not push CRL (index = %d) onto stack",crlIndex];
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslStackPushFailure
                                description:message];
            BIO_free_all(crlBio);
            break;
        }
        
        //Clean up the BIO
        BIO_free_all(crlBio);
        
        crlIndex++;
    }
    
    //Perform any clean up needed
    if (!completedSuccessfully){
        //Only clean up the stack if we're had an error and are returning NULL
        if (crlsStack){
            sk_X509_CRL_pop_free(crlsStack,X509_CRL_free);
        }
        
        return NULL;
    }
    
    return crlsStack;
}


+(SecKeyRef)getPublicKeyRefFromPemCertificate:(NSString *)pemCertificate
                          publicKeyIdentifier:(NSString *)publicKeyIdentifier
                                        error:(NSError **)error {
    BOOL errorOccurred = NO;
    SecKeyRef publicKeyRef = nil;
    unsigned char *buffer = NULL;
    int length = 0;
    int keySize = 0;
    NSData *publicKeyPkcs1Data = nil;
    
    //Convert PEM certificate into OpenSSL's X509 object
    X509 *certificate = [self x509FromPemCertificate:pemCertificate error:error];
    
    if (!certificate){
        QredoLogError(@"Could not create X509 certificate.");
        return nil;
    }
    
    //Past this point we must not exit early, but ensure OpenSSL objects are freed correctly
    
    //Get OpenSSL's public key object (EVP_PKEY) from X509 object and validate meets our key requirements
    EVP_PKEY *publicKey = [self getValidatedPublicKeyFromX509Certificate:certificate error:error];
    
    if (!errorOccurred && !publicKey){
        //NSError should already be populated
        errorOccurred = YES;
        QredoLogError(@"Could not get valid public key (EVP_PKEY) from certificate.");
    }
    
    //Know it's RSA, with key size in acceptable range, so safe to get the key size
    if (!errorOccurred){
        BN_num_bits(publicKey->pkey.rsa->n);
        
        //Populate the buffer with X.509 DER encoded public key (will allocate memory if pointer provided is NULL)
        length = i2d_X509_PUBKEY(X509_get_X509_PUBKEY(certificate),(unsigned char **)&buffer);
        
        if (length <= 0 ||  buffer == NULL){
            errorOccurred = YES;
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodeOpenSslFailedToGetPublicKey
                                description:@"Could not get DER encoded public key from certificate"];
        }
    }
    
    if (!errorOccurred){
        //buffer now contains the ASN.1 DER-encoded subjectPublicKeyInfo ('X509' encoded, not PKCS#1 format required by Apple Keychain)
        NSData *publicKeyData = [NSData dataWithBytes:buffer length:length];
        
        //Convert from X.509 Encoded public key data to PKCS#1
        publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyData];
        
        if (!publicKeyPkcs1Data){
            errorOccurred = YES;
            [QredoCryptoError populateError:error
                                  errorCode:QredoCryptoErrorCodePublicKeyIncorrectFormat
                                description:@"Could not convert public key into PCSK#1 format"];
        }
    }
    
    if (!errorOccurred){
        //Import into Keychain and get SecKeyRef for use in other crypto operations
        publicKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyPkcs1Data
                                         keyLengthBits:keySize
                                         keyIdentifier:publicKeyIdentifier
                                             isPrivate:NO];
    }
    
    //Clean up the OpenSSL objects
    OPENSSL_free(buffer);
    EVP_PKEY_free(publicKey);
    X509_free(certificate);
    
    return publicKeyRef;
}


@end
