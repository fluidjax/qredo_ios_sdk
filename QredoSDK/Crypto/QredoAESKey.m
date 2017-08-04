//
//  QredoAESKey.m
//  QredoSDK
//
//  Created by Christopher Morris on 04/08/2017.
//
//

#import "QredoAESKey.h"

@interface QredoAESKey ()
@property (nonatomic,copy) NSData *data;
@end


@implementation QredoAESKey


-(instancetype)initWithKeyData:(NSData *)data {
    self = [self init];
    
    if (self){
        _data = data;
    }
    
    return self;
}


-(NSData *)serialize {
    return _data;
}

@end
