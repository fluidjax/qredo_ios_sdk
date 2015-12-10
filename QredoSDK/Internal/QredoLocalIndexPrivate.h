/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "Qredo.h"






@interface QredoLocalIndex : NSObject <QredoVaultObserver>


@property (readonly) NSManagedObjectContext *managedObjectContext;

- (instancetype)initWithVault:(QredoVault*)vault;

/** Put a metadata item into the local Index */
-(void)putItemWithMetadata:(QredoVaultItemMetadata *)newMetadata;

/** Get a the most recent metadata item (most recent based on sequence number) */
-(QredoVaultItemMetadata *)get:(QredoVaultItemDescriptor *)vaultItemDescriptor;



/** Enumerates through all vault items in the local index that match the predicate 
    The predicate search is performed on the QredoIndexSummaryValues object.

    eg. [NSPredicate predicateWithFormat:@"key='name' && value.string=='John'"];
        [NSPredicate predicateWithFormat:@"key='name' && value.string=='John'"];
    
    Value is matched against a sub field depending on specified type.
    Valid types are
            value.string    (an NSString)
            value.date      (as NSDate)
            value.number    (an NSNumber)
            value.data      (an NSData)
 
*/
-(void)enumerateSearch:(NSPredicate *)predicate
              withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block
      completionHandler:(void(^)(NSError *error))completionHandler;





/** Synchronize the local Index with all items on the server 
 returns a count of how many items were imported */
-(void)syncIndexWithCompletion:(void(^)(int syncCount, NSError *error))completion;



/** Count of how many metadata items in the index */
-(NSInteger)count;

/** Delete all items in the cache */
-(void)purge;
-(void)purgeAllVaults;

-(BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor;
-(BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError*)returnError;

-(void)dump:(NSString*)message;

@end