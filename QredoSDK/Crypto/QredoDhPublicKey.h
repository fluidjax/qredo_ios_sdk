/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoPublicKey.h"

@interface QredoDhPublicKey :QredoPublicKey

@property (nonatomic,copy,readonly) NSData *data;

-(instancetype)initWithData:(NSData *)data;

@end
