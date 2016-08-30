/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoUpdateListener;

@protocol QredoUpdateListenerDataSource <NSObject>

@required
- (BOOL)qredoUpdateListenerDoesSupportMultiResponseQuery:(QredoUpdateListener *)updateListener;

// In an implementation of this method get results from the server and for each result call `[QredoUpdateListener processSingleItem:]`
- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener
              pollWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@optional

// if `DoesSupportMultiResponseQuery` returns YES, then these methods shall be implemented
- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener subscribeWithCompletionHandler:(void(^)(NSError *))completionHandler;
- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener unsubscribeWithCompletionHandler:(void(^)(NSError *))completionHandler;

@end


@protocol QredoUpdateListenerDelegate <NSObject>

// Implementation of this method should usually deliver result to the delegate.
// The type is the same as `item` in `[QredoUpdateListener processSingleItem:]`
- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item;

@end

@interface QredoUpdateListener : NSObject

@property (nonatomic, weak) id<QredoUpdateListenerDataSource> dataSource;
@property (nonatomic, weak) id<QredoUpdateListenerDelegate> delegate;

// if transport doesn't support multiresponse
@property (nonatomic) NSTimeInterval pollInterval;

// if transport supports multiresponse and there is multiresponse query, then we stil need to poll every now and then
// to make sure that nothing has been missed from the subscribe results
@property (nonatomic) NSTimeInterval pollIntervalDuringSubscribe;

// on MQTT there is no confirmation that subscribtion has been successful. (not sure yet if it is the case with WebSockets)
// therefore, we need to unsubscribe and subscribe from time to time
@property (nonatomic) NSTimeInterval renewSubscriptionInterval;

@property (nonatomic) BOOL enumerateAfterSubscription;

@property (nonatomic, readonly) BOOL isListening;

- (void)startListening;
- (void)stopListening;

// Processing an items includes deduplicaiton of items if it is necessary
- (BOOL)processSingleItem:(id)item sequenceValue:(id)sequenceValue;

- (void)didTerminateSubscriptionWithError:(NSError *)error;

@end
