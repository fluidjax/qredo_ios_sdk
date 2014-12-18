/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainArchiverForAppleKeychain.h"
#import "QredoKeychain.h"
#import "QredoErrorCodes.h"

static NSString *kUnderlyingErrorSource = @"Underlying error source";
static NSString *kUnderlyingErrorCode = @"Underlying error code";

static NSString *kCurrentService = @"CurrentService";

@implementation QredoKeychainArchiverForAppleKeychain

- (BOOL)saveQredoKeychain:(QredoKeychain *)qredoKeychain withIdentifier:(NSString *)identifier error:(NSError **)error {
    
    
    // Check whther we need to save or delete a keychain
    
    if (!qredoKeychain) {
        
        // Delete keychain
        
        OSStatus deleteSanityCheck = [self deleteQredoKeychainWithIdentifier:identifier error:error];
        if (deleteSanityCheck == noErr) {
            *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeSaved userInfo:
                      @{
                        kUnderlyingErrorSource : @"SecItemDelete",
                        kUnderlyingErrorCode : @(deleteSanityCheck),
                        }
                      ];
            return NO;
        }
        return YES;
    }
    
    
    // Check if a keychin with the provided id exists and delete it if necessary
    
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [queryDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [queryDictionary setObject:identifier forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    [queryDictionary setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    
    CFDictionaryRef result = nil;
    OSStatus qureySanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(queryDictionary), (CFTypeRef *)&result);
    if (qureySanityCheck == noErr) {
        
        OSStatus deleteSanityCheck = [self deleteQredoKeychainWithIdentifier:identifier error:error];
        if (deleteSanityCheck != noErr) {
            *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeSaved userInfo:
                      @{
                        kUnderlyingErrorSource : @"SecItemDelete",
                        kUnderlyingErrorCode : @(deleteSanityCheck),
                        }
                      ];
            return NO;
        }
        
    } else if (qureySanityCheck != errSecItemNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeSaved userInfo:
                      @{
                        kUnderlyingErrorSource : @"SecItemCopyMatching",
                        kUnderlyingErrorCode : @(qureySanityCheck),
                        }
                      ];
        }
        return NO;
    }

    
    // Save the keychain
    
    NSData *keychainData = [qredoKeychain data];
    
    NSMutableDictionary *addDictionary = [[NSMutableDictionary alloc] init];
    [addDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [addDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [addDictionary setObject:identifier forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    [addDictionary setObject:keychainData forKey:(__bridge id<NSCopying>)(kSecValueData)];
    
    OSStatus sanityCheck = SecItemAdd((__bridge CFDictionaryRef)(addDictionary), NULL);
    if (sanityCheck != noErr) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeSaved userInfo:
                      @{
                        kUnderlyingErrorSource : @"SecItemAdd",
                        kUnderlyingErrorCode : @(sanityCheck),
                        }
                      ];
        }
        return NO;
    }
    
    return YES;
}

- (QredoKeychain *)loadQredoKeychainWithIdentifier:(NSString *)identifier error:(NSError **)error {
    
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [queryDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [queryDictionary setObject:identifier forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    [queryDictionary setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    [queryDictionary setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnData)];
    
    CFDictionaryRef result = nil;
    OSStatus sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(queryDictionary), (CFTypeRef *)&result);
    
    if (sanityCheck == errSecItemNotFound) {
        *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeFound userInfo:
                  @{
                    kUnderlyingErrorSource : @"SecItemCopyMatching",
                    kUnderlyingErrorCode : @(sanityCheck),
                    }
                  ];
        return nil;
    } else if (sanityCheck != noErr) {
        *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeRetrieved userInfo:
                  @{
                    kUnderlyingErrorSource : @"SecItemCopyMatching",
                    kUnderlyingErrorCode : @(sanityCheck),
                    }
                  ];
        return nil;
    }
    
    NSDictionary * resultDict = (__bridge NSDictionary *)result;
    NSData *keychainData = [resultDict objectForKey:(__bridge id)(kSecValueData)];
    if (!keychainData) {
        *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeRetrieved userInfo:
                  @{
                    kUnderlyingErrorSource : @"SecItemCopyMatching",
                    kUnderlyingErrorCode : @(sanityCheck),
                    }
                  ];
        return nil;
    }
    
    QredoKeychain *qredoKeychain = nil;
    
    @try {
        qredoKeychain = [[QredoKeychain alloc] initWithData:keychainData];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeRetrieved userInfo:
                  @{
                    kUnderlyingErrorSource : @"ParsingError",
                    }];
        qredoKeychain = nil;
    }
    @finally {
        if (!qredoKeychain) {
            *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeRetrieved userInfo:
                      @{
                        kUnderlyingErrorSource : @"ParsingError",
                        }];
        }
    }
    
    return qredoKeychain;
    
}

- (OSStatus)deleteQredoKeychainWithIdentifier:(NSString *)identifier error:(NSError **)error {
    
    NSMutableDictionary *addDictionary = [[NSMutableDictionary alloc] init];
    [addDictionary setObject: (__bridge id)kSecClassGenericPassword forKey: (__bridge id<NSCopying>)kSecClass];
    [addDictionary setObject:kCurrentService forKey:(__bridge id<NSCopying>)kSecAttrService];
    [addDictionary setObject:identifier forKey:(__bridge id<NSCopying>)kSecAttrAccount];
    
    return SecItemDelete((__bridge CFDictionaryRef)(addDictionary));
}

@end

