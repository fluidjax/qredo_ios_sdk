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
#import "QredoKey.h"
#import "QredoQUID.h"

@interface QredoKeyRef()
@property (strong) NSData *ref;

@end

@implementation QredoKeyRef


-(instancetype)initWithKeyData:(NSData*)keyData{
    self = [self init];
    if (self) {
        QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
        QredoQUID *quid =  [[QredoQUID alloc] init];
        _ref = [[quid data] copy];
        [keychain addItem:keyData forRef:_ref];
    }
    return self;
}


-(NSString*)hexadecimalString{
    return [self.ref hexadecimalString];
}


#pragma Private Methods 
//These should be private for Testing Only as QredoKeyRef should not have access to the underlying Key data
//Access within live code should be via Keychain only




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
