/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"

@implementation QredoVaultItem

+(instancetype)vaultItemWithValue:(NSData *)value{
    return  [QredoVaultItem vaultItemWithMetadataDictionary:[NSDictionary dictionary] value:value];
}

+ (instancetype)vaultItemWithMetadataDictionary:(NSDictionary *)metadataDictionary value:(NSData *)value{
    QredoVaultItemMetadata *vaultItemMetadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:@"" accessLevel:0 summaryValues:metadataDictionary];
    return [[QredoVaultItem alloc] initWithMetadata:vaultItemMetadata value:value];
}


+ (instancetype)vaultItemWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value{
    return [[QredoVaultItem alloc] initWithMetadata:metadata value:value];
}




- (instancetype)initWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value{
    self = [super init];
    if (!self) return nil;
    _metadata = metadata;
    _value = value;

    return self;
}



-(id)objectForMetadataKey:(NSString*)key{
    return [_metadata objectForMetadataKey:key];
}

-(NSString*)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    [desc appendFormat:@"%@", self.metadata];
    return [desc copy];
}

@end



