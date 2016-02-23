/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTypes.h"

@class QredoQUID;
@class QredoVault;
@class QredoVaultItemMetadata;
@class QredoIndexSummaryValues;
@class NSManagedObjectContext;



/** Represents state of the vault. An opaque class */
@interface QredoVaultHighWatermark :NSObject
@end

/** Points to the origin of the vault. If it is used in `[QredoVault enumerateVaultItemsUsingBlock:failureHandler:since:]`, then it will return all the items from the vault */
extern QredoVaultHighWatermark *const QredoVaultHighWatermarkOrigin;



@protocol QredoVaultObserver <NSObject>
-(void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata;
-(void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error;
@end



@interface QredoVaultItemDescriptor :NSObject
// assuming that vault id is known by QredoClient
@property (readonly) QredoQUID *sequenceId;
@property (readonly) QredoQUID *itemId;

// sequenceValue is not used, because in rev.1 there is no version control, then itemId should be enough for pointing to the correct vault item
+(instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId
                                          itemId:(QredoQUID *)itemId;

-(instancetype)initWithSequenceId:(QredoQUID *)sequenceId
                    sequenceValue:(int64_t)sequenceValue
                           itemId:(QredoQUID *)itemId;

-(BOOL)isEqual:(id)object;
@end


/** Immutable metadata. */
@interface QredoVaultItemMetadata :NSObject<NSCopying, NSMutableCopying>

@property (readonly) QredoVaultItemDescriptor *descriptor;
@property (readonly, copy) NSDate* created;
@property (readonly, copy) NSDictionary *summaryValues; // string -> string | NSNumber | QredoQUID



/** this constructor to be used externally when creating a new vault item to be stored in Vault */
+(instancetype)vaultItemMetadataWithSummaryValues:(NSDictionary *)summaryValues;

/** Converts an index coredata summaryValue object retrieved by an index search predicate into a QredoVaultItemMetadata */
+(instancetype)vaultItemMetadataWithIndexMetadata:(QredoIndexSummaryValues*)summaryValue;

-(id)objectForMetadataKey:(NSString*)key;

@end



/** Mutable metadata. */
@interface QredoMutableVaultItemMetadata :QredoVaultItemMetadata

@property QredoVaultItemDescriptor *descriptor;
@property (copy) NSDictionary *summaryValues; // string -> string | NSNumber | QredoQUID
-(void)setSummaryValue:(id)value forKey:(NSString *)key;

@end




@interface QredoVaultItem :NSObject
@property (readonly) QredoVaultItemMetadata *metadata;
@property (readonly) NSData *value;



/** Shortcut to creating a Vaultitem*/
+(instancetype)vaultItemWithValue:(NSData *)value;
+(instancetype)vaultItemWithMetadataDictionary:(NSDictionary *)metadataDictionary value:(NSData *)value;
+(instancetype)vaultItemWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value;
-(instancetype)initWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value;
-(id)objectForMetadataKey:(NSString *)key;
@end


/**
 @discussion constructor is private, as an external developer is not supposed to create an object of this class
 */
@interface QredoVault :NSObject

-(QredoQUID *)vaultId;

-(void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor completionHandler:(void (^)(QredoVaultItem *vaultItem, NSError *error))completionHandler;

-(void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor completionHandler:(void (^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler;

/**
 Adds an observer to the vault.
 
 @param observer The observer to be added.
 
 @discussion An observer should be added to the vault in order to receive notifications when
 items in the vault change. It is important to remove the added observer before it is deallocated.
 */
-(void)addVaultObserver:(id<QredoVaultObserver>)observer;

/**
 Removes an observer from the vault.
 
 @param observer The observer to be removed.
 
 @discussion An observer use this method to remove it self before being deallocated.
 */
-(void)removeVaultObserver:(id<QredoVaultObserver>)observer;

-(void)putItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler;

/** Requests meta data of all items from the server and calls `block` for each item. If an error occurs during the request, then `completionHandler` is called with NSError set, otherwise it gets called once enumeration complete. Enumeration starts from `QredoVaultHighWatermarkOrigin`, i.e. returning all items from the vault. If it is necessary to return items from certain point, use `enumerateVaultItemsUsingBlock:failureHandler:since:`
 
 @param block called for every item in the vault. If the block sets `YES` to `stop` then the enumeration will terminate.
 @param completionHandler is called when enumeration completed or if an error has occured during the communication to the server
 
 @discussion The method name is aligned with `[NSArray enumerateObjectsUsingBlock:]`, however, in our case this method may go to server to request the items
 */

-(void)enumerateVaultItemsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                   completionHandler:(void (^)(NSError *error))completionHandler;

-(void)enumerateVaultItemsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                               since:(QredoVaultHighWatermark*)sinceWatermark
                   completionHandler:(void (^)(NSError *error))completionHandler;


/** Deletes a vault item and returns it's metadata */
-(void)deleteItem:(QredoVaultItemMetadata *)metadata completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler;

/** High watermark of the Vault from which the updates will be arriving, when `startListening` is called. The watermark is persisted in `NSUserDefaults`. */
-(QredoVaultHighWatermark *)highWatermark;

/** If for some reason the client application needs to receive all items in the delegate after calling `startListening`, then this method can be called. */
-(void)resetWatermark;

@end


@interface QredoVault (LocalIndex)


typedef void (^ IncomingMetadataBlock)(QredoVaultItemMetadata *vaultMetadata);

/** Enumerates through all vault items in the local index that match the predicate
 The predicate search is performed on the QredoIndexSummaryValues object.
 
 eg. [NSPredicate predicateWithFormat:@"key='name' && value.string=='John'"];
 [NSPredicate predicateWithFormat:@"key=='name' && value.string=='John'"];
 
 Value is matched against a sub field depending on specified type.
 Valid types are
 value.string    (an NSString)
 value.date      (as NSDate)
 value.number    (an NSNumber)
 value.data      (an NSData)
 */

-(void)enumerateIndexUsingPredicate:(NSPredicate *)predicate
                          withBlock:(void (^)(QredoVaultItemMetadata *vaultMetadata, BOOL *stop))block
                  completionHandler:(void (^)(NSError *error))completionHandler;


/** Return the number of Metadata entries in the local Metadata index  */
-(int)indexSize;

/** Retrieves an NSManagedObjectContext (on main Thread) for the Coredata stack holding the index */
-(NSManagedObjectContext*)indexManagedObjectContext;

/** Caching of Vault Item Metadata is enabled by default, turning it off will turn off all caching & indexing  */
-(void)metadataCacheEnabled:(BOOL)metadataCacheEnabled;

/** Caching of VaultItem values is enabled by default, turning it off will force the value to be retrieved from the serve. Metadata caching is unaffected  */
-(void)valueCacheEnabled:(BOOL)valueCacheEnabled;

/** Returns the size in bytes of the cache/index coredata database
 Specifically to allow dynamic management of the caches if required in the case of an app which uses large (>a few gig) of storage. */
-(long long)cacheFileSize;

/**  Deletes all records in the Coredata Cache/Index for this vault */
-(void)purgeCache;

/** Set the maximum size in bytes of the local cache/index default is QREDO_DEFAULT_INDEX_CACHE_SIZE in Qredo.h */
-(void)setMaxCacheSize:(long long)maxSize;


@end


