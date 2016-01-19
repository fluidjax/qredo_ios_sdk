//
//  QredoLocalIndexCacheInvalidation.h
//  QredoSDK
//
//  Created by Christopher Morris on 13/01/2016.
//
//

#import <Foundation/Foundation.h>

@class QredoIndexVault;
@class QredoIndexVaultItem;
@class QredoIndexVaultItemMetadata;
@class QredoVaultItemMetadata;

@interface QredoLocalIndexCacheInvalidation : NSObject


@property (assign) long long maxCacheSize;

- (instancetype)initWithIndexVault:(QredoIndexVault *)qredoIndexVault  maxCacheSize:(long long)maxCacheSize;


//add Payload & Metadata size in bytes for a given IndexVaultItem to the total in qredoIndexVault
- (void)addSizeToTotals:(QredoIndexVaultItem *)qredoIndexVaultItem;

//remove Payload & Metadata size in bytes for a given IndexVaultItem to the total in qredoIndexVault
- (void)subtractSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem;

//Set the last accessed date for a VaultMetatDataIndex to now
- (void)updateAccessDate:(QredoIndexVaultItemMetadata *)indexVaultItemMetadata;

//The storage needed in sqllite (coredata) for the supplied dictionary of metadata
- (long)summaryValueByteCountSizeEstimator:(NSDictionary *)summaryValue;

//Estimate the size of the cache on disk based on the num records, and the size of the sum of the metadata & payloads
- (long long)totalCacheSizeEstimate;

@end
