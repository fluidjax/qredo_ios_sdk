/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"

@implementation QredoVaultItemMetadata

+ (instancetype)vaultItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)descriptor
                                       dataType:(NSString *)dataType
                                     accessLevel:(QredoAccessLevel)accessLevel
                                        created:(NSDate*)created
                                  summaryValues:(NSDictionary *)summaryValues
{
    return [[self alloc] initWithDescriptor:descriptor dataType:dataType accessLevel:accessLevel created: created summaryValues:summaryValues];
}


+ (instancetype)vaultItemMetadataWithDataType:(NSString *)dataType
                                  accessLevel:(QredoAccessLevel)accessLevel
                                      created:(NSDate*)created
                                summaryValues:(NSDictionary *)summaryValues
{
    return [self vaultItemMetadataWithDescriptor:nil dataType:dataType accessLevel:accessLevel created: created summaryValues:summaryValues];
}

+ (instancetype)vaultItemMetadataWithDataType:(NSString *)dataType
                                  accessLevel:(QredoAccessLevel)accessLevel
                                 summaryValues:(NSDictionary *)summaryValues
{
   
    NSDate* created = [NSDate date];
    return [self vaultItemMetadataWithDataType:dataType accessLevel:accessLevel created: created summaryValues:summaryValues];
}


- (instancetype)initWithDescriptor:(QredoVaultItemDescriptor *)descriptor
                          dataType:(NSString *)dataType
                       accessLevel:(QredoAccessLevel)accessLevel
                           created:(NSDate*)created
                     summaryValues:(NSDictionary *)summaryValues
{
    self = [super init];
    if (!self) return nil;

    _descriptor = descriptor;
    _dataType = dataType;
    _accessLevel = accessLevel;
    _created = created;
    _summaryValues = summaryValues;

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[QredoVaultItemMetadata allocWithZone:zone] initWithDescriptor:self.descriptor
                                                                  dataType:self.dataType
                                                               accessLevel:self.accessLevel
                                                                   created:self.created
                                                             summaryValues:self.summaryValues];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[QredoMutableVaultItemMetadata allocWithZone:zone] initWithDescriptor:self.descriptor
                                                                         dataType:self.dataType
                                                                      accessLevel:self.accessLevel
                                                                          created:self.created
                                                                    summaryValues:self.summaryValues];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"QredoVaultItemMetadata: dataType=\"%@\", metadata values=%@", self.dataType, self.summaryValues];
}

@end


@implementation QredoMutableVaultItemMetadata

@dynamic descriptor, dataType, accessLevel, summaryValues;

- (void)setSummaryValue:(id)value forKey:(NSString *)key
{
    NSMutableDictionary *mutableSummaryValues = [self.summaryValues mutableCopy];
    if (!mutableSummaryValues) {
        if (value) {
            self.summaryValues = [NSDictionary dictionaryWithObject:value forKey:key];
        }
    }
    else {
        [mutableSummaryValues setObject:value forKey:key];
        self.summaryValues = mutableSummaryValues;
    }
}

@end