/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoKeychain;

@protocol QredoKeychainArchiver <NSObject>

- (BOOL)saveQredoKeychain:(QredoKeychain *)qredoKeychain withIdentifier:(NSString *)identifier error:(NSError **)error;
- (QredoKeychain *)loadQredoKeychainWithIdentifier:(NSString *)identifier error:(NSError **)error;

@end


@interface QredoKeychainArchivers : NSObject
+ (id<QredoKeychainArchiver>)defaultQredoKeychainArchiver;
@end
