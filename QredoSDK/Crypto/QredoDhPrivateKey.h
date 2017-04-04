/* HEADER GOES HERE */

#import <Foundation/Foundation.h>
#import "QredoPrivateKey.h"

@interface QredoDhPrivateKey :QredoPrivateKey

@property (nonatomic,copy,readonly) NSData *data;

-(instancetype)initWithData:(NSData *)data;

@end
