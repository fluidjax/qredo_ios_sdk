/* HEADER GOES HERE */
#include "rsapss.h"
#include <stdio.h>
#include <CommonCrypto/CommonCrypto.h>
#include <Security/Security.h>

static void mgf_mask(unsigned char *dst,size_t dlen,unsigned char *src,size_t slen);


int rsa_pss_sha256_encode(const void *input_hash_data,size_t input_hash_data_len,size_t sLen,
                          size_t emBits,void *encoded_data_out,size_t encoded_data_max_size) {
    int result = 0;
    
    //length of hash in bytes, in our case it is hardcoded to SHA-256
    const int hLen = CC_SHA256_DIGEST_LENGTH;
    
    //Variable names are aligned with the specification of EMSA-PSS-ENCODE http://tools.ietf.org/html/rfc3447#section-9.1.1
    size_t emLen = (emBits + 7) / 8; //ceil(emBits / 8)
    
    //All dynamically allocated buffers should be declared before the function can terminate with an error
    //This bufferss are checked after fail: label and will be released
    uint8_t *DB = NULL;
    uint8_t *salt = NULL;
    
    if (hLen != input_hash_data_len){
        result = QREDO_RSA_PSS_INVALID_ARGUMENT;
        goto fail;
    }
    
    //3.  If emLen < hLen + sLen + 2, output "encoding error" and stop.
    if (emLen < hLen + sLen + 2){
        result = QREDO_RSA_PSS_SALT_TOO_LONG;
        goto fail;
    }
    
    if (encoded_data_max_size < emLen){
        result = QREDO_RSA_PSS_BUFFER_TOO_SHORT;
        goto fail;
    }
    
    //4.  Generate a random octet string salt of length sLen; if sLen = 0, then salt is the empty string.
    salt = malloc(sLen);
    
    if (!salt){
        result = QREDO_RSA_PSS_OUT_OF_MEMORY;
        goto fail;
    }
    
    int copyResult = SecRandomCopyBytes(kSecRandomDefault,sLen,salt);
    
    if (copyResult != 0){
        result = QREDO_RSA_PSS_RANDOM_GENERATION_FAILED;
        goto fail;
    }
    
    //5.  Let M' = (0x)00 00 00 00 00 00 00 00 || mHash || salt;
    //6.  Let H = Hash(M'), an octet string of length hLen.
    uint8_t H[hLen];
    uint8_t zeroes[8] = { 0 };
    
    CC_SHA256_CTX hash_ctx;
    CC_SHA256_Init(&hash_ctx);
    CC_SHA256_Update(&hash_ctx,zeroes,8);
    CC_SHA256_Update(&hash_ctx,input_hash_data,(CC_LONG)input_hash_data_len);
    CC_SHA256_Update(&hash_ctx,salt,(CC_LONG)sLen);
    CC_SHA256_Final(H,&hash_ctx);
    
    //7.  Generate an octet string PS consisting of emLen - sLen - hLen - 2
    //zero octets.  The length of PS may be 0.
    size_t PSlen = emLen - sLen - hLen - 2;
    
    //8.  Let DB = PS || 0x01 || salt; DB is an octet string of length
    //emLen - hLen - 1.
    size_t DBlen = emLen - hLen - 1;
    DB = malloc(DBlen);
    
    if (!DB){
        result = QREDO_RSA_PSS_OUT_OF_MEMORY;
        goto fail;
    }
    
    memset(DB,0,PSlen);
    DB[PSlen] = 0x01;
    memcpy(DB + PSlen + 1,salt,sLen);
    
    //9.  Let dbMask = MGF(H, emLen - hLen - 1).
    //10. Let maskedDB = DB \xor dbMask.
    mgf_mask(DB,DBlen,H,hLen);
    
    //DB already has the masked applied, so maskedDB == DB
    
    //11. Set the leftmost 8emLen - emBits bits of the leftmost octet in
    //maskedDB to zero.
    
    long zeroCount = 8 * emLen - emBits;
    
    int byteNum = 0;
    
    while (zeroCount > 0){
        uint8_t mask = 0x7f >> ((zeroCount & 7) - 1);
        
        DB[byteNum] &= mask;
        
        zeroCount -= 8;
        ++byteNum;
    }
    
    
    
    //12. Let EM = maskedDB || H || 0xbc.
    
    uint8_t *EM = (uint8_t *)encoded_data_out;
    memcpy(EM,DB,DBlen);
    memcpy(EM + DBlen,H,hLen);
    EM[DBlen + hLen] = 0xbc;
    
    //13. Output EM.
    result = (int)emLen;
    
fail:
    free(salt);
    free(DB);
    return result;
}

