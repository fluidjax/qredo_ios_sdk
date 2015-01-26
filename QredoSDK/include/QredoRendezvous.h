/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoRendezvous_h
#define QredoSDK_QredoRendezvous_h

#import "QredoTypes.h"

typedef uint64_t QredoRendezvousHighWatermark;
extern const QredoRendezvousHighWatermark QredoRendezvousHighWatermarkOrigin;
extern NSString *const kQredoRendezvousVaultItemType;

extern NSString *const kQredoRendezvousVaultItemLabelTag;


@class QredoRendezvous;

@protocol QredoRendezvousDelegate <NSObject>
@required
/** Called when a new response is received */
- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation;

@optional
/** Not implemented yet. Supposed to be called when the server closes the rendezvous after `durationSeconds` specified in `QredoRendezvousConfiguration` */
- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didTimeout:(NSError *)error;
@end

/** This class is used for creating rendezvous and for getting information about rendezvous */
@interface QredoRendezvousConfiguration : NSObject
/** Reverse domain name service notation. For example, `com.qredo.qatchat` */
@property NSString *conversationType;

@property (readonly) QredoRendezvousAuthenticationType authenticationType;

/** if `nil`, then conversation doesn't have a time limit */
@property (readonly) NSNumber *durationSeconds;
/** if `nil`, then conversation doesn't have a limit for the number of responders */
@property (readonly) NSNumber *maxResponseCount;

@property (readonly) NSSet* transCap;

/** Should be used only for creating a new rendezvous */
- (instancetype)initWithConversationType:(NSString*)conversationType;
/** Should be used only for creating a new rendezvous */
- (instancetype)initWithConversationType:(NSString*)conversationType durationSeconds:(NSNumber *)durationSeconds maxResponseCount:(NSNumber *)maxResponseCount;

- (instancetype)initWithConversationType:(NSString*)conversationType durationSeconds:(NSNumber *)durationSeconds maxResponseCount:(NSNumber *)maxResponseCount transCap:(NSSet*)transCap;

- (instancetype)initWithConversationType:(NSString*)conversationType authenticationType:(QredoRendezvousAuthenticationType)authenticationType durationSeconds:(NSNumber *)durationSeconds maxResponseCount:(NSNumber *)maxResponseCount transCap:(NSSet*)transCap;

@end


// QredoRendezvousMetadata objects are returned in [QredoClient enumerateRendezvousWithBlock:] method.
// Although, at the moment it has only tag, we might add more information later.
@interface QredoRendezvousMetadata : NSObject

@property (readonly) NSString *tag;

@end

/** Objects of this class are not supposed to be created manually. Instances of QredoRendezvous can be returned from:

 - `[QredoClient createRendezvousWithTag:configuration:completionHandler:]`
 - `[QredoClient enumerateRendezvousWithBlock:failureHandler:]`
 - `[QredoClient fetchRendezvousWithTag:completionHandler:]`
 */
@interface QredoRendezvous : NSObject
/** See `QredoRendezvousConfiguration` */
@property (readonly) QredoRendezvousConfiguration *configuration;
@property (readonly) NSString *tag;


/** See `QredoRendezvousDelegate` */
@property (weak) id<QredoRendezvousDelegate> delegate;

/** High watermark defining the last point when we get the number of responders. Updated when listening for events. See `startListening`.
 The value of the high watermark is persisted on the device.
 */
@property (readonly) QredoRendezvousHighWatermark highWatermark;

- (void)resetHighWatermark;

- (QredoRendezvousMetadata*)metadata;

/** Not implemented yet. */
- (void)deleteWithCompletionHandler:(void (^)(NSError *error))completionHandler;

/** Start listening for responses to the rendezvous. `delegate` should be set before calling this method. */
- (void)startListening;
/** Stops listening for responses to the rendezvous. */
- (void)stopListening;

/** Enumerates all the conversations (responses) that were created for this rendezvous */
- (void)enumerateConversationsWithBlock:(void (^)(QredoConversation *conversation, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;
/** Enumerates the conversations (responses) that were created for this rendezvous since the specified high watermark */
- (void)enumerateConversationsWithBlock:(void (^)(QredoConversation *conversation, BOOL *stop))block since:(QredoRendezvousHighWatermark)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler;

@end

#endif