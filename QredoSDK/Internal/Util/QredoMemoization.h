//
//  QredoMemoization.h
//  QredoSDK
//
//  Created by Christopher Morris on 04/09/2017.
//  
//

#import <Foundation/Foundation.h>

@interface QredoMemoization : NSObject

@property (readonly,assign) int memoizationHits;
@property (readonly,assign) int memoizationTrys;


-(id)memoizeAndInvokeSelector:(SEL)selector withArguments:(id)arguments, ... ;


//Testing / Debugging
-(void)purgeMemoizationCache;

@end
