//
//  QredoAESKey.h
//  QredoSDK
//
//  Created by Christopher Morris on 04/08/2017.
//
//

#import <Foundation/Foundation.h>
#import "QredoKey.h"

@interface QredoAESKey : QredoKey

@property (nonatomic,readonly,copy) NSData *serializa;
-(instancetype)initWithKeyData:(NSData *)keydata;

@end
