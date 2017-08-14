//
//  QredoKeyRef.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import "QredoKeyRef.h"
#import "NSData+HexTools.h"

@interface QredoKeyRef()
@property (strong) NSData *data;

@end

@implementation QredoKeyRef




-(instancetype)initWithData:(NSData*)data;{
    self = [super init];
    if (self) {
        _data = [data copy];
    }
    return self;
}


-(NSData*)bytes{
    return self.data;
}


-(NSString*)hexadecimalString{
    return [self.data hexadecimalString];
}

@end