//returns 0 if successful
int rsa_pss_sha256_verify(const void *mHash,size_t mHashLen,
                          const void *encoded_message,size_t encoded_message_size,size_t sLen,
                          size_t emBits) {
    int result = 0;
    
    //1.  If the length of M is greater than the input limitation for the
    //hash function (2^61 - 1 octets for SHA-1), output "inconsistent"
    //and stop.
    
    //length of hash in bytes, in our case it is hardcoded to SHA-256
    const int hLen = CC_SHA256_DIGEST_LENGTH;
    
    //Variable names are aligned with the specification of EMSA-PSS-ENCODE http://tools.ietf.org/html/rfc3447#section-9.1.1
    size_t emLen = (emBits + 7) / 8; //ceil(emBits / 8)
    
    //All dynamically allocated buffers should be declared before the function can terminate with an error
    //This bufferss are checked after fail: label and will be released
    uint8_t *DB = NULL;
    
    const uint8_t *EM = (const uint8_t *)encoded_message;
    
    int i;
    
    //skipping 2. This function just decodes PSS, but doesn't verify
    
    //3.  If emLen < hLen + sLen + 2, output "inconsistent" and stop.
    if (emLen < hLen + sLen + 2){
        result = QREDO_RSA_PSS_SALT_TOO_LONG;
        goto fail;
    }
    
    //4.  If the rightmost octet of EM does not have hexadecimal value
    //0xbc, output "inconsistent" and stop.
    if (EM[encoded_message_size - 1] != 0xbc){
        result = QREDO_RSA_PSS_INVALID_DATA;
        goto fail;
    }
    
    //5.  Let maskedDB be the leftmost emLen - hLen - 1 octets of EM, and...
    size_t DBlen = emLen - hLen - 1;
    DB = malloc(DBlen);
    
    if (!DB){
        result = QREDO_RSA_PSS_OUT_OF_MEMORY;
        goto fail;
    }
    
    memcpy(DB,EM,DBlen);
    
    //let H be the next hLen octets.
    uint8_t H[hLen];
    memcpy(H,EM + DBlen,hLen);
    
    //6.  If the leftmost 8emLen - emBits bits of the leftmost octet in
    //maskedDB are not all equal to zero, output "inconsistent" and
    //stop.
    
    long zeroCount = 8 * emLen - emBits;
    
    
    
    int byteNum = 0;
    
    while (zeroCount > 0){
        uint8_t mask = 0x7f >> ((zeroCount & 7) - 1);
        
        if (DB[byteNum] & (~mask)){
            result = QREDO_RSA_PSS_INVALID_DATA;
            goto fail;
        }
        
        zeroCount -= 8;
        ++byteNum;
    }
    
    //7.  Let dbMask = MGF(H, emLen - hLen - 1).
    //8.  Let DB = maskedDB \xor dbMask.
    mgf_mask(DB,DBlen,H,hLen);
    
    //DB already has the masked applied, so DB == maskedDB
    
    //9.  Set the leftmost 8emLen - emBits bits of the leftmost octet in DB
    //to zero.
    
    zeroCount = 8 * emLen - emBits;
    
    byteNum = 0;
    
    while (zeroCount > 0){
        uint8_t mask = 0x7f >> ((zeroCount & 7) - 1);
        
        DB[byteNum] &= mask;
        
        zeroCount -= 8;
        ++byteNum;
    }
    
    //10. If the emLen - hLen - sLen - 2 leftmost octets of DB are not zero
    //or if the octet at position emLen - hLen - sLen - 1 (the leftmost
    //position is "position 1") does not have hexadecimal value 0x01,
    //output "inconsistent" and stop.
    
    size_t zeroOctets = emLen - hLen - sLen - 2;
    unsigned char sum = 0;
    
    for (i = 0; i < zeroOctets; ++i){
        sum |= DB[i];
    }
    
    if (sum != 0){
        result = QREDO_RSA_PSS_INVALID_DATA;
        goto fail;
    }
    
    if (DB[zeroOctets] != 0x01){
        result = QREDO_RSA_PSS_INVALID_DATA;
        goto fail;
    }
    
    //11.  Let salt be the last sLen octets of DB.
    uint8_t *salt = DB + DBlen - sLen;
    
    //12.  Let
    //M' = (0x)00 00 00 00 00 00 00 00 || mHash || salt ;
    //M' is an octet string of length 8 + hLen + sLen with eight
    //initial zero octets.
    
    //13. Let H' = Hash(M'), an octet string of length hLen.
    
    //(no need to construct M'. Just calculating hash directly
    
    uint8_t zeros[8] = { 0 };
    uint8_t hHash[hLen] = { 0 };
    CC_SHA256_CTX sha256_ctx;
    CC_SHA256_Init(&sha256_ctx);
    CC_SHA256_Update(&sha256_ctx,zeros,8);
    CC_SHA256_Update(&sha256_ctx,mHash,(CC_LONG)mHashLen);
    CC_SHA256_Update(&sha256_ctx,salt,(CC_LONG)sLen);
    CC_SHA256_Final(hHash,&sha256_ctx);
    
    //14. If H = H', output "consistent." Otherwise, output "inconsistent."
    //avoiding memcmp just because it is easy to find it in debugger by potential attacker
    for (i = 0; i < hLen; i++){
        if (hHash[i] != H[i]){
            result = QREDO_RSA_PSS_NOT_VERIFIED;
            goto fail;
        }
    }
    
    result = QREDO_RSA_PSS_VERIFIED;
    
fail:
    free(DB);
    return result;
}

