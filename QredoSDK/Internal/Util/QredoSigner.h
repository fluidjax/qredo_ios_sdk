/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@class QredoED25519SigningKey;

@protocol QredoSigner <NSObject>

@required
-(NSData *)signData:(NSData *)data error:(NSError **)error;

@end

@interface QredoED25519Signer :NSObject <QredoSigner>

-(instancetype)initWithSigningKey:(QredoED25519SigningKey *)signingKey;

@end

