/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@interface NSDictionary (IndexableSet)

-(NSSet *)indexableSet;

@end


@interface NSSet (IndexableSet)

-(NSDictionary *)dictionaryFromIndexableSet;

@end
