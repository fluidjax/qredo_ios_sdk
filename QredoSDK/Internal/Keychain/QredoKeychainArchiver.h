/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@class QredoKeychain;

@protocol QredoKeychainArchiver <NSObject>

-(BOOL)saveQredoKeychain:(QredoKeychain *)qredoKeychain withIdentifier:(NSString *)identifier error:(NSError **)error;
-(QredoKeychain *)loadQredoKeychainWithIdentifier:(NSString *)identifier error:(NSError **)error;
-(BOOL)hasQredoKeychainWithIdentifier:(NSString *)identifier error:(NSError **)error;

@end


@interface QredoKeychainArchivers :NSObject
+(id<QredoKeychainArchiver>)defaultQredoKeychainArchiver;
@end
