/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@class QredoED25519SigningKey;

@protocol QredoSigner <NSObject>

@required
-(NSData *)signData:(NSData *)data error:(NSError **)error;

@end

@interface QredoED25519Singer :NSObject <QredoSigner>

-(instancetype)initWithSigningKey:(QredoED25519SigningKey *)signingKey;

@end

