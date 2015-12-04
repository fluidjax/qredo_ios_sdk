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

+(id)sharedQredoLocalIndex;

-(void)putItemWithMetadata:(QredoVaultItemMetadata *)metadata;
-(void)putItem:(QredoVaultItem *)vaultItem;
-(QredoVaultItemMetadata *)get:(QredoVaultItemDescriptor *)vaultItemDescriptor;

-(void)enumerateSearch:(NSPredicate *)predicate
              withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block
      completionHandler:(void(^)(NSError *error))completionHandler;


- (void)enumerateCurrentSearch:(NSPredicate *)predicate
                     withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block
             completionHandler:(void(^)(NSError *error))completionHandler;


-(void)delete:(QredoVaultItemDescriptor *)vaultItemDescriptor;



-(void)sync;
-(void)purge;
-(void)addListener;
-(void)removeListener;


@end