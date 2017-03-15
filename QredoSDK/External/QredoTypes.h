/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

/** The class that `QredoRendezvousRef`and `QredoConversationRef` derive from
 Objects of this class are not created directly
 */
@interface QredoObjectRef :NSObject

/** Used internally */

/** Used internally */
-(nullable instancetype)initWithData:(NSData* _Nonnull)data;
-(nullable NSString*)serializedString;
-(nullable instancetype)initWithSerializedString:(NSString* _Nonnull)string;


-(BOOL)isEqual:(nullable id)object;
- (nullable NSData *)dataUsingEncoding:(NSStringEncoding)encoding;



/** Developers should not rely on the contents of this property */
@property (readonly) NSData * _Nonnull data;
@end
