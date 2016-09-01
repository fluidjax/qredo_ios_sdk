/* HEADER GOES HERE */
#ifndef __QredoSDK__QredoRsaBlindSignature__
#define __QredoSDK__QredoRsaBlindSignature__

#include <stdio.h>
//#include "tommath.h"

// Result codes
#define QREDO_BLINDING_INVALID_ARGUMENT -100
#define QREDO_BLINDING_BUFFER_TOO_SHORT -101
#define QREDO_BLINDING_NULL_ARGUMENT -102

#define QREDO_BLINDING_OUT_OF_MEMORY -200
#define QREDO_BLINDING_INIT_FAILED -201
#define QREDO_BLINDING_CONVERSION_FAILED -202
#define QREDO_BLINDING_RANDOM_GENERATION_FAILED -203
#define QREDO_BLINDING_GCD_FAILED -204
#define QREDO_BLINDING_GET_SIZE_FAILED -205
#define QREDO_BLINDING_MOD_EXP_FAILED -206
#define QREDO_BLINDING_GEN_BLINDING_FACTOR_FAILED -206
#define QREDO_BLINDING_COPY_FAILED -207

#define QREDO_BLINDING_SUCCESS 1

//int blindMessage(unsigned char *publicModulus, size_t publicModulusLength, unsigned char *exponent, size_t exponentLength, unsigned char *message, size_t messageLength, unsigned char *blindingFactor, size_t *blindingFactorLength, unsigned char *blindedMessage, size_t *blindedMessageLength);
//int unblindSignature(unsigned char *publicModulus, size_t publicModulusLength, unsigned char *blindingFactor, size_t blindingFactorLength, unsigned char *blindedSignature, size_t blindedSignatureLength, unsigned char *unblindedSignature, size_t *unblindedSignatureLength);
//int generateRandomInteger(int bitCount, mp_int *randomInteger);
//int generateRandomIntegerLessThanAnother(mp_int *randomInteger, mp_int *otherInteger);
//int generateBlindingFactor(mp_int *modulus, mp_int *blindingFactor);

#endif /* defined(__QredoSDK__QredoRsaBlindSignature__) */
