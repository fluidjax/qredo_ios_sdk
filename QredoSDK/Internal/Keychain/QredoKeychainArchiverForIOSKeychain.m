/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainArchiverForIOSKeychain.h"
#import "QredoKeychain.h"


static NSString *kCurrentService = @"CurrentService";

@implementation QredoKeychainArchiverForIOSKeychain

- (BOOL)saveQredoKeychain:(QredoKeychain *)qredoKeychain forKey:(NSString *)key error:(NSError **)error {
    
    if (!qredoKeychain) {
        return [self deleteQredoKeychainWithKey:key error:error];
    }
    
    NSData *keychainData = [qredoKeychain data];
    
    
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [queryDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [queryDictionary setObject:key forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    [queryDictionary setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    
    CFDictionaryRef result = nil;
    OSStatus qureySanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(queryDictionary), (CFTypeRef *)&result);
    if (qureySanityCheck == noErr)
    {
        [self deleteQredoKeychainWithKey:key error:error];
    }

    NSMutableDictionary *addDictionary = [[NSMutableDictionary alloc] init];
    [addDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [addDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [addDictionary setObject:key forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    [addDictionary setObject:keychainData forKey:(__bridge id<NSCopying>)(kSecValueData)];
    
    OSStatus sanityCheck = SecItemAdd((__bridge CFDictionaryRef)(addDictionary), NULL);
    if (sanityCheck != noErr)
    {
        // TODO [GR]: Add error handling.
        return NO;
    }
    
    return YES;
}

- (QredoKeychain *)loadQredoKeychainForKey:(NSString *)key error:(NSError **)error {
    
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [queryDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [queryDictionary setObject:key forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    [queryDictionary setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    [queryDictionary setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnData)];
    
    CFDictionaryRef result = nil;
    OSStatus sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(queryDictionary), (CFTypeRef *)&result);
    if (sanityCheck != noErr)
    {
        // TODO [GR]: Add error handling.
        return nil;
    }
    
    NSDictionary * resultDict = (__bridge NSDictionary *)result;
    NSData *keychainData = [resultDict objectForKey:(__bridge id)(kSecValueData)];
    if (!keychainData) {
        // TODO [GR]: Add error handling.
        return nil;
    }
    
    QredoKeychain *qredoKeychain = [[QredoKeychain alloc] initWithData:keychainData];
    return qredoKeychain;
    
}

- (BOOL)deleteQredoKeychainWithKey:(NSString *)key error:(NSError **)error {
    
    NSMutableDictionary *addDictionary = [[NSMutableDictionary alloc] init];
    [addDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [addDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [addDictionary setObject:key forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    
    OSStatus sanityCheck = SecItemDelete((__bridge CFDictionaryRef)(addDictionary));
    if (sanityCheck != noErr)
    {
        // TODO [GR]: Add error handling.
        return NO;
    }
    
    return YES;

}

@end


