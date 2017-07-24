//
//  QredoCryptoTestUtilities.m
//  QredoSDK
//
//  Created by Christopher Morris on 11/07/2017.
//
//

#import "QredoCryptoTestUtilities.h"
#import "MasterConfig.h"
#import "QredoLoggerPrivate.h"
#import "QredoCrypto.h"
#import "rsapss.h"

@implementation QredoCryptoTestUtilities

SecPadding secPaddingFromQredoPadding(QredoPadding);
SecPadding secPaddingFromQredoPaddingForPlainData(QredoPadding,size_t,NSData*);

+(BOOL)deleteKeyInAppleKeychainWithIdentifier:(NSString *)keyIdentifier {
    
    GUARD(keyIdentifier,
          @"Key identifier argument is nil");
    
    BOOL success = YES;
    
    NSData *tag = [keyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!tag)return NO;
    
    //Specify that all items of kSecClassKey which have this identifier tag should be deleted
    NSDictionary *secKeysToDelete = @{ (__bridge id)kSecClass:(__bridge id)kSecClassKey,
                                       (__bridge id)kSecAttrApplicationTag:tag };
    
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)secKeysToDelete);
    
    if (result != errSecSuccess){
        success = NO;
        
        if (result == errSecItemNotFound){
            //This means that the specified key was not found. This is an error as specifying a specific key
            QredoLogError(@"Could not find key with identifier '%@' to delete.",keyIdentifier);
        } else {
            QredoLogError(@"SecItemDelete returned error: %@.",[QredoLogger stringFromOSStatus:result]);
        }
    }
    
    return success;
}



+(SecKeyRef)importPkcs1KeyData:(NSData *)keyData keyLengthBits:(NSUInteger)keyLengthBits keyIdentifier:(NSString *)keyIdentifier isPrivate:(BOOL)isPrivate {
    //Note, this method will happily import public key data marked as private, but our getRsaSecKeyReferenceForIdentifier method will return null SecKeyRef (and no error).
    
    CFTypeRef keyClass = kSecAttrKeyClassPublic;
    
    if (isPrivate){
        keyClass = kSecAttrKeyClassPrivate;
    }
    
    NSData *tag = [keyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    /* Attributes which are valid for kSecClassKey:
     
     kSecClassKey item attributes:
     kSecAttrAccessible
     kSecAttrAccessControl
     kSecAttrAccessGroup
     kSecAttrKeyClass
     kSecAttrLabel
     kSecAttrApplicationLabel
     kSecAttrIsPermanent - Note: appears to be ignored on SecItemAdd, can only Add permanent keys
     kSecAttrApplicationTag
     kSecAttrKeyType
     kSecAttrKeySizeInBits
     kSecAttrEffectiveKeySize
     kSecAttrCanEncrypt
     kSecAttrCanDecrypt
     kSecAttrCanDerive
     kSecAttrCanSign
     kSecAttrCanVerify
     kSecAttrCanWrap
     kSecAttrCanUnwrap
     
     */
    
    //Note: SecItemAdd() does not validate the key size argument.
    
    //TODO: DH - need to verify these settings, especially the canEncrypt/canDecrypt/canSign options - should these be configurable per key?  Configured based on public/private setting?  For now, allowing encrypt/decrypt/sign/verify
    NSMutableDictionary *keyAttributes = [[NSMutableDictionary alloc] init];
    keyAttributes[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    keyAttributes[(__bridge id)kSecAttrKeyType] = (__bridge id)kSecAttrKeyTypeRSA;
    keyAttributes[(__bridge id)kSecAttrApplicationTag] = tag;
    keyAttributes[(__bridge id)kSecAttrKeyClass] = (__bridge id)keyClass;
    keyAttributes[(__bridge id)kSecValueData] = keyData;
    keyAttributes[(__bridge id)kSecAttrKeySizeInBits] = [NSNumber numberWithInteger:keyLengthBits];
    keyAttributes[(__bridge id)kSecAttrEffectiveKeySize] = [NSNumber numberWithInteger:keyLengthBits];
    keyAttributes[(__bridge id)kSecAttrCanDerive] = (__bridge id)kCFBooleanFalse;
    keyAttributes[(__bridge id)kSecAttrCanEncrypt] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanDecrypt] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanVerify] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanSign] = (__bridge id)kCFBooleanTrue;
    keyAttributes[(__bridge id)kSecAttrCanWrap] = (__bridge id)kCFBooleanFalse;
    keyAttributes[(__bridge id)kSecAttrCanUnwrap] = (__bridge id)kCFBooleanFalse;
    keyAttributes[(__bridge id)kSecReturnRef] = (__bridge id)kCFBooleanTrue;
    
    SecKeyRef secKeyRef = nil;
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keyAttributes,(CFTypeRef *)&secKeyRef);
    
    if (status != errSecSuccess){
        @throw [NSException exceptionWithName:@"QredoCryptoImportPublicKeyFailed"
                                       reason:[NSString stringWithFormat:@"Error code: %d",(int)status]
                                     userInfo:nil];
    } else if (!secKeyRef){
        @throw [NSException exceptionWithName:@"QredoCryptoImportPublicKeyInvalidFormat"
                                       reason:@"No imported key ref returned. Check key format is PKCS#1 ASN.1 DER."
                                     userInfo:nil];
    } else {
        return (SecKeyRef)secKeyRef;
    }
}



