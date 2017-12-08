/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

//Domain used in NSError
extern NSString *const QredoCryptoErrorDomain;

@interface QredoCryptoError :NSObject

+(void)throwArgExceptionIf:(BOOL)condition reason:(NSString *)reason;

@end
