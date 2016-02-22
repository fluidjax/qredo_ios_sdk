/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTypes.h"

typedef uint64_t QredoRendezvousHighWatermark;
extern const QredoRendezvousHighWatermark QredoRendezvousHighWatermarkOrigin;
extern NSString *const kQredoRendezvousVaultItemType;
extern NSString *const kQredoRendezvousVaultItemLabelTag;
extern NSString *const kQredoRendezvousVaultItemLabelAuthenticationType;


@class QredoRendezvous;

@protocol QredoRendezvousObserver <NSObject>

@required
/** Called when a new response is received */
-(void)qredoRendezvous:(QredoRendezvous*)rendezvous
     didReceiveReponse:(QredoConversation *)conversation;

@optional
/** Not implemented yet. Supposed to be called when the server closes the rendezvous after `durationSeconds` specified in `QredoRendezvousConfiguration` */
-(void)qredoRendezvous:(QredoRendezvous*)rendezvous
            didTimeout:(NSError *)error;
@end





@interface QredoRendezvousRef :QredoObjectRef
@end



// QredoRendezvousMetadata objects are returned in [QredoClient enumerateRendezvousWithBlock:] method.
// Although, at the moment it has only tag, we might add more information later.
@interface QredoRendezvousMetadata :NSObject
@property (readonly) QredoRendezvousRef *rendezvousRef;
@property (readonly, copy) NSString *tag;
@end




/** Objects of this class are not supposed to be created manually. Instances of QredoRendezvous can be returned from:
 - `[QredoClient createRendezvousWithTag:configuration:completionHandler:]`
 - `[QredoClient enumerateRendezvousWithBlock:failureHandler:]`
 - `[QredoClient fetchRendezvousWithTag:completionHandler:]`
 */
@interface QredoRendezvous :NSObject
@property (readonly) QredoRendezvousMetadata *metadata;
@property (readonly) long duration;
@property (readonly) BOOL unlimitedResponses;
@property (readonly) NSDate *expiresAt;
@property (readonly) NSString *tag;


/** High watermark defining the last point when we get the number of responders. Updated when listening for events. See `startListening`.
 The value of the high watermark is persisted on the device.
 */
@property (readonly) QredoRendezvousHighWatermark highWatermark;

-(void)resetHighWatermark;

/** Not implemented yet. */
-(void)deleteWithCompletionHandler:(void (^)(NSError *error))completionHandler;
-(void)addRendezvousObserver:(id<QredoRendezvousObserver>)observer;
-(void)removeRendezvousObserver:(id<QredoRendezvousObserver>)observer;

/** Enumerates all the conversations (responses) that were created for this rendezvous */
-(void)enumerateConversationsWithBlock:(void (^)(QredoConversation *conversation, BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler;

/** Enumerates the conversations (responses) that were created for this rendezvous since the specified high watermark */
-(void)enumerateConversationsWithBlock:(void (^)(QredoConversation *conversation, BOOL *stop))block
                                 since:(QredoRendezvousHighWatermark)sinceWatermark
                     completionHandler:(void (^)(NSError *error))completionHandler;




@end
