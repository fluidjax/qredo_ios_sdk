/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#include "QredoRsaBlindSignature.h"
#include <Security/SecRandom.h>
#include <stdbool.h>
//#include "tomcrypt.h"
//#include "tommath.h"

#define QREDO_BITS_PER_BYTE 8

//int blindMessage(unsigned char *publicModulus, size_t publicModulusLength,
//                 unsigned char *exponent, size_t exponentLength,
//                 unsigned char *message, size_t messageLength,
//                 unsigned char *blindingFactor, size_t *blindingFactorLength,
//                 unsigned char *blindedMessage, size_t *blindedMessageLength)
//{
//    /*
//     Steps:
//     1.) Convert the public modulus + exponent byte arrays to internal Big Integer format
//     2.) Generate the Blinding Factor (random number, smaller than modulus and relatively prime to modulus (i.e. GCD = 1))
//     3.) Blind the message using the Blinding Factor
//     4.) Convert the blinded message to byte array and return (blinded message and blinding factor)
//     */
//    
//    int qredoResult = QREDO_BLINDING_SUCCESS;
//    int mpResult;
//    mp_int mpModulus, mpExponent, mpMessage, mpBlindedMessage, mpBlindingFactor;
//    
//    // Validate pointers
//    if (!publicModulus || !exponent || !message || !blindingFactor || !blindedMessage || !blindingFactorLength || !blindedMessageLength)
//    {
//        qredoResult = QREDO_BLINDING_NULL_ARGUMENT;
//    }
//    // Validate lengths
//    else if ((publicModulusLength <= 0) ||
//        (exponentLength <= 0) ||
//        (messageLength <= 0) ||
//        (*blindingFactorLength <= 0) ||
//        (*blindedMessageLength <= 0))
//    {
//        qredoResult = QREDO_BLINDING_INVALID_ARGUMENT;
//    }
//    
//    // Validation complete, return early if validation failed
//    if (qredoResult != QREDO_BLINDING_SUCCESS)
//    {
//        // No cleanup required yet, so an just return
//        return qredoResult;
//    }
//    
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        // Initialise the big integers
//        mpResult = mp_init_multi(&mpModulus, &mpExponent, &mpMessage, &mpBlindedMessage, &mpBlindingFactor, NULL);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_INIT_FAILED;
//        }
//    }
//    
//    // Initialise the modulus integer from the byte array format
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        // TODO: DH - need to deal with signed values possibly? In ASN1 there can be a leading zero (or 01?) at times to deal with signed-ness
//        mpResult = mp_read_unsigned_bin(&mpModulus, publicModulus, (int)publicModulusLength);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//        }
//    }
//
//    // Initialise the exponent integer from the byte array format
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        // TODO: DH - need to deal with signed values possibly? In ASN1 there can be a leading zero (or 01?) at times to deal with signed-ness
//        mpResult = mp_read_unsigned_bin(&mpExponent, exponent, (int)exponentLength);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//        }
//    }
//    
//    // Initialise the message integer from the byte array format
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        mpResult = mp_read_unsigned_bin(&mpMessage, message, (int)messageLength);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//        }
//    }
//
//    // Generate a random big integer (less than the size of the modulus)
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        qredoResult = generateBlindingFactor(&mpModulus, &mpBlindingFactor);
//    }
//    
//    // Blinded message is blindingFactor.ModPow(exp, pub mod), then multiply result with the message, then mod the modulus
//    // 1.) BlindMessage = (BlindingFactor**exponent (mod modulus)
//    // 2.) BlindMessage = BlindMessage * Message
//    // 3.) BlindMessage = BlindMessage mod modulus
//
//    // 1.) BlindMessage = (BlindingFactor**exponent (mod modulus)
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        
//        /* d = a**b (mod c) */
//        // int mp_exptmod(mp_int *a, mp_int *b, mp_int *c, mp_int *d);
//        mpResult = mp_exptmod(&mpBlindingFactor, &mpExponent, &mpModulus, &mpBlindedMessage);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_MOD_EXP_FAILED;
//        }
//    }
//
//    // 2.) BlindMessage = BlindMessage * Message
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        /* c = a * b */
//        // int mp_mul(mp_int *a, mp_int *b, mp_int *c);
//        mpResult = mp_mul(&mpBlindedMessage, &mpMessage, &mpBlindedMessage);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_MOD_EXP_FAILED;
//        }
//    }
//    
//    // 3.) BlindMessage = BlindMessage mod modulus
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        /* c = a mod b, 0 <= c < b  */
//        // int mp_mod(mp_int *a, mp_int *b, mp_int *c);
//        mpResult = mp_mod(&mpBlindedMessage, &mpModulus, &mpBlindedMessage);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_MOD_EXP_FAILED;
//        }
//    }
//    
//    
//    // We have our blinded message, now convert all the outputs to byte arrays
//    
//    // Convert the blinding factor to a byte array
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        int sizeRequired = mp_unsigned_bin_size(&mpBlindingFactor);
//        
//        if (sizeRequired > *blindingFactorLength)
//        {
//            qredoResult = QREDO_BLINDING_BUFFER_TOO_SHORT;
//        }
//        else
//        {
//            mpResult = mp_to_unsigned_bin(&mpBlindingFactor, blindingFactor);
//            if (mpResult != MP_OKAY)
//            {
//                qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//            }
//            else
//            {
//                // Successfully copied the data, so set the correct length
//                *blindingFactorLength = sizeRequired;
//            }
//        }
//    }
//    
//    // Convert the blind message to a byte array so we can return the data. Note, conversion writes
//    // to the output variables directly.
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        int sizeRequired = mp_unsigned_bin_size(&mpBlindedMessage);
//        
//        if (sizeRequired > *blindedMessageLength)
//        {
//            qredoResult = QREDO_BLINDING_BUFFER_TOO_SHORT;
//        }
//        else
//        {
//            mpResult = mp_to_unsigned_bin(&mpBlindedMessage, blindedMessage);
//            if (mpResult != MP_OKAY)
//            {
//                qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//            }
//            else
//            {
//                // Successfully copied the data, so set the correct length
//                *blindedMessageLength = sizeRequired;
//            }
//        }
//    }
//    
//    // On error, zero the blinded message and blinding factor outputs
//    if (qredoResult != QREDO_BLINDING_SUCCESS)
//    {
//        memset_s(blindedMessage, *blindedMessageLength, 0x00, *blindedMessageLength);
//        *blindedMessageLength = 0;
//        memset_s(blindingFactor, *blindingFactorLength, 0x00, *blindingFactorLength);
//        *blindingFactorLength = 0;
//    }
//    
//    // Free up memory
//    mp_clear_multi(&mpModulus, &mpExponent, &mpMessage, &mpBlindedMessage, &mpBlindingFactor, NULL);
//    
//    return qredoResult;
//}

