/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoVault_h
#define QredoSDK_QredoVault_h

#import "QredoTypes.h"

/** Represents state of the vault. An opaque class */
@interface QredoVaultHighWatermark : NSObject
@end

/** Points to the origin of the vault. If it is used in `[QredoVault enumerateVaultItemsUsingBlock:failureHandler:since:]`, then it will return all the items from the vault */
extern QredoVaultHighWatermark *const QredoVaultHighWatermarkOrigin;

@class QredoVault;
@class QredoVaultItemMetadata;

@protocol QredoVaultDelegate <NSObject>

- (void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata;
- (void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error;

@end

@interface QredoVaultItemDescriptor : NSObject
// assuming that vault id is known by QredoClient
@property (readonly) QredoQUID *sequenceId;
@property (readonly) QredoQUID *itemId;

// sequenceValue is not used, because in rev.1 there is no version control, then itemId should be enough for pointing to the correct vault item
+ (instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId itemId:(QredoQUID *)itemId;

- (BOOL)isEqual:(id)object;
@end

/** Immutable metadata. If we need mutable object later, then we can define QredoVaultItemMetaDataMutable */
@interface QredoVaultItemMetadata : NSObject

@property (readonly) QredoVaultItemDescriptor *descriptor;
@property (readonly) NSString *dataType;
@property (readonly) QredoAccessLevel accessLevel;
@property (readonly) NSDictionary *summaryValues; // string -> string | NSNumber | QredoQUID

// this constructor is used mainly internally to create object retreived from the server. It can be hidden in private header file
+ (instancetype)vaultItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)descriptor dataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel summaryValues:(NSDictionary *)summaryValues;
/** this constructor to be used externally when creating a new vault item to be stored in Vault */
+ (instancetype)vaultItemMetadataWithDataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel summaryValues:(NSDictionary *)summaryValues;
@end

@interface QredoVaultItem : NSObject
@property (readonly) QredoVaultItemMetadata *metadata;
@property (readonly) NSData *value;

+ (instancetype)vaultItemWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value;
@end


/** 
 @discussion constructor is private, as an external developer is not supposed to create an object of this class
 */
@interface QredoVault : NSObject

@property (weak) id<QredoVaultDelegate> delegate;

- (QredoQUID *)vaultId;

- (void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor completionHandler:(void(^)(QredoVaultItem *vaultItem, NSError *error))completionHandler;

- (void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor completionHandler:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler;

/** 
 Start listening for the new items. In future revisions it may also return changes on existing items. Notifications will be returned to the delegate
 @discussion fails if delegate == nil 
 */
- (void)startListening;
- (void)stopListening;

- (void)putItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler;

/** Requests meta data of all items from the server and calls `block` for each item. If an error occurs during the request, then `completionHandler` is called with NSError set, otherwise it gets called once enumeration complete. Enumeration starts from `QredoVaultHighWatermarkOrigin`, i.e. returning all items from the vault. If it is necessary to return items from certain point, use `enumerateVaultItemsUsingBlock:failureHandler:since:`

 @param block called for every item in the vault. If the block sets `YES` to `stop` then the enumeration will terminate.
 @param completionHandler is called when enumeration completed or if an error has occured during the communication to the server

 @discussion The method name is aligned with `[NSArray enumerateObjectsUsingBlock:]`, however, in our case this method may go to server to request the items
 */
- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;

/** Returns meta data of items starting from the specific high watermark. See `enumerateVaultItemsUsingBlock:failureHandler:` for more details. */
- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block since:(QredoVaultHighWatermark*)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler;

/** Deletes a vault item and returns it's metadata */
- (void)deleteItem:(QredoVaultItemMetadata *)metadata completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler;

/** High watermark of the Vault from which the updates will be arriving, when `startListening` is called. The watermark is persisted in `NSUserDefaults`. */
- (QredoVaultHighWatermark *)highWatermark;

/** If for some reason the client application needs to receive all items in the delegate after calling `startListening`, then this method can be called. */
- (void)resetWatermark;
@end

#endif
