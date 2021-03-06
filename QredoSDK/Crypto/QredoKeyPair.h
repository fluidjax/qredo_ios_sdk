/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/




#import <Foundation/Foundation.h>
#import "QredoPublicKey.h"
#import "QredoPrivateKey.h"

@interface QredoKeyPair :NSObject

@property (nonatomic,strong,readonly) QredoPublicKey *publicKey;
@property (nonatomic,strong,readonly) QredoPrivateKey *privateKey;

-(instancetype)initWithPublicKey:(QredoPublicKey *)publicKey privateKey:(QredoPrivateKey *)privateKey;

@end
