//
//  QredoCryptoKeychain.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import "QredoCryptoKeychain.h"
#import "QredoKey.h"
#import "Qredo.h"
#import "QredoBulkEncKey.h"
#import "QredoKeyRef.h"
#import "QredoKeyRefPair.h"
#import "UICKeyChainStore.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoRaw.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import "NSData+HexTools.h"
#import "QredoClient.h"
#import "QredoSigner.h"
#import "QLFOwnershipSignature+FactoryMethods.h"


@interface QredoCryptoKeychain()
@property (strong) UICKeyChainStore *keychainWrapper;
@property (strong) QredoCryptoImplV1 *cryptoImplementation;
@property (strong) NSMutableDictionary *keyDictionary;
@property (strong) NSMutableDictionary *memoizationStore;
@property (assign) int memoizationHit;
@property (assign) int memoizationTrys;
@end

@implementation QredoCryptoKeychain


#pragma Initialization

+(instancetype)standardQredoCryptoKeychain{
    static id standardQredoCryptoKeychainInstance = nil;
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        standardQredoCryptoKeychainInstance = [[self alloc] init];
    });
    return standardQredoCryptoKeychainInstance;
}


- (instancetype)init{
    self = [super init];
    if (self) {
        _keychainWrapper    = [UICKeyChainStore keyChainStoreWithService:@"Qredo.Crypto"];
        _cryptoImplementation = [QredoCryptoImplV1 sharedInstance];
        _keyDictionary      = [[NSMutableDictionary alloc] init];
        _memoizationStore   = [[NSMutableDictionary alloc] init];
        _memoizationHit     = 0;
        _memoizationTrys    = 0;
    }
    return self;
}

#pragma Encryption


-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext{
    QredoBulkEncKey *secretKey = [QredoBulkEncKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation encryptBulk:secretKey plaintext:plaintext];
}


-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext iv:(NSData*)iv{
    QredoBulkEncKey *secretKey = [QredoBulkEncKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation encryptBulk:secretKey plaintext:plaintext iv:iv];
}


-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext{
    QredoBulkEncKey *secretKey = [QredoBulkEncKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation decryptBulk:secretKey ciphertext:ciphertext];
}


-(NSData *)authenticate:(QredoKeyRef *)secretKeyRef data:(NSData *)data{
    QredoKey *secretKey = [QredoKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation getAuthCodeWithKey:secretKey data:data];
}


-(BOOL)verify:(QredoKeyRef *)secretKeyRef data:(NSData *)data signature:(NSData *)signature{
    QredoKey *secretKey = [QredoKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation verifyAuthCodeWithKey:secretKey data:data mac:signature];
}


#pragma User/Master Key Generation

-(QredoKeyRef *)deriveUserUnlockKeyRef:(NSData *)ikm{
    NSAssert(ikm,@"DeriveKey key should not be nil");
    QredoKeyRef *derivedKey = [self memoizeAndInvokeSelector:@selector(memoizedDeriveUserUnlockKeyRef:) withArguments:ikm, nil];
    return derivedKey;
}


-(QredoKeyRef *)memoizedDeriveUserUnlockKeyRef:(NSData *)ikm{
    QredoKey *derivedKey = [self.cryptoImplementation deriveSlow:ikm
                                                            salt:SALT_USER_UNLOCK
                                                      iterations:PBKDF2_USERUNLOCK_KEY_ITERATIONS];
    return [self createKeyRef:derivedKey];
}
    
    
    


-(QredoKeyRef *)deriveMasterKeyRef:(QredoKeyRef *)userUnlockKeyRef{
    
    NSData *ikm = [self retrieveWithRef:userUnlockKeyRef];
    NSAssert(ikm,@"DeriveKey key should not be nil");
    
    QredoKey *derivedKey = [self.cryptoImplementation deriveFast:ikm
                                                            salt:SALT_USER_MASTER
                                                            info:INFO_USER_MASTER
                                                    outputLength:MASTER_KEY_SIZE];
    return [self createKeyRef:derivedKey];
}



#pragma Key Derive/Generation


