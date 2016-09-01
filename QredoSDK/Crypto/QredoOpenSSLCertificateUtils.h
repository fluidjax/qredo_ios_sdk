/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoOpenSSLCertificateUtils : NSObject

/**
 * Validates a self-signed PEM encoded X.509 certificate. Does not perform revocation checks.
 *
 * @param pemCertificate        PEM encoded self-signed X.509 certificate to be validated.
 * @param error                 On input, a pointer to an error object. If an error occurs, this pointer is set to
 *                              an actual error object containing the error information. You may specify nil for
 *                              this parameter if you do not want the error information. This is only used for
 *                              execution errors, and does not provide information regarding validation failure.
 * @return                      YES/NO depending on whether the certificate was successfully validated.
 */
+ (BOOL)validateSelfSignedCertificate:(NSString *)pemCertificate error:(NSError **)error;

/**
 * Validates a PEM encoded X.509 certificate using the provided PEM encoded trusted root certificates, using any 
 * other necessary PEM encoded intermediate certificates provided.  By default will perform revocation checks using
 * the provided PEM encoded CRLs.  Bypassing revocation checks is insecure and NOT recommended - consequently use 
 * of this option will be logged as an error.
 *
 * @param pemCertificate        PEM encoded X.509 certificate to be validated.
 * @param skipRevocationChecks  If set to YES will skip revocation checks. THIS IS NOT RECOMMENDED FOR USE IN
 *                              PRODUCTION. Use of this will be logged as an error.
 * @param chainPemCertificates  Array of PEM encoded X.509 intermediate certificates containing at least those 
 *                              needed to validate the chain between subject certificate and root certificate.
 * @param rootPemCertificates   Array of PEM encoded X.509 trusted root certificates containing at least the root
 *                              needed to validate the chain of the subject certificate  to be validated.
 * @param pemCrls               PEM encoded CRL (Certificate Revocation List) for every certificate provided in 
 *                              pemCertificate, chainPemCertificiates and rootPemCertificates.  Failure to provide 
 *                              a valid CRL for every certificate provided will result in validation failure.
 * @param error                 On input, a pointer to an error object. If an error occurs, this pointer is set to
 *                              an actual error object containing the error information. You may specify nil for 
 *                              this parameter if you do not want the error information. This is only used for 
 *                              execution errors, and does not provide information regarding validation failure.
 * @return                      YES/NO depending on whether the certificate was successfully validated.
 */
+ (BOOL)validateCertificate:(NSString *)pemCertificate
       skipRevocationChecks:(BOOL)skipRevocationChecks
       chainPemCertificates:(NSArray *)chainPemCertificates
        rootPemCertificates:(NSArray *)rootPemCertificates
                    pemCrls:(NSArray *)pemCrls
                      error:(NSError **)error;

/**
 * Creates a SecKeyRef (by importing into iOS keychain) from the public key (subjectPublicKeyInfo) in the PEM
 * encoded X.509 certificate.
 *
 * @param pemCertificate        PEM encoded X.509 certificate to get public key SecKeyRef from.
 * @param publicKeyIdentifier   Name to identify the public key reference being returned. Will need to be deleted
 *                              from iOS Keychain once no longer required.
 * @param error                 On input, a pointer to an error object. If an error occurs, this pointer is set to
 *                              an actual error object containing the error information. You may specify nil for
 *                              this parameter if you do not want the error information. This is only used for
 *                              execution errors, and does not provide information regarding validation failure.
 * @return                      SecKeyRef for the public key found inside the PEM certificate */
+ (SecKeyRef)getPublicKeyRefFromPemCertificate:(NSString *)pemCertificate
                           publicKeyIdentifier:(NSString *)publicKeyIdentifier
                                         error:(NSError **)error;

@end