/**
 * Generate and apply the MGF1 operation (from PKCS#1 v2.1) to a buffer.
 *
 * \param dst       buffer to mask
 * \param dlen      length of destination buffer
 * \param src       source of the mask generation
 * \param slen      length of the source buffer
 * \param md_ctx    message digest context to use
 */
static void mgf_mask(unsigned char *dst,size_t dlen,
                     unsigned char *src,size_t slen) {
    CC_SHA256_CTX md_ctx;
    unsigned char mask[CC_SHA256_DIGEST_LENGTH];
    unsigned char counter[4];
    unsigned char *p;
    unsigned int hlen;
    size_t i,use_len;
    
    memset(mask,0,CC_SHA256_DIGEST_LENGTH);
    memset(counter,0,4);
    
    hlen = CC_SHA256_DIGEST_LENGTH;
    
    //Generate and apply dbMask
    p = dst;
    
    while (dlen > 0){
        use_len = hlen;
        
        if (dlen < hlen)use_len = dlen;
        
        CC_SHA256_Init(&md_ctx);
        CC_SHA256_Update(&md_ctx,src,(CC_LONG)slen);
        CC_SHA256_Update(&md_ctx,counter,4);
        CC_SHA256_Final(mask,&md_ctx);
        
        for (i = 0; i < use_len; ++i){
            *p++ ^= mask[i];
        }
        
        counter[3]++;
        
        dlen -= use_len;
    }
}
