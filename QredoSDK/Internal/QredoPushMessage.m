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
//#import "QredoPrimitiveMarshallers.h"
//#import "QredoConversationCrypto.h"
#import "QredoClient.h"
#import "QredoConversationPrivate.h"
#import "QredoConversationMessagePrivate.h"

@interface QredoPushMessage ()
@property (readwrite) NSString* alert;
@property (assign,readwrite) BOOL contentAvailable;
@property (assign,readwrite) BOOL mutableContent;
@property (assign,readwrite) int messageType;
@property (readwrite) QredoQUID *queueId;
@property (readwrite) QredoClient *client;
@property (readwrite) QredoConversation *conversation;
@property (readwrite) QredoConversationMessage *conversationMessage;
@property (readwrite) NSString *incomingMessageText;
@end

@implementation QredoPushMessage


#pragma Public constructor
+(void)initializeWithRemoteNotification:(NSDictionary*)message
                            qredoClient:(QredoClient*)client
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler{
    [[QredoPushMessage alloc] initializeWithRemoteNotification:message
                                                   qredoClient:client
                                             completionHandler:^(QredoPushMessage *pushMessage, NSError *error) {
                                                 completionHandler(pushMessage,error);
                                             }];
    
}



#pragma Private methods

-(void)initializeWithRemoteNotification:(NSDictionary*)message
                            qredoClient:(QredoClient*)client
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler{
               
        NSDictionary *aps = message[@"aps"];
        NSDictionary *q = message[@"q"];
        
        if (!aps || !q){
            NSLog(@"Invalid message");
            completionHandler(nil, [NSError errorWithDomain:@"qredopushmessage" code:1000 userInfo:nil]);
            return;
        }
        
        if (!client){
            NSLog(@"Invalid Qredo Client");
            completionHandler(nil, [NSError errorWithDomain:@"qredopushmessage" code:1000 userInfo:nil]);
            return;
        }
        
        
        self.alert        = aps[@"alert"][@"body"];
        self.client       = client;
        self.messageType  = [self decodeMessageType:q];
        self.queueId      = [self decodeQueueID:q];
        
        
        
        
        if (aps[@"content-available"]  &&  [aps[@"content-available"] intValue]==1){
            self.contentAvailable=YES;
        }else{
            self.contentAvailable=NO;
        }
        
        
        if (aps[@"mutable-content"] && [aps[@"mutable-content"] intValue]==1){
            self.mutableContent=YES;
        }else{
            self.mutableContent=NO;
        }

        [self decodeConversationItemWithSequenceValue:q];
        [self decodeSequenceValue:q];

    
    
        //find the conversationRef in the lookup
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *queueIDConversationLookup = [defaults objectForKey:@"ConversationQueueIDLookup"];
    
        //deserialize the ref
        NSString *serializedConversationRef = [queueIDConversationLookup objectForKey:[self.queueId QUIDString]];
        QredoConversationRef *conversationRef = [[QredoConversationRef alloc] initWithSerializedString:serializedConversationRef];
    
        //retrieve the conversation object using the ref
        [client fetchConversationWithRef:conversationRef completionHandler:^(QredoConversation *retrievedConversation, NSError *error) {
            if (error){
                completionHandler(nil,error);
            }else{
                self.conversation = retrievedConversation;

                
                //Create stream from Base64encoded data
                NSData *data = [[NSData alloc] initWithBase64EncodedString:q[@"d"] options:0];
                NSInputStream *readData = [[NSInputStream alloc] initWithData:data];
                [readData open];
                

                //create a reader
                QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:readData];
                
                //Strip off header (version info)
                [reader readMessageHeader];
                
                //Read ConversationItem with Sequence Value
                QLFConversationItemWithSequenceValue *val =  [QLFConversationItemWithSequenceValue unmarshaller](reader);
                
                //Using conversation's keys, decrypt the message
                QLFEncryptedConversationItem *conversationItem = val.item;
                QLFConversationMessage *message = [self.conversation decryptMessage:conversationItem];
                
                
                //Build the full QredoConversationMessage from it
                self.conversationMessage = [[QredoConversationMessage alloc] initWithMessageLF:message incoming:YES];
                self.incomingMessageText = [[NSString alloc] initWithData:self.conversationMessage.value encoding:NSUTF8StringEncoding];
                
                completionHandler(self, nil);
            }
        }];
}



-(QredoConversation*)buildConversationFromQueueID:(QredoQUID*)queueID{
 
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

-(QredoWireFormatReader*)wireFormatReaderFromString:(NSString*)base64Data{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Data options:0];
    NSInputStream *readData = [[NSInputStream alloc] initWithData:data];
    [readData open];
    QredoWireFormatReader *reader = [QredoWireFormatReader wireFormatReaderWithInputStream:readData];
    return reader;
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
    return incomingQueueID;
}





- (NSString *)description{
    NSMutableString *dump = [[NSMutableString alloc] init];
    [dump appendFormat:@"\nAlert:               %@\n",self.alert];
    
    switch (self.messageType) {
        case QREDO_PUSH_CONVERSATION_MESSAGE:{
            [dump appendString:@"Type:                Conversation\n"];
            [dump appendFormat:@"ConversationMessage: %@\n",self.incomingMessageText];
            break;
        }
        default:
            [dump appendString:@"Type: **UNKNOWN**\n"];
            break;
    }
    
    [dump appendFormat:@"QueueId:             %@\n",self.queueId];
    [dump appendFormat:@"ConversationId:      %@\n",self.conversation.metadata.conversationId];

    
    
    return [dump copy];
}


@end
