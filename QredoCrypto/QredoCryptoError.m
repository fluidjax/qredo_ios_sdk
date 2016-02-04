/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoCryptoError.h"
#import "QredoLoggerPrivate.h"

NSString *const QredoCryptoErrorDomain = @"QredoCryptoError";

@implementation QredoCryptoError


#ifndef __clang_analyzer__ // Method gives false positive warning regarding NSError use

+ (void)populateError:(NSError **)error errorCode:(NSInteger)errorCode description:(NSString *)description
{
    QredoLogError(@"%@", description);
    if (error) {
        *error = [NSError errorWithDomain:QredoCryptoErrorDomain
                                     code:errorCode
                                 userInfo:@{NSLocalizedDescriptionKey: description}];
    }
}

#endif

+ (void)throwArgExceptionIf:(BOOL)condition reason:(NSString *)reason
{
    if (condition) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
    }
}

@end