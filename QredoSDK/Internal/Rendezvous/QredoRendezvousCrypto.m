/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <CommonCrypto/CommonDigest.h>
#import "QredoRendezvousCrypto.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoRaw.h"
#import "QredoRendezvousHelpers.h"
#import "QredoLoggerPrivate.h"
#import "QredoErrorCodes.h"
#import "QredoCryptoKeychain.h"

#define SALT_CONVERSATION_ID             [@"ConversationID" dataUsingEncoding:NSUTF8StringEncoding]

#define QREDO_RENDEZVOUS_MASTER_KEY_SALT [@"8YhZWIxieGYyW07D" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_HASHED_TAG_SALT [@"tAMJb4bJd60ufzHS" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_ENC_SALT        [@"QoR0rwQOu3PMCieK" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_AUTH_SALT       [@"FZHoqke4BfkIOfkH" dataUsingEncoding:NSUTF8StringEncoding]


@implementation QredoRendezvousCrypto {
    id<QredoCryptoImpl> _crypto;
}

+(QredoRendezvousCrypto *)instance {
    static QredoRendezvousCrypto *_instance = nil;
    
    @synchronized(self) {
        if (_instance == nil){
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}


-(id)init {
    self = [super init];
    
    if (self){
        _crypto = [QredoCryptoImplV1 new];
    }
    
    return self;
}


-(QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                     authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                   encryptedResponderData:(NSData *)encryptedResponderData {
    NSMutableData *payload = [NSMutableData dataWithData:[hashedTag data]];
    
    [payload appendData:encryptedResponderData];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain authenticate:authenticationKeyRef data:payload];
}


-(QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                                 authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                                responderPublicKeyRef:(QredoKeyRef *)responderPublicKeyRef {
    NSMutableData *payload = [NSMutableData dataWithData:[hashedTag data]];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    [payload appendData:[[QredoCryptoKeychain standardQredoCryptoKeychain] retrieveWithRef:responderPublicKeyRef]];
    return [keychain authenticate:authenticationKeyRef data:payload];
}


+(NSData *)transformPublicKeyToData:(SecKeyRef)key {
    NSString *const keychainTag = @"X509_KEY";
    NSData *publicKeyData;
    OSStatus putResult,delResult = noErr;
    
    //Params for putting the key first
    NSMutableDictionary *putKeyParams = [NSMutableDictionary new];
    
    putKeyParams[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    putKeyParams[(__bridge id)kSecAttrApplicationTag] = keychainTag;
    putKeyParams[(__bridge id)kSecValueRef] = (__bridge id)(key);
    putKeyParams[(__bridge id)kSecReturnData] = (__bridge id)(kCFBooleanTrue);   //Request the key's data to be returned too
    
    //Params for deleting the data
    NSMutableDictionary *delKeyParams = [[NSMutableDictionary alloc] init];
    delKeyParams[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    delKeyParams[(__bridge id)kSecAttrApplicationTag] = keychainTag;
    delKeyParams[(__bridge id)kSecReturnData] = (__bridge id)(kCFBooleanTrue);
    
    //Put the key
    putResult = SecItemAdd((__bridge CFDictionaryRef)putKeyParams,(void *)&publicKeyData);
    //Delete the key
    delResult = SecItemDelete((__bridge CFDictionaryRef)(delKeyParams));
    
    if ((putResult != errSecSuccess) || (delResult != errSecSuccess)){
        publicKeyData = nil;
    }
    
    return publicKeyData;
}



-(BOOL)validateEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
                 authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                  tag:(NSString *)tag
                            hashedTag:(QLFRendezvousHashedTag *)hashedTag
                                error:(NSError **)error {
    QLFRendezvousAuthType *authenticationType = encryptedResponderInfo.authenticationType;
    QLFAuthenticationCode *authenticationCode = encryptedResponderInfo.authenticationCode;
    NSData *encryptedResponderData = encryptedResponderInfo.value;
    
    id<QredoRendezvousRespondHelper> rendezvousHelper = [self rendezvousHelperForAuthType:authenticationType
                                                                                  fullTag:tag
                                                                                    error:error];
    
    NSData *calculatedAuthenticationCode
    = [self authenticationCodeWithHashedTag:hashedTag
                          authenticationKeyRef:authenticationKeyRef
                     encryptedResponderData:encryptedResponderData];
    
    BOOL isValidAuthCode = [QredoCryptoRaw constantEquals:calculatedAuthenticationCode rhs:authenticationCode];
    
    __block BOOL isValidSignature = NO;
    [authenticationType ifRendezvousAnonymous:^{
        isValidSignature = YES;
    }
                          ifRendezvousTrusted:^(QLFRendezvousAuthSignature *signature) {
                              if (rendezvousHelper == nil){
                                  isValidSignature = NO;
                              } else {
                                  NSData *rendezvousData = authenticationCode;
                                  isValidSignature = [rendezvousHelper isValidSignature:signature
                                                                         rendezvousData:rendezvousData
                                                                                  error:error];
                              }
                          }];
    
    return isValidAuthCode && isValidSignature;
}


-(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)tag
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error {
    return [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:authenticationType
                                                                 fullTag:tag
                                                                  crypto:_crypto
                                                          signingHandler:signingHandler
                                                                   error:error];
}


-(id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthType:(QLFRendezvousAuthType *)authType
                                                       fullTag:(NSString *)tag
                                                         error:(NSError **)error {
    __block id<QredoRendezvousRespondHelper> rendezvousHelper = nil;
    
    
    if (authType == QredoRendezvousAuthenticationTypeAnonymous){
        rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                                 fullTag:tag
                                                                                  crypto:_crypto
                                                                                   error:error];
    }
    
    return rendezvousHelper;
}


-(QredoKeyRef *)masterKeyRefWithTag:(NSString *)tag appId:(NSString *)appId {
    NSAssert(appId,@"AppID should not be nil");
    NSString *compositeTag = [NSString stringWithFormat:@"%@%@",appId,tag];
    NSData *tagData = [compositeTag dataUsingEncoding:NSUTF8StringEncoding];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain derivePasswordKey:tagData salt:QREDO_RENDEZVOUS_MASTER_KEY_SALT];
}


-(QLFRendezvousHashedTag *)hashedTagWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    QredoKeyRef *keyRef = [keychain deriveKeyRef:masterKeyRef salt:QREDO_RENDEZVOUS_HASHED_TAG_SALT info:[NSData data]];
    return [keychain keyRefToQUID:keyRef];
}


-(QredoKeyRef *)encryptionKeyRefWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain deriveKeyRef:masterKeyRef salt:QREDO_RENDEZVOUS_ENC_SALT info:[NSData data]];
}


-(QredoKeyRef *)authenticationKeyRefWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain deriveKeyRef:masterKeyRef salt:QREDO_RENDEZVOUS_AUTH_SALT info:[NSData data]];
}


