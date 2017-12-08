/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoVault.h"
#import "QredoClient.h"

@class QredoVaultKeys,QredoClient,QredoVaultCrypto,QredoVaultSequenceCache;

@interface QredoVaultServerAccess :NSObject

-(instancetype)initWithClient:(QredoClient *)client
                  vaultCrypto:(QredoVaultCrypto *)vaultCrypto
                   sequenceId:(QredoQUID *)sequenceId
                    vaultKeys:(QredoVaultKeys *)vaultKeys
           vaultSequenceCache:(QredoVaultSequenceCache *)vaultSequenceCache
             enumerationQueue:(dispatch_queue_t)enumerationQueue;


-(void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
           completionHandler:(void (^)(QredoVaultItem *vaultItem,NSError *error))completionHandler;

-(void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                   completionHandler:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,NSError *error))completionHandler;

-(void)putUpdateOrDeleteItem:(QredoVaultItem *)vaultItem
                      itemId:(QredoQUID *)itemId dataType:(NSString *)dataType
                     created:(NSDate *)created
               summaryValues:(NSDictionary *)summaryValues
           completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata,QLFEncryptedVaultItem *encryptedVaultItem,NSError *error))completionHandler;


-(void)enumerateVaultItemsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop))block
                   completionHandler:(void (^)(NSError *error))completionHandler
                    watermarkHandler:(void (^)(QredoVaultHighWatermark *watermark))watermarkHandler
                               since:(QredoVaultHighWatermark *)sinceWatermark
                consolidatingResults:(BOOL)shouldConsolidateResults;


@end
