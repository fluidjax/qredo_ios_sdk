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


-(void)delete:(QredoVaultItemDescriptor *)vaultItemDescriptor;

-(NSArray *)find:(NSPredicate *)predicate;


-(void)enumerateAllItems;
-(void)sync;
-(void)purge;
-(void)addListener;
-(void)removeListener;


@end