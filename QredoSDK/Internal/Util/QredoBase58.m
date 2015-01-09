/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoBase58.h"

static NSUInteger kAlphabetLength = 0;
static char kAlphabet[] = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
static const NSUInteger kIndexesLength  = 128;
static NSUInteger kIndexes[kIndexesLength];


//
// number -> number / 58, returns number % 58
//
unsigned char qredoBase58Divmod58(NSMutableData *number, NSUInteger startAt);

//
// number -> number / 256, returns number % 256
//
unsigned char qredoBase58Divmod256(NSMutableData *number58, NSUInteger startAt);



@implementation QredoBase58

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kAlphabetLength = strlen(kAlphabet);
        for (NSUInteger i = 0; i < kIndexesLength; i++) {
            kIndexes[i] = NSNotFound;
        }
        for (NSUInteger i = 0; i < kAlphabetLength; i++) {
            kIndexes[kAlphabet[i]] = i;
        }
    });
}

+ (NSString *)encodeData:(NSData *)data
{
    if ([data length] < 1) {
        return @"";
    }
    
    NSMutableData *input = [data mutableCopy];
    unsigned char *inputBytes = [input mutableBytes];
    const NSUInteger inputLength = [input length];
    
    // Count leading zeroes.
    NSUInteger zeroCount = 0;
    while (zeroCount < inputLength && inputBytes[zeroCount] == 0) {
        ++zeroCount;
    }
    
    // The actual encoding.
    NSMutableData *temp = [NSMutableData dataWithLength:inputLength*2];
    unsigned char *tempBytes = [temp mutableBytes];
    const NSUInteger tempLength = [temp length];
    
    NSUInteger j = tempLength;

    NSUInteger startAt = zeroCount;
    while (startAt < inputLength) {
        unsigned char mod = qredoBase58Divmod58(input, startAt);
        if (inputBytes[startAt] == 0) {
            ++startAt;
        }
        tempBytes[--j] = (unsigned char) kAlphabet[mod];
    }
    
    // Strip extra '1' if there are some after decoding.
    while (j < tempLength && tempBytes[j] == kAlphabet[0]) {
        ++j;
    }
    // Add as many leadding '1' as there were leading zeros.
    for (NSUInteger i = 0; i < zeroCount; i++) {
        tempBytes[--j] = (unsigned char)kAlphabet[0];
    }
    
    return [[NSString alloc] initWithData:temp encoding:NSASCIIStringEncoding];
}

+ (NSData *)decodeData:(NSString *)string
{
    if ([string length] < 1) {
        return [NSMutableData dataWithLength:1];
    }
    NSMutableData *input58 = [NSMutableData dataWithLength:[string length]];
    unsigned char *input58Bytes = [input58 mutableBytes];
    const NSUInteger input58Length = [input58 length];
    
    BOOL disallowedChar = NO;
    
    // Transform the string to a base58 byte sequence
    for (NSUInteger i = 0; i < [string length]; ++i) {
        
        unichar uc = [string characterAtIndex:i];
        if ((uc>>8) != 0) {
            disallowedChar = YES;
            break;
        }
        
        unsigned char c = (unsigned char)uc;
        NSUInteger digit58 = NSNotFound;
        if (c < kIndexesLength) {
            digit58 = kIndexes[c];
        }
        if (digit58 == NSNotFound) {
            disallowedChar = YES;
            break;
        }
        
        input58Bytes[i] = digit58;
    }
    
    if (disallowedChar) {
        return nil;
    }
    
    // Count leading zeros
    NSUInteger zeroCount = 0;
    while (zeroCount < input58Length && input58Bytes[zeroCount] == 0) {
        ++zeroCount;
    }
    
    // The encoding
    NSMutableData *temp = [NSMutableData dataWithLength:input58Length];
    unsigned char *tempBytes = [temp mutableBytes];
    const NSUInteger tempLength = [temp length];
    
    NSUInteger j = tempLength;
    
    NSUInteger startAt = zeroCount;
    while (startAt < input58Length) {
        
        unsigned char mod = qredoBase58Divmod256(input58, startAt);
        if (input58Bytes[startAt] == 0) {
            ++startAt;
        }
        
        tempBytes[--j] = mod;
    }
    
    // Do no add extra leading zeroes, move j to first non null byte.
    while (j < tempLength && tempBytes[j] == 0) {
        ++j;
    }
    
    NSUInteger resultStartIndex = j - zeroCount;
    return [NSData dataWithBytes:&tempBytes[resultStartIndex] length:tempLength-resultStartIndex];
}

@end



unsigned char qredoBase58Divmod58(NSMutableData *number, NSUInteger startAt)
{
    NSUInteger remainder = 0;
    unsigned char *numberBytes = [number mutableBytes];
    for (NSUInteger i = startAt; i < [number length]; i++) {
        NSUInteger digit256 = (NSUInteger)numberBytes[i] & 0xff;
        NSUInteger temp = remainder * 256 + digit256;
        numberBytes[i] = (unsigned char)(temp % 58);
        remainder = temp % 58;
    }
    return (unsigned char)remainder;
}


unsigned char qredoBase58Divmod256(NSMutableData *number58, NSUInteger startAt)
{
    NSUInteger remainder = 0;
    unsigned char *number58Bytes = [number58 mutableBytes];
    for (NSUInteger i = startAt; i < [number58 length]; i++) {
        NSUInteger digit58 = (NSUInteger)(number58Bytes[i] & 0xff);
        NSUInteger temp = remainder * 58 + digit58;
        number58Bytes[i] = (unsigned char)(temp / 256);
        remainder = temp % 256;
    }
    return (unsigned char)remainder;
}


