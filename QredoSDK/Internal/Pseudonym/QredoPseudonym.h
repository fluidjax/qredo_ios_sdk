//
//  QredoPseudonym.h
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

@class QredoSignedKey;
@class QredoRevocation;

#import <Foundation/Foundation.h>

@interface QredoPseudonym : NSObject


+ (QredoPseudonym *)create:(NSString *)localName;
+ (void)destroy:(QredoPseudonym *)pseudonym;
+ (bool)exists:(NSString *)localName;
+ (QredoPseudonym *)get:(NSString *)localName;
+ (NSArray *)list;
+ (void)put:(QredoPseudonym *)pseudonym;

- (NSString *)localName;
- (QredoSignedKey *)pubKey;
- (QredoRevocation *)revoke;
- (QredoPseudonym *)rotate:(QredoPseudonym *)old;
- (NSData *)sign:(NSData *)data;
- (bool)verify:(NSData *)data signature:(NSData *)signature;

@end