-(QredoKeyRef *)deriveKeyRef:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info{
    //derive_fast HKDF
    NSData *ikm = [self retrieveWithRef:keyRef];
    NSAssert(ikm,@"DeriveKey key should not be nil");
    NSAssert(salt,@"Salt should not be nil");
    QredoKey *derivedKey = [self.cryptoImplementation deriveFast:ikm salt:salt info:info outputLength:SHA256_DIGEST_SIZE];
    return [self createKeyRef:derivedKey];
}




-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt{
    //derive_slow PBKDF
    QredoKey *derivedKey = [self.cryptoImplementation deriveSlow:password  salt:salt iterations:10000];
    return [self createKeyRef:derivedKey];
}


-(QredoKeyRefPair *)generateDHKeyPair{
    QredoKeyPair *keyPair = [self.cryptoImplementation generateDHKeyPair];
    QredoKey *private = [QredoKey keyWithData:keyPair.privateKey.bytes];
    QredoKey *public  = [QredoKey keyWithData:keyPair.publicKey.bytes];
    QredoKeyRefPair *keyRefPair = [QredoKeyRefPair keyPairWithPublic:public private:private];
    return keyRefPair;
}


-(QredoKeyRefPair *)ownershipKeyPairDeriveRef:(QredoKeyRef *)ikmRef{
    //ed25519_sha512_derive
    NSData *ikm = [self retrieveWithRef:ikmRef];
    QredoED25519SigningKey *signKey = [self.cryptoImplementation qredoED25519SigningKeyWithSeed:ikm];
    QredoKey *private = [QredoKey keyWithData:signKey.data];
    QredoKey *public  = [QredoKey keyWithData:signKey.verifyKey.data];
    QredoKeyRefPair *keyRefPair =  [QredoKeyRefPair keyPairWithPublic:public private:private];
    return keyRefPair;
}


-(QredoQUID*)keyRefToQUID:(QredoKeyRef*)keyRef{
   NSData *keyData = [self retrieveWithRef:keyRef];
   return [QredoQUID QUIDWithData:keyData];
}


-(NSData*)publicKeyDataFor:(QredoKeyRefPair *)keyPair{
    //Return public key data in a KeyPair
    QredoKeyRef *publicKeyRef = keyPair.publicKeyRef;
    return [self retrieveWithRef:publicKeyRef];
}


-(NSString*)sha256FingerprintKeyRef:(QredoKeyRef*)keyRef{
    NSData *keyData = [self retrieveWithRef:keyRef];
    NSData *fp = [QredoCryptoRaw sha256:keyData];
    return [QredoUtils dataToHexString:fp];
}



-(QredoKeyRef *)generateDiffieHellmanMasterKeyWithMyPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                            yourPublicKeyRef:(QredoKeyRef *)yourPublicKeyRef{
    QredoKey *myPrivateKey = [QredoKey keyWithData:[self retrieveWithRef:myPrivateKeyRef]];
    QredoKey *yourPublicKey  = [QredoKey keyWithData:[self retrieveWithRef:yourPublicKeyRef]];
    QredoKey *diffieHellmanMaster = [self.cryptoImplementation generateDiffieHellmanMasterKeyWithMyPrivateKey:myPrivateKey
                                                                                           yourPublicKey:yourPublicKey];
    QredoKeyRef *keyRef = [self createKeyRef:diffieHellmanMaster];
    return keyRef;
}


-(NSData *)generateDiffieHellmanSecretWithSalt:(NSData *)salt
                             myPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey{
    NSData *diffieHellmanSecret = [self.cryptoImplementation generateDiffieHellmanSecretWithSalt:salt
                                                                               myPrivateKey:myPrivateKey
                                                                              yourPublicKey:yourPublicKey];
    return diffieHellmanSecret;
}


#pragma Qredo Lingua Franca

-(QredoED25519Signer *)qredoED25519SignerWithKeyRef:(QredoKeyRef*)keyref{
    NSData *keyData = [self retrieveWithRef:keyref];
    if (!keyData)return nil;
    QredoED25519SigningKey *key = [QredoED25519SigningKey keyWithData:keyData];
    return [[QredoED25519Signer alloc] initWithSigningKey:key];
}

-(QLFKeyPairLF *)newRequesterKeyPair {
    QredoKeyPair *keyPair = [self.cryptoImplementation generateDHKeyPair];
    QLFKeyLF *publicKeyLF  = [QLFKeyLF keyLFWithBytes:[(QredoDhPublicKey *)[keyPair publicKey]  data]];
    QLFKeyLF *privateKeyLF = [QLFKeyLF keyLFWithBytes:[(QredoDhPrivateKey *)[keyPair privateKey] data]];
    return [QLFKeyPairLF keyPairLFWithPubKey:publicKeyLF privKey:privateKeyLF];
}


