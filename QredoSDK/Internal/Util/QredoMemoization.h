//
//  QredoMemoization.h
//  QredoSDK
//
//  Created by Christopher Morris on 04/09/2017.
//  
//

#import <Foundation/Foundation.h>

@interface QredoMemoization : NSObject


-(id)memoizeAndInvokeSelector:(SEL)selector withArguments:(id)arguments, ... ;
-(void)setArgument:(id)object atIndex:(NSUInteger)index inInvocation:(NSInvocation *)invocation;
-(id)returnValueForMethodSignature:(NSMethodSignature *)methodSignature withInvocation:(NSInvocation *)invocation;
-(float)memoizationHitRate;


@end
