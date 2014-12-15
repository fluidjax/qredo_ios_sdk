/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoKeychain;

@protocol QredoKeychainArchiver <NSObject>

- (BOOL)saveQredoKeychain:(QredoKeychain *)qredoKeychain forKey:(NSString *)key error:(NSError **)error;
- (QredoKeychain *)loadQredoKeychainForKey:(NSString *)key error:(NSError **)error;

@end


