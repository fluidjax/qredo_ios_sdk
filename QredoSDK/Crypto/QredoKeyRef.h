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
-(BOOL)isEqual:(id)other;

@end
