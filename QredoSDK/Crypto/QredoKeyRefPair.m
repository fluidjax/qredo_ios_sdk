//
//  QredoKeyRefPair.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import "QredoKeyRefPair.h"
#import "QredoKeyRef.h"
#import "QredoKey.h"

@implementation QredoKeyRefPair



-(instancetype)initWithPublic:(QredoKey*)public private:(QredoKey*)private{
    self = [super init];
    if (self) {
        self.publicKeyRef =  [[QredoKeyRef alloc] initWithKeyData:[public data]];
        self.privateKeyRef = [[QredoKeyRef alloc] initWithKeyData:[private data]];
        
    }
    return self;
}




@end
