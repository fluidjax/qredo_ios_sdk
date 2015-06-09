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
    dispatch_queue_t _observerNotificaionQueue;
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
    self = [self initWithAssociationKey:nil];
    if (self) {
    }
    return self;
}

- (instancetype)initWithAssociationKey:(NSString *)associationKey
{
    self = [super init];
    if (self) {
        _associationKey = associationKey ? associationKey : kDefaultAssociationKey;
        _observerNotificaionQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _observerProxies = [NSMutableArray array];
    }
    return self;
}


#pragma mark Add, remove and notify observers

- (void)addObserver:(id)observer completionHandler:(void(^)())completionHandler
{
    NSAssert(observer, @"An observer must be supplied to [QredoVault addQredoVaultObserver:]");
    
    dispatch_async(_observerNotificaionQueue, ^{
        
        QredoObserverProxy *observerProxy = [self proxyForObserver:observer];
        if (!observerProxy) {
            observerProxy = [QredoObserverProxy observerProxyWithObserver:observer];
        }
        
        NSAssert1(![_observerProxies containsObject:observerProxy],
                  @"The %@ is already added to the QredoObserverList", observer);
        
        [_observerProxies addObject:observerProxy];
        
        if (completionHandler) {
            completionHandler();
        }
        
    });
}

- (void)removeObaserver:(id)observer completionHandler:(void(^)())completionHandler
{
    NSAssert(observer, @"An observer must be supplied to [QredoVault removeQredoVaultObaserver:]");
    
    QredoObserverProxy *observerProxy = [self proxyForObserver:observer];
    
    dispatch_async(_observerNotificaionQueue, ^{
        
        if (observerProxy) {
            [_observerProxies removeObject:observerProxy];
        }
        
        if (completionHandler) {
            completionHandler();
        }
        
    });
}

- (void)notyfyObservers:(void(^)(id observer))notificationBlock
{
    dispatch_async(_observerNotificaionQueue, ^{
        
        for (QredoObserverProxy *observerProxy in _observerProxies.reverseObjectEnumerator) {
            
            if (!observerProxy.observer) {
                [_observerProxies removeObject:observerProxy];
                continue;
            }
            
            notificationBlock(observerProxy.observer);
        }
        
    });
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
                             OBJC_ASSOCIATION_ASSIGN);
}


@end



