/* HEADER GOES HERE */


@class QredoKeyRef;
@class QredoKey;

#import <Foundation/Foundation.h>

@interface QredoKeyRefPair : NSObject

@property (strong) QredoKeyRef *publicKeyRef;
@property (strong) QredoKeyRef *privateKeyRef;


+(instancetype)keyPairWithPublic:(QredoKey*)public private:(QredoKey*)private;
@end