+(BOOL)deleteAllKeysInAppleKeychain {
    BOOL success = YES;
    
    //Just specify that all items of kSecClassKey should be deleted
    NSDictionary *secKeysToDelete = @{ (__bridge id)kSecClass:(__bridge id)kSecClassKey };
    
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)secKeysToDelete);
    
    if (result != errSecSuccess){
        if (result == errSecItemNotFound){
            //This means that no keys were present to delete, this is not an error in this situation (bulk delete of all keys)
        } else {
            QredoLogError(@"SecItemDelete returned error: %@.",[QredoLogger stringFromOSStatus:result]);
            success = NO;
        }
    }
    
    return success;
}

+(BOOL)rsaPssVerifySignature:(NSData *)signature forMessage:(NSData *)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef {
    
    
    GUARD(signature,
          @"Signature argument is nil.");
    
    GUARD(message,
          @"Message argument is nil.");
    
    GUARD(keyRef,
          @"Key ref argument is nil.");
    
    //Length of data to decrypt must equal key length
    size_t keyLength = SecKeyGetBlockSize(keyRef);
    
    GUARD(keyLength != 0,
          @"Invalid SecKeyRef. Key block size is 0 bytes.");
    
    GUARDF(signature.length == keyLength,
           @"Invalid data length (%lu). Signature must equal key length (%lu).",
           (unsigned long)signature.length, (unsigned long)keyLength);
    
    //Get a buffer of correct size for the specified key
    size_t outputDataLength = keyLength;
    NSMutableData *buffer = [NSMutableData dataWithLength:outputDataLength];
    
    OSStatus result = SecKeyDecrypt(keyRef, //key
                                    kSecPaddingNone, //padding
                                    signature.bytes, //cipherText
                                    signature.length, //ciptherTextLen
                                    buffer.mutableBytes, //plainText
                                    &outputDataLength); //plainTextLen
    
    if (result != errSecSuccess){
        QredoLogError(@"SecKeyDecrypt returned error: %@.",[QredoLogger stringFromOSStatus:result]);
        return NO;
    }
    
    //Restore any leading zeroes which were 'lost' in the decrypt by copying to array of keyLength, skipping the position of missing zeroes
    uint8_t *decryptedSignatureBytes = malloc(keyLength);
    size_t destinationIndex = keyLength - outputDataLength;
    memcpy(decryptedSignatureBytes + destinationIndex,buffer.bytes,outputDataLength);
    
    //This doesn't leak
    NSMutableData *decryptedSignature = [NSMutableData dataWithBytesNoCopy:decryptedSignatureBytes length:keyLength freeWhenDone:YES];
    
    
    NSData *hash = [QredoCrypto sha256:message];
    
    int pss_result = rsa_pss_sha256_verify(hash.bytes,hash.length,decryptedSignature.bytes,decryptedSignature.length,saltLength,keyLength * 8 - 1);
    
    if (pss_result < 0 && pss_result != QREDO_RSA_PSS_NOT_VERIFIED){
        QredoLogError(@"Failed to decode PSS data. Result %d",pss_result);
    }
    
    return pss_result == QREDO_RSA_PSS_VERIFIED;
}



