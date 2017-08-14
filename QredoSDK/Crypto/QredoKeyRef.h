//
//  QredoKeyRef.h
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import <Foundation/Foundation.h>

@interface QredoKeyRef : NSObject


-(instancetype)initWithData:(NSData*)data;
-(NSData*)bytes;
-(NSString*)hexadecimalString;

@end
