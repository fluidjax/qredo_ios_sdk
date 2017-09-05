//
//  QredoMemoization.m
//  QredoSDK
//
//  Created by Christopher Morris on 04/09/2017.
//  Memoized methods need to return Objects (not primitives), this is due a bug in 
//  http://www.cocoabuilder.com/archive/cocoa/288663-bool-returned-via-performselctor-not-bool-on-64-bit-system.html

#import "QredoMemoization.h"

@interface QredoMemoization()
@property (strong) NSMutableDictionary *memoizationStore;
@property (readwrite, assign) int memoizationHits;
@property (readwrite, assign) int memoizationTrys;
@end


@implementation QredoMemoization


- (instancetype)init{
    self = [super init];
    if (self) {
        _memoizationStore   = [[NSMutableDictionary alloc] init];
        _memoizationHits     = 0;
        _memoizationTrys    = 0;
    }
    return self;
}


-(void)purgeMemoizationCache{
    [_memoizationStore removeAllObjects];
    _memoizationStore   = nil;
    _memoizationStore   = [[NSMutableDictionary alloc] init];
    _memoizationHits     = 0;
    _memoizationTrys    = 0;
}


-(id)memoizeAndInvokeSelector:(SEL)selector withArguments:(id)arguments, ... {
    self.memoizationTrys++;

    
    //create a key array based on selector & arguments
    NSMutableArray *key = [[NSMutableArray alloc] init];
    NSNumber *selectorPointer = [NSNumber numberWithUnsignedLong:(uintptr_t)(void *)selector];
    [key addObject:selectorPointer];
    va_list args;
    va_start(args, arguments);
    for(id argument = arguments; argument != nil; argument = va_arg(args, id)) {
        [key addObject:argument];
    }
    va_end(args);
    
    //is the result already cached?
    id result = [self.memoizationStore objectForKey:key];
    
    
    //if not excute method & cache
    if (!result){
        NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = selector;
        invocation.target = self;
        
        va_list args;
        va_start(args, arguments);
        NSUInteger index = 2;
        for(id argument = arguments; argument != nil; argument = va_arg(args, id)) {
            [self setArgument:argument atIndex:index++ inInvocation:invocation];
        }
        va_end(args);
        
        [invocation invoke];
        result = [self returnValueForMethodSignature:methodSignature withInvocation:invocation];
        [self.memoizationStore setObject:result forKey:key];
        
    }else{
        self.memoizationHits++;
    }
    return result;
}



- (void)setArgument:(id)object atIndex:(NSUInteger)index inInvocation:(NSInvocation *)invocation {
#define PULL_AND_SET(type, selector) \
do { \
type val = [object selector]; \
[invocation setArgument:&val atIndex:(NSInteger)index]; \
} while(0)
    
    const char *argType = [invocation.methodSignature getArgumentTypeAtIndex:index];
    // Skip const type qualifier.
    if(argType[0] == 'r') {
        argType++;
    }
    
    if(strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        [invocation setArgument:&object atIndex:(NSInteger)index];
    }else if(strcmp(argType, @encode(char)) == 0)               {PULL_AND_SET(char, charValue);
    }else if(strcmp(argType, @encode(int)) == 0)                {PULL_AND_SET(int, intValue);
    }else if(strcmp(argType, @encode(short)) == 0)              {PULL_AND_SET(short, shortValue);
    }else if(strcmp(argType, @encode(long)) == 0)               {PULL_AND_SET(long, longValue);
    }else if(strcmp(argType, @encode(long long)) == 0)          {PULL_AND_SET(long long, longLongValue);
    }else if(strcmp(argType, @encode(unsigned char)) == 0)      {PULL_AND_SET(unsigned char, unsignedCharValue);
    }else if(strcmp(argType, @encode(unsigned int)) == 0)       {PULL_AND_SET(unsigned int, unsignedIntValue);
    }else if(strcmp(argType, @encode(unsigned short)) == 0)     {PULL_AND_SET(unsigned short, unsignedShortValue);
    }else if(strcmp(argType, @encode(unsigned long)) == 0)      {PULL_AND_SET(unsigned long, unsignedLongValue);
    }else if(strcmp(argType, @encode(unsigned long long)) == 0) {PULL_AND_SET(unsigned long long, unsignedLongLongValue);
    }else if(strcmp(argType, @encode(float)) == 0)              {PULL_AND_SET(float, floatValue);
    }else if(strcmp(argType, @encode(double)) == 0)             {PULL_AND_SET(double, doubleValue);
    }else if(strcmp(argType, @encode(BOOL)) == 0)               {PULL_AND_SET(BOOL, boolValue);
    }else if(strcmp(argType, @encode(char *)) == 0){
        const char *cString = [object UTF8String];
        [invocation setArgument:&cString atIndex:(NSInteger)index];
    } else if(strcmp(argType, @encode(void (^)(void))) == 0) {
        [invocation setArgument:&object atIndex:(NSInteger)index];
    } else {
        NSCParameterAssert([object isKindOfClass:NSValue.class]);
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment([object objCType], &valueSize, NULL);
        
#if DEBUG
        NSUInteger argSize = 0;
        NSGetSizeAndAlignment(argType, &argSize, NULL);
        NSCAssert(valueSize == argSize, @"Value size does not match argument size in -setArgument: %@ atIndex: %lu", object, (unsigned long)index);
#endif
        unsigned char valueBytes[valueSize];
        [object getValue:valueBytes];
        [invocation setArgument:valueBytes atIndex:(NSInteger)index];
    }
    
#undef PULL_AND_SET
}

- (id)returnValueForMethodSignature:(NSMethodSignature *)methodSignature withInvocation:(NSInvocation *)invocation {
    const char *returnType = methodSignature.methodReturnType;
    // Skip const type qualifier.
    if(returnType[0] == 'r') {
        returnType++;
    }
    if(strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0 || strcmp(returnType, @encode(void (^)(void))) == 0) {
        __autoreleasing id returnObj;
        [invocation getReturnValue:&returnObj];
        return returnObj;
    }else if(strcmp(returnType, @encode(void)) == 0){
        return nil;
    }else{
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(returnType, &valueSize, NULL);
        unsigned char valueBytes[valueSize];
        [invocation getReturnValue:valueBytes];
        return [NSValue valueWithBytes:valueBytes objCType:returnType];
    }
}


@end