//int unblindSignature(unsigned char *publicModulus, size_t publicModulusLength,
//                     unsigned char *blindingFactor, size_t blindingFactorLength,
//                     unsigned char *blindedSignature, size_t blindedSignatureLength,
//                     unsigned char *unblindedSignature, size_t *unblindedSignatureLength)
//{
//    /*
//     Steps:
//     1.) Convert the public modulus byte array to internal Big Integer format
//     2.) Convert the Blinding Factor byte array to internal Big Integer format
//     3.) Convert the Blinded Signature byte array to internal Big Integer format
//     4.) Unblind the signature using the Blinding Factor
//     5.) Convert the unblinded signature to byte array and return
//     */
//    
//    int qredoResult = QREDO_BLINDING_SUCCESS;
//    mp_int mpModulus, mpUnblindedSignature, mpBlindedSignature, mpBlindingFactor;
//    
//    // Validate pointers
//    if (!publicModulus || !blindingFactor || !blindedSignature || !unblindedSignature || !unblindedSignatureLength)
//    {
//        qredoResult = QREDO_BLINDING_NULL_ARGUMENT;
//    }
//    // Validate lengths
//    else if ((publicModulusLength <= 0) ||
//        (blindingFactorLength <= 0) ||
//        (blindedSignatureLength <= 0) ||
//        (*unblindedSignatureLength <= 0))
//    {
//        qredoResult = QREDO_BLINDING_INVALID_ARGUMENT;
//    }
//    
//    // Validation complete, return early if validation failed
//    if (qredoResult != QREDO_BLINDING_SUCCESS)
//    {
//        // No cleanup required yet, so an just return
//        return qredoResult;
//    }
//    
//    // Initialise the big integers
//    int mpResult = mp_init_multi(&mpModulus, &mpUnblindedSignature, &mpBlindedSignature, &mpBlindingFactor, NULL);
//    if (mpResult != MP_OKAY)
//    {
//        qredoResult = QREDO_BLINDING_INIT_FAILED;
//    }
//    
//    // Initialise the modulus integer from the byte array format
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        // TODO: DH - need to deal with signed values possibly? In ASN1 there can be a leading zero (or 01?) at times to deal with signed-ness
//        mpResult = mp_read_unsigned_bin(&mpModulus, publicModulus, (int)publicModulusLength);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//        }
//    }
//
//    // Initialise the blinding factor integer from the byte array format
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        mpResult = mp_read_unsigned_bin(&mpBlindingFactor, blindingFactor, (int)blindingFactorLength);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//        }
//    }
//    
//    // Initialise the blinded signature integer from the byte array format
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        mpResult = mp_read_unsigned_bin(&mpBlindedSignature, blindedSignature, (int)blindedSignatureLength);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//        }
//    }
//    
//    // Unblinded signature is blindingFactor.ModInverse(pub mod), then multiply result with the blinded signature, then mod the modulus
//    // 1.) UnblindedSignature = 1/BlindingFactor (mod modulus)
//    // 2.) UnblindedSignature = UnblindedSignature * BlindedSignature
//    // 3.) UnblindedSignature = UnblindedSignature mod modulus
//    
//    
//    // 1.) UnblindedSignature = 1/BlindingFactor (mod modulus)
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        /* c = 1/a (mod b) */
//        // int mp_invmod(mp_int *a, mp_int *b, mp_int *c);
//        mpResult = mp_invmod(&mpBlindingFactor, &mpModulus, &mpUnblindedSignature);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_MOD_EXP_FAILED;
//        }
//    }
//    
//    // 2.) UnblindedSignature = UnblindedSignature * BlindedSignature
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        /* c = a * b */
//        // int mp_mul(mp_int *a, mp_int *b, mp_int *c);
//        mpResult = mp_mul(&mpUnblindedSignature, &mpBlindedSignature, &mpUnblindedSignature);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_MOD_EXP_FAILED;
//        }
//    }
//    
//    // 3.) UnblindedSignature = UnblindedSignature mod modulus
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        /* c = a mod b, 0 <= c < b  */
//        // int mp_mod(mp_int *a, mp_int *b, mp_int *c);
//        mpResult = mp_mod(&mpUnblindedSignature, &mpModulus, &mpUnblindedSignature);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_MOD_EXP_FAILED;
//        }
//    }
//    
//    // We have our unblinded signature, now convert all the output to byte arrays
//    
//    // Convert the unblinded message to a byte array so we can return the data. Note, conversion writes
//    // to the output variables directly.
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        int sizeRequired = mp_unsigned_bin_size(&mpUnblindedSignature);
//        
//        if (sizeRequired > *unblindedSignatureLength)
//        {
//            qredoResult = QREDO_BLINDING_BUFFER_TOO_SHORT;
//        }
//        else
//        {
//            mpResult = mp_to_unsigned_bin(&mpUnblindedSignature, unblindedSignature);
//            if (mpResult != MP_OKAY)
//            {
//                qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//            }
//            else
//            {
//                // Successfully copied the data, so set the correct length
//                *unblindedSignatureLength = sizeRequired;
//            }
//        }
//    }
//    
//    // On error, zero the blinded signature and blinding factor outputs
//    if (qredoResult != QREDO_BLINDING_SUCCESS)
//    {
//        memset_s(unblindedSignature, *unblindedSignatureLength, 0x00, *unblindedSignatureLength);
//        *unblindedSignatureLength = 0;
//    }
//    
//    // Free up memory
//    mp_clear_multi(&mpModulus, &mpUnblindedSignature, &mpBlindedSignature, &mpBlindingFactor, NULL);
//    
//    return qredoResult;
//}
//
//int getByteLength(int bits)
//{
//    // Gets the number of bytes required for a specified number of bits (1-8 bits requires 1 byte etc)
//    return (bits + QREDO_BITS_PER_BYTE - 1) / QREDO_BITS_PER_BYTE;
//}
//
//int generateRandomInteger(int bitCount, mp_int *randomInteger)
//{
//    // General rule: caller will allocate and initialise mp_int arguments, and be responsible for clearing/freeing
//
//    int qredoResult = QREDO_BLINDING_SUCCESS;
//    int mpResult;
//
//    int byteCount = getByteLength(bitCount);
//    uint8_t *randomBytes = alloca(byteCount);
//    int result = SecRandomCopyBytes(kSecRandomDefault, byteCount, randomBytes);
//    if (result != 0) {
//        qredoResult = QREDO_BLINDING_RANDOM_GENERATION_FAILED;
//    }
//    
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        // Remove (zero) any excess bits in the MSB (first byte)
//        int bitsToStrip = (byteCount * QREDO_BITS_PER_BYTE) - bitCount;
//        randomBytes[0] &= 0xFF >> bitsToStrip;
//    }
//    
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        mpResult = mp_read_unsigned_bin(randomInteger, randomBytes, (int)byteCount);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_CONVERSION_FAILED;
//        }
//    }
//    
//    return qredoResult;
//}
//
//int generateRandomIntegerLessThanAnother(mp_int *randomInteger, mp_int *otherInteger)
//{
//    // General rule: caller will allocate and initialise mp_int arguments, and be responsible for clearing/freeing
//
//    int qredoResult = QREDO_BLINDING_SUCCESS;
//    
//    // Maximum number of attempts at generating a number less than the existing number.
//    // Needed to guarantee we avoid a forever while loop
//    const int maxAttempts = 256;
//    int attempts = 0;
//    int comparisonResult;
//
//    int numberOfBitsInOtherInteger = mp_count_bits(otherInteger);
//    
//    // Keep generating random integers until the generated one is less than otherInteger
//    // or until it generates an error, or until we've hit the max attempts
//    do
//    {
//        qredoResult = generateRandomInteger(numberOfBitsInOtherInteger, randomInteger);
//        
//        if (qredoResult != QREDO_BLINDING_SUCCESS)
//        {
//            break;
//        }
//        
//        comparisonResult = mp_cmp(randomInteger, otherInteger);
//        
//        if (comparisonResult == MP_LT)
//        {
//            // Found a suitable value, return the already assigned success result
//            break;
//        }
//    } while (attempts < maxAttempts);
//    
//    return qredoResult;
//}
//
//int generateBlindingFactor(mp_int *modulus, mp_int *blindingFactor)
//{
//    // General rule: caller will allocate and initialise mp_int arguments, and be responsible for clearing/freeing
//
//    /*
//     Steps:
//     1.) Convert the public modulus byte array to internal Big Integer format
//     2.) Generate a new random Big Integer (called blindingFactor) which is smaller than the public modulus
//     3.) Find the Greatest Common Divisor of the blindingFactor
//     4.) Check that the factor is not 0 or 1 (if it is, return to step 2)
//     5.) Check that the GCD is 1 (if it is not, return to step 2)
//     6.) If checks pass, then we've got our Blinding Factor, so convert return the Big Integer
//     */
//
//    int qredoResult = QREDO_BLINDING_SUCCESS;
//    mp_int gcd;
//    mp_int candiateFactor;
//    mp_int one;
//    bool factorIsValid = false;
//    const int maxBlindingFactorAttempts = 100; // Haven't yet seen more than 1 attempt needed, but used to prevent endless loop
//    int attempts = 0;
//    
//    // Initialise the big integers
//    int mpResult = mp_init_multi(&gcd, &candiateFactor, NULL);
//    if (mpResult != MP_OKAY)
//    {
//        qredoResult = QREDO_BLINDING_INIT_FAILED;
//    }
//
//    // Create the mp_int with value 1
//    if (qredoResult == QREDO_BLINDING_SUCCESS)
//    {
//        mpResult = mp_init_set(&one, 1);
//        if (mpResult != MP_OKAY)
//        {
//            qredoResult = QREDO_BLINDING_INIT_FAILED;
//        }
//    }
//    
//    do
//    {
//        attempts++;
//        
//        // Generate a random candiate blinding factor
//        if (qredoResult == QREDO_BLINDING_SUCCESS)
//        {
//            qredoResult = generateRandomIntegerLessThanAnother(&candiateFactor, modulus);
//        }
//        
//        // Get the Greatest Common Divisor (GCD) for modulus and our blinding factor
//        if (qredoResult == QREDO_BLINDING_SUCCESS)
//        {
//            mpResult = mp_gcd(&candiateFactor, modulus, &gcd);
//            if (mpResult != MP_OKAY)
//            {
//                qredoResult = QREDO_BLINDING_GCD_FAILED;
//            }
//        }
//
//        // Validate the GCD and Factor values
//        // A valid blinding factor is one where GCD = 1 and factor != 0 and factor != 1
//        if (qredoResult == QREDO_BLINDING_SUCCESS)
//        {
//            factorIsValid = true;
//            
//            // Factor cannot be 0
//            if (mp_iszero(&candiateFactor))
//            {
//                factorIsValid = false;
//            }
//            
//            // Factor cannot be 1
//            if (mp_cmp(&candiateFactor, &one) == MP_EQ)
//            {
//                factorIsValid = false;
//            }
//            
//            // GCD must be 1
//            if (mp_cmp(&gcd, &one) != MP_EQ)
//            {
//                factorIsValid = false;
//            }
//        }
//        
//        if (attempts >= maxBlindingFactorAttempts)
//        {
//            qredoResult = QREDO_BLINDING_GEN_BLINDING_FACTOR_FAILED;
//        }
//    } while ((qredoResult == QREDO_BLINDING_SUCCESS) && !factorIsValid);
//
//    // If everything was successful, then copy the result out for the caller to use
//    if ((qredoResult == QREDO_BLINDING_SUCCESS) && factorIsValid)
//    {
//        mpResult = mp_copy(&candiateFactor, blindingFactor);
//    }
//    
//    if (mpResult != MP_OKAY)
//    {
//        qredoResult = QREDO_BLINDING_COPY_FAILED;
//    }
//
//    // Free up memory
//    mp_clear_multi(&gcd, &candiateFactor, &one, NULL);
//            
//    return qredoResult;
//}
