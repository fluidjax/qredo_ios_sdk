/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainArchiver.h"
#import "QredoKeychainArchiverForAppleKeychain.h"


@implementation QredoKeychainArchivers

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    NSAssert1(FALSE, @"Class %@ may can not be instantiated", NSStringFromClass(self));
    return nil;
}

+ (instancetype)alloc {
    NSAssert1(FALSE, @"Class %@ may can not be instantiated", NSStringFromClass(self));
    return nil;
}

- (instancetype)init {
    NSAssert1(FALSE, @"Class %@ may can not be instantiated", NSStringFromClass([self class]));
    return nil;
}

+ (id<QredoKeychainArchiver>)defaultQredoKeychainArchiver {
    return [[QredoKeychainArchiverForAppleKeychain alloc] init];
}


@end

