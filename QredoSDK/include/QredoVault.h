/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTypes.h"

@class QredoQUID;
@class QredoVault;
@class QredoVaultItemMetadata;
@class QredoIndexSummaryValues;
@class NSManagedObjectContext;


/** Used to represent the state of the Vault. This is the mark to search from when enumerating VaultItems
 
 Pass this as a parameter to `enumerateVaultItemsUsingBlock` */

@interface QredoVaultHighWatermark :NSObject
@end

/** Points to the start of the Vault */
extern QredoVaultHighWatermark *const QredoVaultHighWatermarkOrigin;


/** The protocol that must implemented by the object that listens for new items added to the Vault
 
 @see Vault listeners: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/vault_listeners.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/vault_listeners.html)
 
 */

@protocol QredoVaultObserver <NSObject>

/**
 Invoked when a new item is added to the Vault on this or another device
 
 @param client The Vault the item has been added to
 @param itemMetadata The metadata of the item added. This can be used to retrieve the vault item data.
 
 @note this method must be implemented
 */
-(void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata;


/**
 Invoked when a failure occurs
 
 @param error The error
 */

-(void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error;
@end


/** Identifies a vault item. Developers do not create this objects directly. Stored in the `QredoVaultItemMetadata` 
 
 Used to retrieve a vault item with `getItemWithDescriptor` and the metadata with `getItemMetadataWithDescriptor`
 */

@interface QredoVaultItemDescriptor :NSObject

/** Device specific value*/
@property (readonly) QredoQUID *sequenceId;
/** Unique identifier for the vault item*/
@property (readonly) QredoQUID *itemId;

/** Used internally*/
+(instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId
                                          itemId:(QredoQUID *)itemId;
/** Used internally*/
-(instancetype)initWithSequenceId:(QredoQUID *)sequenceId
                    sequenceValue:(int64_t)sequenceValue
                           itemId:(QredoQUID *)itemId;

/** @return YES if the two descriptors are the same*/
-(BOOL)isEqual:(id)object;
@end


/** Information about a vault item. These properties are read only.
Constructed when a 'QredoVaultItem` is created and returned from `enumerateVaultItemsUsingBlock` */
@interface QredoVaultItemMetadata :NSObject<NSCopying, NSMutableCopying>

#pragma mark - Properties

/** The `QredoVaultItemDescriptor` used to retrieve an item from the Vault with `getItemWithDescriptor` and `getItemMetadataWithDescriptor`  */
@property (readonly) QredoVaultItemDescriptor *descriptor;

/** The date and time that the item was created, in UTC format  */
@property (readonly, copy) NSDate* created;

/** The metadata dictionary stored as a dictionary of key/ value pairs 
 @note The summaryValues can contain anything you like, but must be of one of `NSNumber`, `NSDate` or `NSString`
 */
 @property (readonly, copy) NSDictionary *summaryValues;

#pragma mark - Methods

/** Construct the metadata with the specified summary values 
 @param summaryValues a dictionary of key/value pairs
 @return the newly created metadata
 
 @see Adding an item to the Vault: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/adding_an_item_to_the_vault.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/adding_an_item_to_the_vault.html)
 
 */
+(instancetype)vaultItemMetadataWithSummaryValues:(NSDictionary *)summaryValues;

/** Converts an index coredata summaryValue object retrieved by an index search predicate into a `QredoVaultItemMetadata` 
 @note You only need to call this function if you are accessing the `NSManagedObjectContext` directly.
 @see The CustomerLookup example app
 */
+(instancetype)vaultItemMetadataWithIndexMetadata:(QredoIndexSummaryValues*)summaryValue;


/** Returns the metadata dictionary object referred to by the specified key
 @param key The key to lookup
 @return The object stored under this key. nil if the key cannot be found
 */
-(id)objectForMetadataKey:(NSString*)key;

@end



/** Mutable metadata. 
 
 Used to construct the updated metadata to pass to [updateItem](#/c:objc(cs)QredoVault(im)updateItem:completionHandler:)
*/
 
@interface QredoMutableVaultItemMetadata :QredoVaultItemMetadata

/** The `QredoVaultItemDescriptor` used to retrieve an item from the Vault with `getItemWithDescriptor` and `getItemMetadataWithDescriptor`  */
@property QredoVaultItemDescriptor *descriptor;
/** Editable version of the metadata dictionary  */
@property (copy) NSDictionary *summaryValues;
/** Set the value of the object with the specified key in the metadata dictionary  
 @param value The new value of the object
 @param key   The key representing the object to update */
-(void)setSummaryValue:(id)value forKey:(NSString *)key;

@end



/** Represents a VaultItem. Contains properties for the vault item's data and metadata
 
 @see Vault classes: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/vault_classes.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/vault_classes.html)
 
 */

@interface QredoVaultItem :NSObject

#pragma mark - Properties

/** The item metadata */
@property (readonly) QredoVaultItemMetadata *metadata;
/** The item value */
@property (readonly) NSData *value;

#pragma mark - Methods

/** Create and return a vault item with the specified data 
 
 @param value The data to set for the vault item
 @return The newly created vault item
 */
+(instancetype)vaultItemWithValue:(NSData *)value;

/** Create and return a vault item with the specified summary values and data
 
 @param metadataDictionary The dictionary of key/value pairs
 @param value The data to set for the vault item
 @return The newly created vault item
 */

+(instancetype)vaultItemWithMetadataDictionary:(NSDictionary *)metadataDictionary value:(NSData *)value;

/** Create and return a vault item with the specified metadata and data
 
 @param metadata The item's metadata
 @param value The data to set for the vault item
 @return The newly created vault item
 */

+(instancetype)vaultItemWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value;

/** Initialise the vault item with the specified metadata and data
 @param metadata the item's metadata
 @parama value the item's data */

-(instancetype)initWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value;


/** Search the metadata dictionary and return the object stored with the specified key 
 @param the key to search for
 @return the object stored with this key. Returns nil if no objects can be found with the specified key.
 */

-(id)objectForMetadataKey:(NSString *)key;
@end


/** Contains the methods to add, retrieve, search for and delete items in a Qredo Vault.
 
 Objects of this class are not constructed by the developer, but returned from the [defaultVault](QredoClient.html#/c:objc(cs)QredoClient(im)defaultVault) method
 */
@interface QredoVault :NSObject

/** Returns the id of this Vault. Not currently used */
-(QredoQUID *)vaultId;

#pragma mark - Retrieving Vault items

/** Retrieves the item with the given descriptor from the Vault 
 @param itemDescriptor The descriptor for the item to retrieve. This can be found in the `QredoVaultItemMetadata`
 @param completionHandler Returns the vaultItem or an error if it cannot be found or some other error occurs.
 @see Retrieving an item from the Vault: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html)
*/

-(void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor completionHandler:(void (^)(QredoVaultItem *vaultItem, NSError *error))completionHandler;

/** Retrieves the metadata for the vault item with the given descriptor
 @param itemDescriptor The descriptor for the item to retrieve. This can be found in the `QredoVaultItemMetadata`
 @param completionHandler Returns the vault item metadata or an error if it cannot be found
 @see Retrieving an item from the Vault: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html)
 */

-(void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor completionHandler:(void (^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler;


#pragma mark - Vault listeners


/**
 
 Start listening for items added to the Vault
 
 Adds an observer that adopts the `QredoVaultObserver` protocol. The [didReceiveVaultItemMetadata](../Protocols/QredoVaultObserver.html#/c:objc(pl)QredoVaultObserver(im)qredoVault:didReceiveVaultItemMetadata:) method must be implemented
 
 @see Vault listeners: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/vault_listeners.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/vault_listeners.html)
 
 @param observer The object that implements the `QredoVaultObserver` protocol.
 
 */

-(void)addVaultObserver:(id<QredoVaultObserver>)observer;


/**
 Stop listening for items added to the Vault and delete the observer object.
 @param The observer to remove
 
 @note Observers are automatically deleted when you close the connection to the `QredoClient`.
 
 */
-(void)removeVaultObserver:(id<QredoVaultObserver>)observer;


#pragma mark - Adding items to the Vault

-(void)putItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler;


#pragma mark - Finding items in the Vault

/**

Goes through the items in this Vault and calls the specified code block on each one
 
@see Retrieving an item from the Vault: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html)
 
@param block Called for each vault item, passing the `QredoVaultItemMetadata`.  Set `stop` to YES to terminate the enumeration
@param completionHandler will be called when the enumeration is complete or if an error occurs

 */

-(void)enumerateVaultItemsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                   completionHandler:(void (^)(NSError *error))completionHandler;


/**
 
 Goes through the items in this Vault at the point after the specified highwatermark and calls the specified code block on each one
 
 @see Retrieving an item from the Vault: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/retrieving_an_item_from_the_vault.html)
 
 @param block Called for each vault item, passing the `QredoVaultItemMetadata`.  Set `stop` to YES to terminate the enumeration
 @param sinceWatermark The `QredoVaultHighWatermark` specifying the location in the Vault to search from. Set this to `QredoVaultHighWatermarkOrigin` to start the enumeration from the beginning or use the `highWatermark` method to get the current watermark
 @param completionHandler will be called when the enumeration is complete or if an error occurs
 
 */

-(void)enumerateVaultItemsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                               since:(QredoVaultHighWatermark*)sinceWatermark
                   completionHandler:(void (^)(NSError *error))completionHandler;

/** The current highwatermark for this Vault. 
 
 This is the location from which updates will arrive in the [didReceiveVaultItemMetadata](../Protocols/QredoVaultObserver.html#/c:objc(pl)QredoVaultObserver(im)qredoVault:didReceiveVaultItemMetadata:) method  */
-(QredoVaultHighWatermark *)highWatermark;

/** Resets the highwatermark for this Vault to the beginning. 
 If a `QredoVaultObserver` has been added, the [didReceiveVaultItemMetadata](../Protocols/QredoVaultObserver.html#/c:objc(pl)QredoVaultObserver(im)qredoVault:didReceiveVaultItemMetadata:) will be invoked with all items in the Vault
 */
 -(void)resetWatermark;


#pragma mark - Deleting Vault items

/** Deletes a vault item and returns its descriptor
 
 @note The item will be permanently deleted and cannot be retrieved later
 @param metadata The `QredoVaultItemMetadata` of the item to delete
 @param completionHandler Called with the `QredoVaultItemDescriptor` of the deleted item if the delete is successful or an error.
 
 @see Deleting a Vault item: [Objective-C](https://www.qredo.com/docs/ios/objective-c/programming_guide/html/the_vault/deleting_a_vault_item.html), [Swift](https://www.qredo.com/docs/ios/swift/programming_guide/html/the_vault/deleting_a_vault_item.html)
 
 
 */
-(void)deleteItem:(QredoVaultItemMetadata *)metadata completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler;


#pragma mark - Updating Vault items
-(void)updateItem:(QredoVaultItemMetadata *)metadata value:(NSData *)value
                                         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler;



@end


@interface QredoVault (LocalIndex)


typedef void (^ IncomingMetadataBlock)(QredoVaultItemMetadata *vaultMetadata);

/** 
 Find a vault item in the local index using a predicate to specify a search query. Call the specified code block for each matching item.
 
@param predicate The search query. See the notes above.
@param block The code block to execute for each item that matches the search. Set `stop` to YES to terminate the search
@param completionHandler Called when the search is complete or an error occurs

 The following code will search for all items that contains objects with the key 'name' the value of which is equal to 'John':
 
 `[NSPredicate predicateWithFormat:@"key=='name' && value.string=='John'"];`
 
 Value is matched against a sub field depending on specified type.
 Valid types are:
 
 value.string    (NSString)
 
 value.date      (NSDate)
 
 value.number    (NSNumber)
 
 value.data      (NSData)

 */

-(void)enumerateIndexUsingPredicate:(NSPredicate *)predicate
                          withBlock:(void (^)(QredoVaultItemMetadata *vaultMetadata, BOOL *stop))block
                  completionHandler:(void (^)(NSError *error))completionHandler;


/** Return the number of Metadata entries in the local Metadata index  */
-(int)indexSize;

/** Retrieves an NSManagedObjectContext (on main Thread) for the Coredata stack holding the index 
 Only to be used if you are accessing the `NSManagedObjectContext` directly as shown in the CustomerLookup example
 */
-(NSManagedObjectContext*)indexManagedObjectContext;

/** Caching of Vault Item Metadata is enabled by default, turning it off will turn off all caching & indexing 
 
 @note It is recommended that metadata caching is only turned off when free space on the device is running very low. Disabling the cache will decrease performance since nothing will be cached locally on the devices and searches will always have to go straight to the server
 
 @param metadataCacheEnabled Set to YES to enable the cache
 */
-(void)metadataCacheEnabled:(BOOL)metadataCacheEnabled;

/** Caching of VaultItem values is enabled by default, turning it off will force the value to be retrieved from the serve. Metadata caching is unaffected  
 
 @note We recommend value caching is only turned off when free space on the device is running low, but it should be disabled before turning off the metadata cache. It is not possible to control which vault items are cached on the device, only the cache size.
 
 @param metadataCacheEnabled Set to YES to enable the cache

  */
-(void)valueCacheEnabled:(BOOL)valueCacheEnabled;

/** Returns the size in bytes of the cache/index coredata database
 This allows dynamic management of the caches if required in the case of an app which uses a large amount of storage */

-(long long)cacheFileSize;

/**  Deletes all records in both the cache and the index. 
 @note Only call this when running low on device space. All data will have to be read from the server */
-(void)purgeCache;

/** Set the maximum size in bytes of the local cache/index. The default is `QREDO_DEFAULT_INDEX_CACHE_SIZE`*/
-(void)setMaxCacheSize:(long long)maxSize;


@end


