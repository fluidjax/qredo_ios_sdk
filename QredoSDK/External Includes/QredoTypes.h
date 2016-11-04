/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

/** The class that `QredoRendezvousRef`and `QredoConversationRef` derive from
 Objects of this class are not created directly
 */
@interface QredoObjectRef :NSObject

/** Used internally */
-(instancetype)initWithData:(NSData *)data;
-(nullable NSString*)serializedString;
-(nullable instancetype)initWithSerializedString:(NSString* _Nonnull)string;


-(BOOL)isEqual:(id)object;
- (NSData *)dataUsingEncoding:(NSStringEncoding)encoding;



/** Developers should not rely on the contents of this property */
@property (readonly) NSData * _Nonnull data;

@end
