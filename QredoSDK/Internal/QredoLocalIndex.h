//
//  QredoLocalIndex.h
//  QredoSDK
//
//  Created by Christopher Morris on 03/12/2015.
//
//
#import "Qredo.h"


@interface QredoLocalIndex : NSObject

@property (readonly) NSManagedObjectContext *managedObjectContext;

/** Returns the  Local Index singleton */
+(id)sharedQredoLocalIndex;

/** Put a metadata item into the local Index */
-(void)putItemWithMetadata:(QredoVaultItemMetadata *)metadata;

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


/** Enumerates through the most recent (based on SequenceValue) vault items in the local index that match the predicate */
- (void)enumerateCurrentSearch:(NSPredicate *)predicate
                     withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block
             completionHandler:(void(^)(NSError *error))completionHandler;


-(void)delete:(QredoVaultItemDescriptor *)vaultItemDescriptor;



-(void)sync;
-(void)purge;
-(void)addListener;
-(void)removeListener;


@end