/* HEADER GOES HERE */
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