-(QLFKeyPairLF *)keyPairLFWithPubKeyRef:(QredoKeyRef *)pubKeyRef privateKeyRef:(QredoKeyRef *)privateKeyRef{
    NSData *pubKeyData = [self retrieveWithRef:pubKeyRef];
    NSData *privKeyData = [self retrieveWithRef:privateKeyRef];
    return  [QLFKeyPairLF keyPairLFWithPubKey:[QLFKeyLF keyLFWithBytes:pubKeyData]
                                      privKey:[QLFKeyLF keyLFWithBytes:privKeyData]];
}


-(QLFVaultKeyPair *)vaultKeyPairWithEncryptionKey:(QredoKeyRef *)encryptionKeyRef privateKeyRef:(QredoKeyRef *)authenticationKeyRef{
    NSData *encData = [self retrieveWithRef:encryptionKeyRef];
    NSData *authData = [self retrieveWithRef:authenticationKeyRef];
    return  [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:encData authenticationKey:authData];
}


-(QLFRendezvousDescriptor *)rendezvousDescriptorWithTag:(NSString *)tag
                                              hashedTag:(QLFRendezvousHashedTag *)hashedTag
                                       conversationType:(NSString *)conversationType
                                     authenticationType:(QLFRendezvousAuthType *)authenticationType
                                        durationSeconds:(NSSet *)durationSeconds
                                              expiresAt:(NSSet *)expiresAt
                                     responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit
                                       requesterKeyPair:(QredoKeyRefPair *)requesterKeyPair
                                       ownershipKeyPair:(QredoKeyRefPair *)ownershipKeyPair{
    
    QLFKeyPairLF * requesterKeyPairQL = [self keyPairLFWithPubKeyRef:requesterKeyPair.publicKeyRef privateKeyRef:requesterKeyPair.privateKeyRef];
    QLFKeyPairLF * ownershipKeyPairQL = [self keyPairLFWithPubKeyRef:ownershipKeyPair.publicKeyRef privateKeyRef:ownershipKeyPair.privateKeyRef];
    
    return [QLFRendezvousDescriptor            rendezvousDescriptorWithTag:tag
                                                          hashedTag:hashedTag
                                                   conversationType:conversationType
                                                 authenticationType:authenticationType
                                                    durationSeconds:durationSeconds
                                                          expiresAt:expiresAt
                                                 responseCountLimit:responseCountLimit
                                                   requesterKeyPair:requesterKeyPairQL
                                                   ownershipKeyPair:ownershipKeyPairQL];
}


-(QLFConversationDescriptor *)conversationDescriptorWithRendezvousTag:(NSString *)rendezvousTag
                                                      rendezvousOwner:(BOOL)rendezvousOwner
                                                       conversationId:(QLFConversationId *)conversationId
                                                     conversationType:(NSString *)conversationType
                                                   authenticationType:(QLFRendezvousAuthType *)authenticationType
                                                       myPublicKeyRef:(QredoKeyRef *)myPublicKeyRef
                                                      myPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                                     yourPublicKeyRef:(QredoKeyRef *)yourPublicKey
                                                  myPublicKeyVerified:(BOOL)myPublicKeyVerified
                                                yourPublicKeyVerified:(BOOL)yourPublicKeyVerified{

    QLFKeyPairLF *myKey = [self keyPairLFWithPubKeyRef:myPublicKeyRef privateKeyRef:myPrivateKeyRef];
    QLFKeyLF *publicLFKey = [QLFKeyLF keyLFWithBytes:[self retrieveWithRef:yourPublicKey]];
    
    QLFConversationDescriptor *descriptor =
                            [QLFConversationDescriptor conversationDescriptorWithRendezvousTag:rendezvousTag
                                                                               rendezvousOwner:rendezvousOwner                                                                            conversationId:conversationId
                                                                              conversationType:conversationType
                                                                        authenticationType:authenticationType
                                                                                     myKey:myKey
                                                                             yourPublicKey:publicLFKey
                                                                       myPublicKeyVerified:myPublicKeyVerified
                                                                     yourPublicKeyVerified:yourPublicKeyVerified];
   return descriptor;
}



