/* HEADER GOES HERE */


#import <Foundation/Foundation.h>
#import "QredoPublicKey.h"
#import "QredoPrivateKey.h"

@interface QredoKeyPair :NSObject

@property (nonatomic,strong,readonly) QredoPublicKey *publicKey;
@property (nonatomic,strong,readonly) QredoPrivateKey *privateKey;

-(instancetype)initWithPublicKey:(QredoPublicKey *)publicKey privateKey:(QredoPrivateKey *)privateKey;

@end
