/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoKeychainArchiver.h"


@interface QredoKeychainArchiverForAppleKeychain :NSObject<QredoKeychainArchiver>

-(OSStatus)fixedSecItemCopyMatching:(CFDictionaryRef)query result:(CFTypeRef *)result;
@end
