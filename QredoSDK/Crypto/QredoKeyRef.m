//
//  QredoKeyRef.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import "QredoKeyRef.h"
#import "NSData+HexTools.h"
#import "QredoCryptoKeychain.h"
#import "QredoQUID.h"
#import "QredoRawCrypto.h"


#define  KEY_REF_INFO                 [@"QREDO_KEY_REF_INFO" dataUsingEncoding:NSUTF8StringEncoding]


@interface QredoKeyRef()
@property (strong) NSData *ref;

@end

@implementation QredoKeyRef


-(instancetype)initWithKeyData:(NSData*)keyData{
    self = [self init];
    if (self) {
        QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
        _ref = [self hKDFRefForKey:keyData];
        [keychain addItem:keyData forRef:_ref];
    }
    return self;
}


-(NSData*)hKDFRefForKey:(NSData*)key{
    //generate a Reference for a Key
    NSData *ref = [QredoRawCrypto hkdfSha256Expand:key info:KEY_REF_INFO outputLength:32];
    return ref;
}


-(instancetype)initWithKeyHexString:(NSString*)keyHexString{
    self = [self initWithKeyData:[NSData dataWithHexString:keyHexString]];;
    if (self) {
    }
    return self;
}


-(BOOL)isEqual:(id)other{
    if (other == self)return YES;
    if (!other || ![other isKindOfClass:[self class]])return NO;
    return [self isEqualToKey:other];
}

- (BOOL)isEqualToKey:(QredoKeyRef *)otherKeyRef {
    if (self == otherKeyRef)return YES;
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    return [keychain keyRef:self isEqualToKeyRef:otherKeyRef];
}






@end
