/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoUpdateListener.h"
#import "QredoLogging.h"

@interface QredoUpdateListener ()
{
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
    dispatch_queue_t _subscriptionRenewalQueue;
    dispatch_source_t _subscriptionRenewalTimer;

    BOOL _subscribedToMessages;
    BOOL _isPollingActive;

    // Key is item, value is sequence number
    NSMutableDictionary *_dedupeStore;

    // Dedupe only necessary during subscription setup - once subsequent query has completed, dedupe no longer required
    BOOL _dedupeNecessary;

    // Indicates that the Query after Subscribe has completed, and no more entries to process
    BOOL _queryAfterSubscribeComplete;
}

@end

@implementation QredoUpdateListener

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    _dedupeStore = [[NSMutableDictionary alloc] init];

    _queue = dispatch_queue_create("com.qredo.conversation.updates", nil);

    self.pollInterval = 1.0;
    self.pollIntervalDuringSubscribe = 10.0;
    self.renewSubscriptionInterval = 15.0;

    return self;
}

- (void)startListening
{
    NSAssert(_delegate, @"Conversation delegate should be set before starting listening for the updates");

    // If we support multi-response, then use it, otherwise poll
    if ([self.dataSource qredoUpdateListenerDoesSupportMultiResponseQuery:self])
    {
        if ([self.dataSource isMemberOfClass:NSClassFromString(@"QredoConversation")] || [self.dataSource isMemberOfClass:NSClassFromString(@"QredoRendezvous")])
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resubscribeWithCompletionHandler:) name:@"resubscribe" object:nil];

        [self startSubscribing];
    }
    else
    {
        _isPollingActive = YES;
        [self startPolling];
    }
    
    _isListening = YES;
}

- (void)stopListening
{
    _isListening = NO;
    NSLog(@"stopListening %@", self.dataSource);

    // If we support multi-response, then use it, otherwise poll
    if ([self.dataSource qredoUpdateListenerDoesSupportMultiResponseQuery:self])
    {
        [self stopSubscribing];
    }
    else
    {
        [self stopPolling];
    }
}

// This method enables subscription (push) for conversation items, and creates new messages from them. Will regularly re-send subsription request as subscriptions can fail silently
- (void)startSubscribing
{
    NSLog(@"startSubscribing");
    
    NSAssert(_delegate, @"Conversation delegate should be set before starting listening for the updates");

    if (_subscribedToMessages) {
        return;
    }

    // Setup re-subscribe timer first
    @synchronized (self) {
        if (_subscriptionRenewalTimer) return;

        _subscriptionRenewalTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _subscriptionRenewalQueue);
        if (_subscriptionRenewalTimer)
        {
            dispatch_source_set_timer(_subscriptionRenewalTimer,
                                      dispatch_time(DISPATCH_TIME_NOW,
                                                    self.renewSubscriptionInterval * NSEC_PER_SEC), // start
                                                    self.renewSubscriptionInterval * NSEC_PER_SEC, // interval
                                      (1ull * NSEC_PER_SEC) / 10); // how much it can defer from the interval
            dispatch_source_set_event_handler(_subscriptionRenewalTimer, ^{
                @synchronized (self) {
                    if (!_subscriptionRenewalTimer) {
                        return;
                    }
                    
                    NSLog(@"periodic resubscribtion");

                    // Should be able to keep subscribing without any side effects, but try to unsubscribing first
                    [self resubscribeWithCompletionHandler:nil];

                }
            });
            dispatch_resume(_subscriptionRenewalTimer);
        }
    }

    // Start first subscription
    [self subscribeWithCompletionHandler:nil];
}

- (void)didTerminateSubscriptionWithError:(NSError *)error
{
    NSLog(@"Conversation subscription terminated with error: %@", error);
    _subscribedToMessages = NO;
}

- (void)subscribeWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    if (_subscribedToMessages) return ;
    NSAssert(_delegate, @"Conversation delegate should be set before starting listening for the updates");

    _subscribedToMessages = YES;

    /*
     Dedupe is necessary when setting up, as requires both Subscribe and Query. Both could return the same
     Response, so need dedupe. Once Query has completed, Subscribe takes over and dedupe no longer required.
     */
    _dedupeNecessary = YES;
    _queryAfterSubscribeComplete = NO;

    [self.dataSource qredoUpdateListener:self subscribeWithCompletionHandler:^(NSError *error) {
        _queryAfterSubscribeComplete = YES;

        if (!error) {
            [self.dataSource qredoUpdateListener:self pollWithCompletionHandler:^(NSError *error) {
                if (completionHandler) completionHandler(error);
            }];
         } else {
             if (completionHandler) completionHandler(error);
         }
    }];
    
    NSLog(@"started subscription: %@", self.dataSource);
}

