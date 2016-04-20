#import <Foundation/Foundation.h>

/** Used to represent ConversationIDs and other values used by the SDK. 
 
 Developers should not need to manipulate QredoQUID objects */

@interface QredoQUID : NSObject <NSCopying, NSSecureCoding>

/** Used internally */
- (NSData*)data;

/** Return a 64 character string represenation of the  QUID */
- (NSString *)QUIDString;

/** Compare this QUID with the one passed as a parameter */
- (NSComparisonResult)compare:(QredoQUID *)object;

@end
