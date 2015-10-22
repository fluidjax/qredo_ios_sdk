/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_rsapss_h
#define QredoSDK_rsapss_h

// PSS encoding for RSA signatures

// The only dependency on iOS at the moment is using CommonCrypto for calculation SHA256
// and generation of crypto-random numbers
// In future that can be wrapped or even replaced by #define

#include <stdint.h>


// Result codes
#define QREDO_RSA_PSS_INVALID_ARGUMENT          -100
#define QREDO_RSA_PSS_BUFFER_TOO_SHORT          -101
#define QREDO_RSA_PSS_SALT_TOO_LONG             -102
#define QREDO_RSA_PSS_INVALID_DATA              -103

#define QREDO_RSA_PSS_OUT_OF_MEMORY             -200
#define QREDO_RSA_PSS_RANDOM_GENERATION_FAILED  -201

#define QREDO_RSA_PSS_NOT_VERIFIED              -300

#define QREDO_RSA_PSS_VERIFIED                  1

// Input data should be already hashed (SHA-256). This is done mainly for effeciency, as the hash can be pre-calculated already, or if it is a large data
// then it might be better to calculated it by chunks rather than putting it whole in memory
// Result: Lengths in bytes of the encoded message, or negative value, if there was an error
int rsa_pss_sha256_encode(const void* input_hash_data, size_t input_hash_data_len, size_t salt_length_bytes,
                          size_t key_size_bits, void* encoded_data_out, size_t encoded_data_max_size);

// returns QREDO_RSA_PSS_VERIFIED if successful
int rsa_pss_sha256_verify(const void *input_hash_data, size_t input_hash_data_len,
                          const void* encoded_message, size_t encoded_message_size, size_t salt_length_bytes, size_t key_size_bits);

#endif