- (void)resubscribeWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
//    if (_subscribedToMessages) return ;
//    NSAssert(_delegate, @"Conversation delegate should be set before starting listening for the updates");
    NSLog(@"resubscription %@", self.dataSource);
    
    if ([self.dataSource isMemberOfClass:NSClassFromString(@"QredoConversation")] || [self.dataSource isMemberOfClass:NSClassFromString(@"QredoConversation")]) {
    
        _subscribedToMessages = YES;
        
        /*
         Dedupe is necessary when setting up, as requires both Subscribe and Query. Both could return the same
         Response, so need dedupe. Once Query has completed, Subscribe takes over and dedupe no longer required.
         */
        _dedupeNecessary = YES;
        _queryAfterSubscribeComplete = NO;
        
        [self.dataSource qredoUpdateListener:self subscribeWithCompletionHandler:^(NSError *error) {
            _queryAfterSubscribeComplete = YES;
            
            if (!error) {
                [self.dataSource qredoUpdateListener:self pollWithCompletionHandler:^(NSError *error) {
                    if (completionHandler)
                        completionHandler(error);
                }];
            } else {
                if (completionHandler)
                    completionHandler(error);
        }}];
        
        NSLog(@"started resubscription");
    }
}

- (void)unsubscribeWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSLog(@"unsubscribeWithCompletionHandler"); // <- not called
    [self.dataSource qredoUpdateListener:self unsubscribeWithCompletionHandler:^(NSError *error) {
        _subscribedToMessages = NO;
        if (completionHandler) completionHandler(error);
    }];
}

// This method disables subscription (push) for responses to rendezvous
- (void)stopSubscribing
{
    NSLog(@"stopSubscribing"); // <- not called
    // Need to stop the subsription renewal timer as well
    @synchronized (self) {
        if (_subscriptionRenewalTimer) {
            dispatch_source_cancel(_subscriptionRenewalTimer);
            _subscriptionRenewalTimer = nil;
        }
    }

    [self unsubscribeWithCompletionHandler:nil];
}

- (BOOL)processSingleItem:(id)item sequenceValue:(id)sequenceValue
{
    NSLog(@"processSingleItem:(id)item sequenceValue:(id)sequenceValue");
    if (_dedupeNecessary) {
        if ([self isDuplicateOrOldItem:item sequenceValue:sequenceValue]) {
            return NO;
        }
    }

    [self.delegate qredoUpdateListener:self processSingleItem:item];
    return YES;
}

// This method polls for (new) items in conversation, and creates message from them.
- (void)startPolling
{
    if (!_isPollingActive) {
        return ;
    }

    [self.dataSource qredoUpdateListener:self pollWithCompletionHandler:^(NSError *error)
    {
        if (!_isPollingActive) {
            return ;
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pollInterval * NSEC_PER_SEC)), _queue, ^{
            [self startPolling];
        });
    }];

}

- (void)stopPolling
{
    NSLog(@"stopPolling"); // <- not called
    @synchronized (self) {
        _isPollingActive = NO;
    }
}


- (BOOL)isDuplicateOrOldItem:(id)item sequenceValue:(id)sequenceValue
{
    BOOL itemIsDuplicate = NO;

    // TODO: DH - Store hashes, rather than actual values if those values are large?

    // TODO: DH - Confirm whether sequence value for Items are unique to that item - i.e. can just store sequence values for dedupe?
    // A duplicate item is being taken to be a specific item which has the same sequence value
    @synchronized(_dedupeStore) {
        id fetchedSequenceValue = [_dedupeStore objectForKey:item];
        
        // TODO: DH - Find out if can improve this check - can conversation sequence values be greater/less than each other - or just non-comparable opaque values?
        if (fetchedSequenceValue && [sequenceValue isEqualToData:fetchedSequenceValue]) {
            // Found a duplicate item
            itemIsDuplicate = YES;
        }
        else if (_queryAfterSubscribeComplete) {
            // We have completed processing the Query after Subscribe, and we have a non-duplicate Item - therefore we have passed the point where dedupe is required, so can empty the dedupe store
            _dedupeNecessary = NO;
            [_dedupeStore removeAllObjects];
        }
        else {
            // Not a duplicate, and Query has not completed, so store this response/sequenceValue pair for later to prevent duplication
            [_dedupeStore setObject:sequenceValue forKey:item];
        }
    }

    return itemIsDuplicate;
}

@end
