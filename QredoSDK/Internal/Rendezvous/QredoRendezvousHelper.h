/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoTypes.h"
#import "QredoTypesPrivate.h"

@protocol QredoCryptoImpl;
@class QLFRendezvousAuthSignature;


static NSString *const QredoRendezvousHelperErrorDomain = @"QredoRendezvousHelperErrorDomain";

typedef NS_ENUM (NSUInteger,QredoRendezvousHelperError) {
    //TODO: DH - Remove unused error values
    QredoRendezvousHelperErrorUnknown = 0,
    QredoRendezvousHelperErrorMissingTag,
    QredoRendezvousHelperErrorMalformedTag,
    QredoRendezvousHelperErrorAuthenticationTagMissing,
    QredoRendezvousHelperErrorAuthenticationTagInvalid,
    QredoRendezvousHelperErrorPublicKeyIdentifierMissing,
    QredoRendezvousHelperErrorTrustedRootsInvalid,
    QredoRendezvousHelperErrorKeyGenerationFailed,
    QredoRendezvousHelperErrorMissingDataToSign,
    QredoRendezvousHelperErrorBadSignature,
    QredoRendezvousHelperErrorSignatureHandlerMissing,
    QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided,
};

/**
 * A helper for constructing rendezvous and validating authenticated rendezvous.
 *
 * For anonymous rendezvous, it can generate a random tag if one does not already exist.
 * For authenticated rendezvous, it can generate public / private keypairs, the public part being the tag.
 * It can also sign authenticated rendezvous, and validate a signature on them.
 */
@protocol QredoRendezvousHelper <NSObject>

/**
 * Get the authentication type
 *
 * @return The type.
 */
-(QredoRendezvousAuthenticationType)type;

/**
 * Get the plaintext representation of the rendezvous tag.
 * <p>
 * The tag may be incompletely specified by the SDK, if the user wishes us to generate a random tag for them,
 * or for other authentication types, a public/private keypair can be generated when the tag is not specified.
 *
 * @return The rendezvous tag
 */
-(NSString *)tag;

/**
 * Gets an empty lingua franca signature type (the signature is not present).
 *
 * @return The signature type for the rendezvous (with no signature present yet).
 */
-(QLFRendezvousAuthSignature *)emptySignature;


@end


@protocol QredoRendezvousCreateHelper <QredoRendezvousHelper>

/**
 * Gets the lingua franca signature type with the signature taken over a byte array.
 *
 * @param data  Data to be signed.
 * @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual
 *              error object containing the error information. You may specify nil for this parameter if you do
 *              not want the error information.
 * @return The signature type for the rendezvous with a signature.
 */
-(QLFRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error;


@end


@protocol QredoRendezvousRespondHelper <QredoRendezvousHelper>

/**
 * Verify the signature
 *
 * @param rendezvousData    Data to be signed (does not include the signature).
 * @param signature         The signature.
 * @param error             On input, a pointer to an error object. If an error occurs, this pointer is set to an
 *                          actual error object containing the error information. You may specify nil for this
 *                          parameter if you do not want the error information.
 * @return True if the signature is valid, false otherwise.
 */
-(BOOL)isValidSignature:(QLFRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error;

@end
