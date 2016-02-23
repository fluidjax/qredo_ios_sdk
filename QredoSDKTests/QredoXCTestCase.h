//
//  QredoXCTestCase.h
//  QredoSDK
//
//  Created by Christopher Morris on 22/01/2016.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoPrivate.h"

//#define QLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define QLog(...)


@interface QredoXCTestCase : XCTestCase


-(void)loggingOff;
-(void)loggingOn;


- (void)resetKeychain;
- (void)deleteAllKeysForSecClass:(CFTypeRef)secClass;

- (NSData*)randomDataWithLength:(int)length;
- (NSString *)randomStringWithLength:(int)len;


@end
