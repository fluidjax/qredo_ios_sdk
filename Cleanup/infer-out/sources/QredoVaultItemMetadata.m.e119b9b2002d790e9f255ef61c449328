/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndex.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexSummaryValues.h"
#import "QredoNetworkTime.h"

@implementation QredoVaultItemMetadata

+(instancetype)vaultItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)descriptor
                                       dataType:(NSString *)dataType
                                        created:(NSDate*)created
                                  summaryValues:(NSDictionary *)summaryValues{
    return [[self alloc] initWithDescriptor:descriptor dataType:dataType accessLevel:0 created: created summaryValues:summaryValues];
}


+(instancetype)vaultItemMetadataWithDataType:(NSString *)dataType
                                      created:(NSDate*)created
                                summaryValues:(NSDictionary *)summaryValues{
    return [self vaultItemMetadataWithDescriptor:nil dataType:dataType  created: created summaryValues:summaryValues];
}


+(instancetype)vaultItemMetadataWithSummaryValues:(NSDictionary *)summaryValues{
   NSDate* created = [QredoNetworkTime dateTime];
    return [self vaultItemMetadataWithDataType:@"" created: created summaryValues:summaryValues];
}


+(instancetype)vaultItemMetadataWithIndexMetadata:(QredoIndexSummaryValues*)summaryValue{
    QredoIndexVaultItemMetadata *indexMetadata = summaryValue.vaultMetadata;
    return  [indexMetadata buildQredoVaultItemMetadata];
}


-(id)objectForMetadataKey:(NSString*)key{
    return [_summaryValues objectForKey:key];
}


-(instancetype)initWithDescriptor:(QredoVaultItemDescriptor *)descriptor
                          dataType:(NSString *)dataType
                       accessLevel:(QredoAccessLevel)accessLevel
                           created:(NSDate*)created
                     summaryValues:(NSDictionary *)summaryValues{
    self = [super init];
    if (!self) return nil;

    _descriptor = descriptor;
    _dataType = dataType;
    _accessLevel = accessLevel;
    _created = created;
    _summaryValues = summaryValues;

    return self;
}


-(id)copyWithZone:(NSZone *)zone{
    return [[QredoVaultItemMetadata allocWithZone:zone] initWithDescriptor:self.descriptor
                                                                  dataType:self.dataType
                                                               accessLevel:self.accessLevel
                                                                   created:self.created
                                                             summaryValues:self.summaryValues];
}


-(id)mutableCopyWithZone:(NSZone *)zone{
    return [[QredoMutableVaultItemMetadata allocWithZone:zone] initWithDescriptor:self.descriptor
                                                                         dataType:self.dataType
                                                                      accessLevel:self.accessLevel
                                                                          created:self.created
                                                                    summaryValues:self.summaryValues];
}


-(NSString *)description{
    return [NSString stringWithFormat:@"QredoVaultItemMetadata: dataType=\"%@\", metadata values=%@", self.dataType, self.summaryValues];
}


-(BOOL)isDeleted{
    if ([self.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone])return YES;
    return NO;
}

@end


@implementation QredoMutableVaultItemMetadata

@dynamic descriptor, dataType, accessLevel, summaryValues;

-(void)setSummaryValue:(id)value forKey:(NSString *)key{
    NSMutableDictionary *mutableSummaryValues = [self.summaryValues mutableCopy];
    if (!mutableSummaryValues) {
        if (value) {
            self.summaryValues = [NSDictionary dictionaryWithObject:value forKey:key];
        }
    }else{
        [mutableSummaryValues setObject:value forKey:key];
        self.summaryValues = mutableSummaryValues;
    }
}

@end
