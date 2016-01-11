/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoObserverList.h"
#import <objc/runtime.h>



static NSString *const kDefaultAssociationKey  = @"QredoObserverList_ObserverProxyObject";



//=================================================================================================================
#pragma mark Interfaces -
//=================================================================================================================


@interface QredoObserverProxy : NSObject
@property (weak) id observer;
@end


#pragma mark -
//-----------------------------------------------------------------------------------------------------------------


@interface QredoObserverList ()
{
    /*
     Notification of observers takes place on this queue.
     */
    dispatch_queue_t _observerNotificationQueue;
    
    NSMutableArray *_observerProxies;
}

@property (nonatomic) NSString *associationKey;

@end



//=================================================================================================================
#pragma mark - Implementaions -
//=================================================================================================================


@implementation QredoObserverProxy

- (instancetype)initWithObserver:(id)observer
{
    self = [self init];
    if (self) {
        _observer = observer;
    }
    return self;
}

+ (instancetype)observerProxyWithObserver:(id)observer
{
    return [[self alloc] initWithObserver:observer];
}

@end


#pragma mark -
//-----------------------------------------------------------------------------------------------------------------


@implementation QredoObserverList


#pragma mark Inits

- (instancetype)init
{
    return [self initWithAssociationKey:nil];
}

- (instancetype)initWithAssociationKey:(NSString *)associationKey
{
    self = [super init];
    if (self) {
        _associationKey = associationKey ? associationKey : kDefaultAssociationKey;
        _observerNotificationQueue = dispatch_queue_create("com.qredo.QredoObserverList.observerNotificationQueue", DISPATCH_QUEUE_CONCURRENT);
        _observerProxies = [NSMutableArray array];
    }
    return self;
}


#pragma mark Add, remove and notify observers

- (void)addObserver:(id)observer{
    NSAssert(observer, @"An observer must be supplied to [QredoVault addQredoVaultObserver:]");
    
    @synchronized(self) {
        QredoObserverProxy *observerProxy = [self proxyForObserver:observer];
        if (!observerProxy) {
            observerProxy = [QredoObserverProxy observerProxyWithObserver:observer];
            [self setProxy:observerProxy forObserver:observer];
        }
        
        NSAssert1(![_observerProxies containsObject:observerProxy],@"The %@ is already added to the QredoObserverList", observer);
        [_observerProxies addObject:observerProxy];
        
    }
}

- (void)removeObserver:(id)observer{
    NSAssert(observer, @"An observer must be supplied to [QredoVault removeQredoVaultObaserver:]");
    QredoObserverProxy *observerProxy = [self proxyForObserver:observer];
    @synchronized(self) {
        if (observerProxy) {
            [_observerProxies removeObject:observerProxy];
        }
    }
}

- (void)notifyObservers:(void(^)(id observer))notificationBlock{
    @synchronized(self) {
        
        //NSLog(@"Observer count %i",(int)[_observerProxies count]);
        
        for (QredoObserverProxy *observerProxy in _observerProxies.reverseObjectEnumerator) {
            // perhaps some check here, if all observers are properly set up
            if (!observerProxy.observer) {
                [_observerProxies removeObject:observerProxy];
                continue;
            }
            dispatch_async(_observerNotificationQueue, ^{
                notificationBlock(observerProxy.observer);
            });
        }
    }
}


- (BOOL)contains:(id)observer{
    if ([self proxyForObserver:observer])return YES;
    return NO;
}



#pragma mark Misc utils

- (NSUInteger)count
{
    return [_observerProxies count];
}


#pragma mark Utils for observer and proxy association

- (QredoObserverProxy *)proxyForObserver:(id)observer
{
    const char *associationKey = [self.associationKey cStringUsingEncoding:NSUTF8StringEncoding];
    return objc_getAssociatedObject(observer,
                                    associationKey);
}

- (void)setProxy:(QredoObserverProxy *)observerProxy forObserver:(id)observer
{
    const char *associationKey = [self.associationKey cStringUsingEncoding:NSUTF8StringEncoding];
    objc_setAssociatedObject(observer,
                             associationKey,
                             observerProxy,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end