//TODO: DH - create unit test for this? (check also if any other SecKeyRef methods added are tested)
+(SecCertificateRef)getCertificateRefFromIdentityRef:(SecIdentityRef)identityRef {
    
    GUARD(identityRef,
          @"Identity ref argument is nil");
    
    SecCertificateRef certificateRef = nil;
    
    OSStatus status = SecIdentityCopyCertificate(identityRef,&certificateRef);
    
    if (status != errSecSuccess){
        QredoLogError(@"SecIdentityCopyCertificate returned error: %@",[QredoLogger stringFromOSStatus:status]);
        certificateRef = nil;
    }
    
    return certificateRef;
}


+(SecKeyRef)getPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef {
    
    GUARD(identityRef,
          @"Identity ref argument is nil");
    
    SecKeyRef privateKeyRef = nil;
    
    OSStatus status = SecIdentityCopyPrivateKey(identityRef,&privateKeyRef);
    
    if (status != errSecSuccess){
        QredoLogError(@"SecIdentityCopyPrivateKey returned error: %@",[QredoLogger stringFromOSStatus:status]);
        identityRef = nil;
    }
    
    return privateKeyRef;
}




+(NSData *)rsaEncryptPlainTextData:(NSData *)plainTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef {
    
    GUARD(plainTextData,
          @"Plain text data argument is nil.");
    
    GUARD(keyRef,
          @"Key ref argument is nil");
    
    //Length of data to encrypt varies depending on the padding option and key length
    size_t keyLength = SecKeyGetBlockSize(keyRef);
    
    //If the SecKeyRef is invalid (e.g. has been released), then SecKeyGetBlockSize appears to return 0 length
    GUARD(keyLength != 0,
          @"Invalid SecKeyRef. Key block size is 0 bytes.");
    
    SecPadding secPaddingType = secPaddingFromQredoPaddingForPlainData(padding,keyLength,plainTextData);
    
    //Get a buffer of correct size for the specified key
    size_t outputDataLength = keyLength;
    NSMutableData *outputData = [NSMutableData dataWithLength:outputDataLength];
    
    OSStatus result = SecKeyEncrypt(keyRef, //key
                                    secPaddingType, //padding
                                    plainTextData.bytes, //plainText
                                    plainTextData.length, //plainTextLen
                                    outputData.mutableBytes, //cipherText
                                    &outputDataLength); //ciptherTextLen
    
    if (result != errSecSuccess){
        //Something went wrong, so return nil;
        QredoLogError(@"SecKeyEncrypt returned error: %@.",[QredoLogger stringFromOSStatus:result]);
        outputData = nil;
    }
    
    return outputData;
}


SecPadding secPaddingFromQredoPadding(QredoPadding padding) {
    SecPadding secPaddingType;
    
    switch (padding){
        case QredoPaddingNone:
            secPaddingType = kSecPaddingNone;
            break;
            
        case QredoPaddingOaep:
            secPaddingType = kSecPaddingOAEP;
            break;
            
        case QredoPaddingPkcs1:
            secPaddingType = kSecPaddingPKCS1;
            break;
            
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Invalid padding argument value (%u).",padding]
                                         userInfo:nil];
            break;
    }
    return secPaddingType;
}


