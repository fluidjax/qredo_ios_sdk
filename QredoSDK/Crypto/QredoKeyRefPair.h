/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/




@class QredoKeyRef;
@class QredoKey;

#import <Foundation/Foundation.h>

@interface QredoKeyRefPair : NSObject

@property (strong) QredoKeyRef *publicKeyRef;
@property (strong) QredoKeyRef *privateKeyRef;


+(instancetype)keyPairWithPublic:(QredoKey*)public private:(QredoKey*)private;
@end
