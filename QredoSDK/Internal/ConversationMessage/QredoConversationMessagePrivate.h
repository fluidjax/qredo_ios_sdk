/* HEADER GOES HERE */
#import "QredoConversationMessage.h"
#import "QredoClient.h"

typedef NS_ENUM(NSInteger, QredoConversationControlMessageType) {
    QredoConversationControlMessageTypeNotControlMessage = -2,
    QredoConversationControlMessageTypeUnknown = -1,
    QredoConversationControlMessageTypeJoined  = 0,
    QredoConversationControlMessageTypeLeft
};

extern NSString *const kQredoConversationMessageTypeControl;


@interface QredoConversationMessage ()
@property (readwrite) NSString *dataType;

@end


@interface QredoConversationMessage (Private)



- (instancetype)initWithMessageLF:(QLFConversationMessage*)messageLF incoming:(BOOL)incoming;
// making read/write for private use

-(instancetype)initWithValue:(NSData*)value
                    dataType:(NSString*)dataType
               summaryValues:(NSDictionary*)summaryValues;


@property QredoConversationHighWatermark *highWatermark;


- (BOOL)isControlMessage;
- (QredoConversationControlMessageType)controlMessageType;

- (QLFConversationMessage*)messageLF;

@end