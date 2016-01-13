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

-(void)addSizeToTotals:(QredoIndexVaultItem *)qredoIndexVaultItem;
-(void)subtractSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem;

- (void)updateAccessDate:(QredoIndexVaultItemMetadata *)indexVaultItemMetadata;


@end
