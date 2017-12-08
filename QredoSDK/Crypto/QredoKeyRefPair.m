/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/




#import "QredoKeyRefPair.h"
#import "QredoKeyRef.h"
#import "QredoKey.h"

@implementation QredoKeyRefPair


+(instancetype)keyPairWithPublic:(QredoKey*)public private:(QredoKey*)private{
    return [[self alloc] initWithPublic:public private:private];
}


-(instancetype)initWithPublic:(QredoKey*)public private:(QredoKey*)private{
    self = [super init];
    if (self) {
        self.publicKeyRef =  [QredoKeyRef keyRefWithKeyData:[public data]];
        self.privateKeyRef = [QredoKeyRef keyRefWithKeyData:[private data]];
        
    }
    return self;
}




@end
