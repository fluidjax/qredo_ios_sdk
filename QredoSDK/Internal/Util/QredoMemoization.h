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

//Testing / Debugging
-(float)memoizationHitRate;
-(void)purgeMemoizationCache;

@end