#pragma Keychain

-(QredoKeyRef*)createKeyRef:(QredoKey*)key{
    if (![key data])return nil;
    return [QredoKeyRef keyRefWithKeyData:[key data]];
}


-(void)addItem:(NSData*)keyData forRef:(NSData*)ref{
    if (![self.keyDictionary objectForKey:ref]){
        [self.keyDictionary setObject:keyData forKey:ref];
    }
    //Alternative (1/2) to store in the iOS Keychain instead of dictionary (significantly slower)
    //[self.keychainWrapper setData:keyData forKey:[ref hexadecimalString]];
}


-(NSData*)retrieveWithRef:(QredoKeyRef*)ref{
    return [self.keyDictionary objectForKey:ref.ref];
    //Alternative (2/2) to retriebe from iOS Keychain instead of dictionary (significantly slower)
    //return [self.keychainWrapper dataForKey:[ref hexadecimalString]];
}



#pragma Keychain comparison (used in testing)

-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToKeyRef:(QredoKeyRef*)keyRef2{
    NSData *key1 = [self retrieveWithRef:keyRef1];
    NSData *key2 = [self retrieveWithRef:keyRef2];
    return [key1 isEqual:key2];
}


-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToData:(NSData*)data{
    NSData *key1 = [self retrieveWithRef:keyRef1];
    return [key1 isEqual:data];
}



#pragma Memoization

-(id)memoizeAndInvokeSelector:(SEL)selector withArguments:(id)arguments, ... {
    self.memoizationTrys++;
    
    NSMutableArray *key = [[NSMutableArray alloc] init];
    NSNumber *selectorPointer = [NSNumber numberWithUnsignedLong:(uintptr_t)(void *)selector];
    [key addObject:selectorPointer];
    
    va_list args;
    va_start(args, arguments);
    for(id argument = arguments; argument != nil; argument = va_arg(args, id)) {
        [key addObject:argument];
    }
    va_end(args);
    id result = [self.memoizationStore objectForKey:key];
    
    if (!result){
        NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = selector;
        invocation.target = self;
        
        va_list args;
        va_start(args, arguments);
        NSUInteger index = 2;
        for(id argument = arguments; argument != nil; argument = va_arg(args, id)) {
            [self setArgument:argument atIndex:index++ inInvocation:invocation];
        }
        va_end(args);
        
        [invocation invoke];
        result = [self returnValueForMethodSignature:methodSignature withInvocation:invocation];
        [self.memoizationStore setObject:result forKey:key];

    }else{
        self.memoizationHit++;
    }
    return result;
}



- (void)setArgument:(id)object atIndex:(NSUInteger)index inInvocation:(NSInvocation *)invocation {
#define PULL_AND_SET(type, selector) \
do { \
type val = [object selector]; \
[invocation setArgument:&val atIndex:(NSInteger)index]; \
} while(0)
    
    const char *argType = [invocation.methodSignature getArgumentTypeAtIndex:index];
    // Skip const type qualifier.
    if(argType[0] == 'r') {
        argType++;
    }
    
    if(strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        [invocation setArgument:&object atIndex:(NSInteger)index];
    }else if(strcmp(argType, @encode(char)) == 0)               {PULL_AND_SET(char, charValue);
    }else if(strcmp(argType, @encode(int)) == 0)                {PULL_AND_SET(int, intValue);
    }else if(strcmp(argType, @encode(short)) == 0)              {PULL_AND_SET(short, shortValue);
    }else if(strcmp(argType, @encode(long)) == 0)               {PULL_AND_SET(long, longValue);
    }else if(strcmp(argType, @encode(long long)) == 0)          {PULL_AND_SET(long long, longLongValue);
    }else if(strcmp(argType, @encode(unsigned char)) == 0)      {PULL_AND_SET(unsigned char, unsignedCharValue);
    }else if(strcmp(argType, @encode(unsigned int)) == 0)       {PULL_AND_SET(unsigned int, unsignedIntValue);
    }else if(strcmp(argType, @encode(unsigned short)) == 0)     {PULL_AND_SET(unsigned short, unsignedShortValue);
    }else if(strcmp(argType, @encode(unsigned long)) == 0)      {PULL_AND_SET(unsigned long, unsignedLongValue);
    }else if(strcmp(argType, @encode(unsigned long long)) == 0) {PULL_AND_SET(unsigned long long, unsignedLongLongValue);
    }else if(strcmp(argType, @encode(float)) == 0)              {PULL_AND_SET(float, floatValue);
    }else if(strcmp(argType, @encode(double)) == 0)             {PULL_AND_SET(double, doubleValue);
    }else if(strcmp(argType, @encode(BOOL)) == 0)               {PULL_AND_SET(BOOL, boolValue);
    }else if(strcmp(argType, @encode(char *)) == 0){
        const char *cString = [object UTF8String];
        [invocation setArgument:&cString atIndex:(NSInteger)index];
    } else if(strcmp(argType, @encode(void (^)(void))) == 0) {
        [invocation setArgument:&object atIndex:(NSInteger)index];
    } else {
        NSCParameterAssert([object isKindOfClass:NSValue.class]);
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment([object objCType], &valueSize, NULL);
        
#if DEBUG
        NSUInteger argSize = 0;
        NSGetSizeAndAlignment(argType, &argSize, NULL);
        NSCAssert(valueSize == argSize, @"Value size does not match argument size in -setArgument: %@ atIndex: %lu", object, (unsigned long)index);
#endif
        unsigned char valueBytes[valueSize];
        [object getValue:valueBytes];
        [invocation setArgument:valueBytes atIndex:(NSInteger)index];
    }
    
#undef PULL_AND_SET
}

