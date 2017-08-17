//
//  QredoKeyRef.h
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import <Foundation/Foundation.h>

@interface QredoKeyRef : NSObject


-(instancetype)initWithKeyData:(NSData*)keyData;
-(instancetype)initWithKeyHexString:(NSString*)keyHexString;

-(NSData*)ref;
-(NSString*)hexadecimalString;
-(BOOL)isEqual:(id)other;


//only for debugging
-(void)dump;
-(NSData*)debugValue;

@end
