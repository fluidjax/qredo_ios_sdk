/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>


@interface QredoObserverList :NSObject


#pragma mark Properties
@property (nonatomic,readonly) NSString *associationKey;


#pragma mark Inits
-(instancetype)initWithAssociationKey:(NSString *)associationKey;


#pragma mark Add, remove and notify observers
-(void)addObserver:(id)observer;
-(void)removeObserver:(id)observer;
-(void)notifyObservers:(void (^)(id observer))notificationBlock;
-(BOOL)contains:(id)observer;
-(void)removeAllObservers;

#pragma mark Misc utils
-(NSUInteger)count;


@end
