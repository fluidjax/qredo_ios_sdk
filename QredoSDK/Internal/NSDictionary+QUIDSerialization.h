#import <Foundation/Foundation.h>

@interface NSDictionary (QUIDSerialization)
- (NSDictionary*)quidToStringDictionary;
- (NSDictionary*)stringToQuidDictionary;
@end
