/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>


@interface QredoObserverList : NSObject


#pragma mark Properties

@property (nonatomic, readonly) NSString *associationKey;


#pragma mark Inits

- (instancetype)initWithAssociationKey:(NSString *)associationKey;


#pragma mark Add, remove and notify observers

- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;
- (void)notifyObservers:(void(^)(id observer))notificationBlock;


#pragma mark Misc utils

- (NSUInteger)count;


@end
