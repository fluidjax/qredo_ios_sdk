/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoVaultItem+Cache.h"



@implementation QredoVaultItemDescriptor (Cache)

- (NSString *)cacheKey
{
    return [NSString stringWithFormat:@"%@-%llu", self.sequenceId.QUIDString, self.sequenceValue];
}

@end

@implementation QLFEncryptedVaultItem (Coding)

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSData *marshalledData = [QredoPrimitiveMarshallers marshalObject:self includeHeader:YES];
    [aCoder encodeDataObject:marshalledData];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSData *marshalledData = [aDecoder decodeDataObject];

    return [QredoPrimitiveMarshallers unmarshalObject:marshalledData
                                         unmarshaller:QLFEncryptedVaultItem.unmarshaller
                                          parseHeader:YES];
}

@end

@implementation QLFEncryptedVaultItemHeader (Coding)

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSData *marshalledData = [QredoPrimitiveMarshallers marshalObject:self includeHeader:YES];
    [aCoder encodeDataObject:marshalledData];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSData *marshalledData = [aDecoder decodeDataObject];

    return [QredoPrimitiveMarshallers unmarshalObject:marshalledData
                                         unmarshaller:QLFEncryptedVaultItemHeader.unmarshaller
                                          parseHeader:YES];
}

@end
