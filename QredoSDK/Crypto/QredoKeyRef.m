/* HEADER GOES HERE */


#import "QredoKeyRef.h"
#import "NSData+HexTools.h"
#import "QredoCryptoKeychain.h"
#import "QredoQUID.h"
#import "QredoCryptoRaw.h"


#define  KEY_REF_INFO                 [@"QREDO_KEY_REF_INFO" dataUsingEncoding:NSUTF8StringEncoding]


@interface QredoKeyRef()
@property (strong) NSData *ref;

@end

@implementation QredoKeyRef



+(instancetype)keyRefWithKeyData:(NSData*)keyData{
    return [[self alloc] initWithKeyData:keyData];
}


+(instancetype)keyRefWithKeyHexString:(NSString*)keyHexString{
    return [[self alloc] initWithKeyHexString:keyHexString];
}


-(instancetype)initWithKeyData:(NSData*)keyData{
    self = [self init];
    if (self) {
        QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
        _ref = [self hKDFRefForKey:keyData];
        [keychain addItem:keyData forRef:_ref];
    }
    return self;
}

-(instancetype)initWithKeyHexString:(NSString*)keyHexString{
    self = [self initWithKeyData:[NSData dataWithHexString:keyHexString]];;
    if (self) {
    }
    return self;
}



-(NSData*)hKDFRefForKey:(NSData*)key{
    //generate a Reference for a Key
    NSData *ref = [QredoCryptoRaw hkdfSha256Expand:key info:KEY_REF_INFO outputLength:32];
    return ref;
}





-(BOOL)isEqual:(id)other{
    if (other == self)return YES;
    if (!other || ![other isKindOfClass:[self class]])return NO;
    return [self isEqualToKey:other];
}

- (BOOL)isEqualToKey:(QredoKeyRef *)otherKeyRef {
    if (self == otherKeyRef)return YES;
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain keyRef:self isEqualToKeyRef:otherKeyRef];
}






@end
