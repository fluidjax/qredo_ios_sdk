/* HEADER GOES HERE */
#import "QredoKeychainArchiver.h"


@interface QredoKeychainArchiverForAppleKeychain :NSObject<QredoKeychainArchiver>

-(OSStatus)fixedSecItemCopyMatching:(CFDictionaryRef)query result:(CFTypeRef *)result;
@end