-(QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                           encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef
                                                      error:(NSError **)error {
    NSData *decryptedData;
    
    @try {
        NSData *encryptedResponderDataRaw
        = [QredoPrimitiveMarshallers unmarshalObject:encryptedResponderData
                                        unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                         parseHeader:YES];
        
        
        QredoCryptoKeychain *keyChain = [QredoCryptoKeychain standardQredoCryptoKeychain];
        
        decryptedData = [keyChain decryptBulk:encryptionKeyRef ciphertext:encryptedResponderDataRaw];
       
    } @catch (NSException *exception){
        QredoLogError(@"Failed to decode: %@",exception);
    }
    
    if (!decryptedData){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey:@"Failed to decrypt responder info"
                                                }];
        }
        
        return nil;
    }
    
    @try {
        QLFRendezvousResponderInfo *responderInfo =
        [QredoPrimitiveMarshallers unmarshalObject:decryptedData
                                      unmarshaller:[QLFRendezvousResponderInfo unmarshaller]
                                       parseHeader:NO];
        return responderInfo;
    } @catch (NSException *exception){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey:@"Failed to unmarshal decrypted data"
                                                }];
        }
        
        return nil;
    }
}


-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
               encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef {
    NSData *iv = [QredoCryptoRaw randomNonceAndZeroCounter];
    
    return [self encryptResponderInfo:responderInfo encryptionKeyRef:encryptionKeyRef iv:iv];
}


-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef
                             iv:(NSData *)iv {
    NSData *serializedResponderInfo = [QredoPrimitiveMarshallers marshalObject:responderInfo includeHeader:NO];
    
    NSData *encryptedResponderInfo = [[QredoCryptoKeychain standardQredoCryptoKeychain] encryptBulk:encryptionKeyRef plaintext:serializedResponderInfo];
    
    
    return [QredoPrimitiveMarshallers marshalObject:encryptedResponderInfo
                                         marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]
                                      includeHeader:YES];
}


@end
