/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface NSDictionary (IndexableSet)

-(NSSet *)indexableSet;

@end


@interface NSSet (IndexableSet)

-(NSDictionary *)dictionaryFromIndexableSet;

@end