//
//  QredoTestUtils.h
//  QredoSDK_nopods
//
//  Created by Gabriel Radu on 20/11/2014.
//
//

#import <Foundation/Foundation.h>

extern NSString *qtu_serviceURL;

@interface NSData (QredoTestUtils)

+ (NSData*)qtu_dataWithRandomBytesOfLength:(int)length;

@end

