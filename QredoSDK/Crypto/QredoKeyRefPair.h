//
//  QredoKeyRefPair.h
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

@class QredoKeyRef;
@class QredoKey;

#import <Foundation/Foundation.h>

@interface QredoKeyRefPair : NSObject

@property (strong) QredoKeyRef *publicKeyRef;
@property (strong) QredoKeyRef *privateKeyRef;


-(instancetype)initWithPublic:(QredoKey*)public private:(QredoKey*)private;
@end