SecPadding secPaddingFromQredoPaddingForPlainData(QredoPadding padding,size_t keyLength,NSData *plainTextData) {
    SecPadding secPaddingType;
    
    switch (padding){
        case QredoPaddingNone:
            
            //When no padding is selected, the plain text length must be same as key length
            GUARDF(plainTextData.length == keyLength,
                   @"Invalid data length (%lu) when no padding is requested. Input data must equal key length (%lu).",
                   (unsigned long)plainTextData.length,(unsigned long)keyLength);
            
            secPaddingType = kSecPaddingNone;
            break;
            
        case QredoPaddingOaep:
            
            //OAEP adds at least 2+(2*hash_size) bytes of padding, and total length cannot exceed key length.
            //Default OAEP MGF1 digest algorithm is SHA1 (20 byte output), so min 42 bytes padding. However
            //if a different algorithm is specified, then min padding will change.
            GUARDF(plainTextData.length + RSA_OAEP_MIN_PADDING_LENGTH <= keyLength,
                   @"Invalid data length (%lu) for provided key length (%lu) and OAEP padding. Default OAEP uses SHA1 so adds minimum 42 bytes "
                   @"padding. Maximum data to encrypt is (key_size - min_padding_size).",
                   (unsigned long)plainTextData.length, (unsigned long)keyLength);
            
            secPaddingType = kSecPaddingOAEP;
            break;
            
        case QredoPaddingPkcs1:
            
            //PKCS#1 v1.5 adds at least 11 bytes of padding, and total length cannot exceed key length.
            GUARDF(plainTextData.length + RSA_PKCS1_MIN_PADDING_LENGTH <= keyLength,
                   @"Invalid data length (%lu) for provided key length (%lu) and PKCS#1 v1.5 padding. PKCS#1 v1.5 adds minimum 11 bytes padding. "
                   @"Maximum data to encrypt is (key_size - min_padding_size).",
                   (unsigned long)plainTextData.length, (unsigned long)keyLength);
            
            secPaddingType = kSecPaddingPKCS1;
            break;
            
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Invalid padding argument value (%u).",padding]
                                         userInfo:nil];
            break;
    }
    return secPaddingType;
}



+(NSData *)rsaDecryptCipherTextData:(NSData *)cipherTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef {
    /*
     
     NOTE: When decrypting data, if the original plaintext had leading zeroes, these will be lost when
     decrypting.  The various PKCS#1.5/OAEP/PSS padding schemes include steps to restore the leading
     zeroes and so these work fine, e.g.
     "Convert the message representative m to an encoded message EM of length k-1 octets: EM = I2OSP (m, k-1)"
     
     However, if the caller is using QredoPaddingNone/kSecPaddingNone then the caller is responsible
     for restoring any leading zeroes, e.g.
     Create a buffer of keyLength and copy in the decryptedData to index 'keyLength - decryptedData.Length'
     
     */
    
    GUARD(cipherTextData,
          @"Cipher text data argument is nil");
    
    GUARD(keyRef,
          @"Key ref argument is nil");
    
    //Length of data to decrypt must equal key length
    size_t keyLength = SecKeyGetBlockSize(keyRef);
    
    GUARD(keyLength != 0,
          @"Invalid SecKeyRef. Key block size is 0 bytes.");
    
    GUARDF(cipherTextData.length == keyLength,
           @"Invalid data length (%lu). Input data must equal key length (%lu).",
           (unsigned long)cipherTextData.length, (unsigned long)keyLength);
    
    SecPadding secPaddingType;
    secPaddingType = secPaddingFromQredoPadding(padding);
    
    //Get a buffer of correct size for the specified key
    size_t outputDataLength = keyLength;
    NSMutableData *buffer = [NSMutableData dataWithLength:outputDataLength];
    
    OSStatus result = SecKeyDecrypt(keyRef, //key
                                    secPaddingType, //padding
                                    cipherTextData.bytes, //cipherText
                                    cipherTextData.length, //ciptherTextLen
                                    buffer.mutableBytes, //plainText
                                    &outputDataLength); //plainTextLen
    
    NSData *outputData = nil;
    
    if (result == errSecSuccess){
        //If padded, the output buffer may be larger than the decrypted data, so only return the correct portion
        NSRange outputRange = NSMakeRange(0,outputDataLength);
        outputData = [buffer subdataWithRange:outputRange];
    } else {
        QredoLogError(@"SecKeyDecrypt returned error: %@.",[QredoLogger stringFromOSStatus:result]);
    }
    
    return outputData;
}



@end