- (id)returnValueForMethodSignature:(NSMethodSignature *)methodSignature withInvocation:(NSInvocation *)invocation {
#define WRAP_AND_RETURN(type) \
do { \
type val = 0; \
[invocation getReturnValue:&val]; \
return @(val); \
} while (0)
    
    const char *returnType = methodSignature.methodReturnType;
    // Skip const type qualifier.
    if(returnType[0] == 'r') {
        returnType++;
    }
    
    if(strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0 || strcmp(returnType, @encode(void (^)(void))) == 0) {
        __autoreleasing id returnObj;
        [invocation getReturnValue:&returnObj];
        return returnObj;
    }else if(strcmp(returnType, @encode(char)) == 0)                 {WRAP_AND_RETURN(char);
    }else if(strcmp(returnType, @encode(int)) == 0)                  {WRAP_AND_RETURN(int);
    }else if(strcmp(returnType, @encode(short)) == 0)                {WRAP_AND_RETURN(short);
    }else if(strcmp(returnType, @encode(long)) == 0)                 {WRAP_AND_RETURN(long);
    }else if(strcmp(returnType, @encode(long long)) == 0)            {WRAP_AND_RETURN(long long);
    }else if(strcmp(returnType, @encode(unsigned char)) == 0)        {WRAP_AND_RETURN(unsigned char);
    }else if(strcmp(returnType, @encode(unsigned int)) == 0)         {WRAP_AND_RETURN(unsigned int);
    }else if(strcmp(returnType, @encode(unsigned short)) == 0)       {WRAP_AND_RETURN(unsigned short);
    }else if(strcmp(returnType, @encode(unsigned long)) == 0)        {WRAP_AND_RETURN(unsigned long);
    }else if(strcmp(returnType, @encode(unsigned long long)) == 0)   {WRAP_AND_RETURN(unsigned long long);
    }else if(strcmp(returnType, @encode(float)) == 0)                {WRAP_AND_RETURN(float);
    }else if(strcmp(returnType, @encode(double)) == 0)               {WRAP_AND_RETURN(double);
    }else if(strcmp(returnType, @encode(BOOL)) == 0)                 {WRAP_AND_RETURN(BOOL);
    }else if(strcmp(returnType, @encode(char *)) == 0)               {WRAP_AND_RETURN(const char *);
    }else if(strcmp(returnType, @encode(void)) == 0){
        return nil;
    }else{
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(returnType, &valueSize, NULL);
        unsigned char valueBytes[valueSize];
        [invocation getReturnValue:valueBytes];
        return [NSValue valueWithBytes:valueBytes objCType:returnType];
    }
#undef WRAP_AND_RETURN
    
}


-(float)memoizationHitRate{
    if (self.memoizationTrys==0)return 0.0;
    return (float)self.memoizationHit / (float)self. memoizationTrys;
}
    
@end

