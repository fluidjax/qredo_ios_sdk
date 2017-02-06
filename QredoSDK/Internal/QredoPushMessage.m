//
//  QredoPushMessage.m
//  QredoSDK
//
//  Created by Christopher Morris on 06/02/2017.
//
//

#import "QredoPushMessage.h"
#import "Qredo.h"
#import "QredoQUIDPrivate.h"
#import "QredoWireFormat.h"
#import "QredoPrimitiveMarshallers.h"


@interface QredoPushMessage ()
@property (readwrite) NSString* alert;
@property (assign,readwrite) BOOL contentAvailable;
@property (assign,readwrite) BOOL mutableContent;
@property (assign,readwrite) int messageType;
@property (readwrite) QredoQUID *queueId;
@property (readwrite) QredoClient *client;
@end

@implementation QredoPushMessage





-(instancetype)initWithMessage:(NSDictionary*)message qredoClient:(QredoClient*)client{
    self = [self init];
    if (self) {
        
        NSDictionary *aps = message[@"aps"];
        NSDictionary *q = message[@"q"];
        
        if (!aps || !q){
            NSLog(@"Invalid message");
            return nil;
        }
        
        if (!client){
            NSLog(@"Invalid Qredo Client");
            return nil;
        }
        
        
        self.client       = client;
        self.messageType  = [self decodeMessageType:q];
        self.queueId      = [self decodeQueueID:q];
        
        
        QredoConversation *conversation = [self buildConversationFromQueueID:self.queueId];
        
        
        [self decodeConversationItemWithSequenceValue:q];
        [self decodeSequenceValue:q];
        
        
    }
    return self;
}



-(QredoConversation*)buildConversationFromQueueID:(QredoQUID*)queueID{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *queueIDConversationLookup = [defaults objectForKey:@"ConversationQueueIDLookup"];
   
    
    QredoQUID *conversationID = [queueIDConversationLookup objectForKey:[queueID QUIDString]];
    NSLog(@"Retrieved ConversationID %@",conversationID);
 
    return nil;
    
}

-(void)decodeConversationItemWithSequenceValue:(NSDictionary*)q{
    NSData *conv = q[@"d"];
    if (!conv)return;
    QredoWireFormatReader *reader = [self wireFormatReaderFromString:conv];
}

-(void)decodeSequenceValue:(NSDictionary*)q{
    NSData *seq = q[@"s"];
    if (!seq)return;
    QredoWireFormatReader *reader = [self wireFormatReaderFromString:seq];
    
    
}





-(int)decodeMessageType:(NSDictionary*)q{
    int messageType = QREDO_PUSH_UNKNOWNTYPE_MESSAGE;
    NSString *messageTypeCode = [q objectForKey:@"t"];
    if (messageTypeCode && [messageTypeCode isEqualToString:@"c"]){
        messageType = QREDO_PUSH_CONVERSATION_MESSAGE;
    }
    
    return messageType;
}

-(QredoQUID*)decodeQueueID:(NSDictionary*)q{
    NSString *queueIdData = [q objectForKey:@"i"];
    if (!queueIdData)return nil;
    
    QredoWireFormatReader *reader = [self wireFormatReaderFromString:queueIdData];
    
    //[reader readStart];
    //NSData *p1 = [reader readByteSequence];
    //NSData *p2  = [reader readByteSequence];
    //this is encapulated by readMEssageHeader
    
    [reader readMessageHeader];
    QredoQUID *incomingQueueID = (QredoQUID*)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
    NSLog(@"***Incoming read queue ID is %@", _queueId);
    
    return incomingQueueID;
    
}


-(QredoWireFormatReader*)wireFormatReaderFromString:(NSString*)base64Data{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Data options:0];
    NSInputStream *readData = [[NSInputStream alloc] initWithData:data];
    [readData open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:readData];
    return reader;
}


- (NSString *)description{
    NSMutableString *dump = [[NSMutableString alloc] init];
    [dump appendFormat:@"\nAlert: %@\n",self.alert];
    
    switch (self.messageType) {
        case QREDO_PUSH_CONVERSATION_MESSAGE:
             [dump appendString:@"Type: Conversation\n"];
            break;
        default:
            [dump appendString:@"Type: **UNKNOWN**\n"];
            break;
    }
    
    [dump appendFormat:@"Alert: %@\n",self.alert];
    [dump appendFormat:@"QueueID: %@\n",self.queueId];
    return [dump copy];
}


@end
