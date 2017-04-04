//
//  QredoPushMessage.m
//  QredoSDK
//
//  Created by Christopher Morris on 06/02/2017.
//
//

#import "QredoPushMessage.h"
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoConversationPrivate.h"
#import "QredoConversationMessagePrivate.h"

@interface QredoPushMessage ()
@property (readwrite) NSString* alert;
@property (assign,readwrite) BOOL contentAvailable;
@property (assign,readwrite) BOOL mutableContent;
@property (assign,readwrite) QredoPushMessageType messageType;
@property (readwrite) QredoQUID *queueId;
@property (readwrite) QredoClient *client;
@property (readwrite) QredoConversation *conversation;
@property (readwrite) QredoConversationMessage *conversationMessage;
@property (readwrite) QredoConversationRef *conversationRef;
@property (readwrite) NSNumber *sequenceValue;
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


+(void)initializeWithRemoteNotification:(NSDictionary*)message
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler{
    [[QredoPushMessage alloc] initializeWithRemoteNotification:message
                                             completionHandler:^(QredoPushMessage *pushMessage, NSError *error) {
                                                 completionHandler(pushMessage,error);
                                             }];
    
}


-(void)initializeWithRemoteNotification:(NSDictionary*)message
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler{
    //Process the incoming Qredo Notification where a QredoClient is not available
    NSDictionary *aps = message[@"aps"];
    NSDictionary *q = message[@"q"];
    
    if (!aps || !q){
        NSLog(@"Invalid message");
        completionHandler(nil, [NSError errorWithDomain:@"qredopushmessage" code:1000 userInfo:nil]);
        return;
    }
    
    self.alert        = aps[@"alert"][@"body"];
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
    
    
    
//    //find the conversationRef in the lookup
//    NSDictionary *queueIDConversationLookup = [[client userDefaults] objectForKey:@"ConversationQueueIDLookup"];
//    
//    //deserialize the ref
//    NSString *serializedConversationRef = [queueIDConversationLookup objectForKey:[self.queueId QUIDString]];
//    self.conversationRef = [[QredoConversationRef alloc] initWithSerializedString:serializedConversationRef];
//    completionHandler(self,nil);
//    
}




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
    
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *appGroup = client.clientOptions.appGroup;
    
    if (appGroup)userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroup];

    
    NSLog(@"**100 Userdefaults %@",userDefaults);
    
    
    NSDictionary *queueIDConversationLookup = [userDefaults objectForKey:@"ConversationQueueIDLookup"];
    
    //deserialize the ref
    NSString *serializedConversationRef = [queueIDConversationLookup objectForKey:[self.queueId QUIDString]];
    self.conversationRef = [[QredoConversationRef alloc] initWithSerializedString:serializedConversationRef];
    
    //retrieve the conversation object using the ref
    [client fetchConversationWithRef:self.conversationRef completionHandler:^(QredoConversation *retrievedConversation, NSError *error) {
        if (error){
            self.conversation = nil;
            completionHandler(nil,error);
        }else{
            self.conversation = retrievedConversation;
            
            if ([self isBigPayload:q]){
                [self decodeConversationWithSequenceValue:q];
            }else{
                //small payload
                [self decodeSequenceValue:q];
            }
            completionHandler(self, nil);
        }
    }];
}






#pragma Private methods

- (void)decodeConversationWithSequenceValue:(NSDictionary *)data{
    //Create stream from Base64encoded data
    NSData *dataD = [[NSData alloc] initWithBase64EncodedString:data[@"d"] options:0];
    NSInputStream *readDataD = [[NSInputStream alloc] initWithData:dataD];
    [readDataD open];
    //create a reader
    QredoWireFormatReader *readerD = [QredoWireFormatReader wireFormatReaderWithInputStream:readDataD];
    //Strip off header (version info)
    [readerD readMessageHeader];
    //Read ConversationItem with Sequence Value
    QLFConversationItemWithSequenceValue *valD =  [QLFConversationItemWithSequenceValue unmarshaller](readerD);
    //Using conversation's keys, decrypt the message
    QLFEncryptedConversationItem *conversationItem = valD.item;
    QLFConversationMessage *message = [self.conversation decryptMessage:conversationItem];
    //Build the full QredoConversationMessage from it
    self.conversationMessage = [[QredoConversationMessage alloc] initWithMessageLF:message incoming:YES];
    self.incomingMessageText = [[NSString alloc] initWithData:self.conversationMessage.value encoding:NSUTF8StringEncoding];
    self.sequenceValue = [self decodeRawSequenceValue:valD.sequenceValue];
}





- (void)decodeSequenceValue:(NSDictionary *)q{
    //Create stream from Base64encoded data
    NSData *dataS = [[NSData alloc] initWithBase64EncodedString:q[@"s"] options:0];
    NSInputStream *readDataS = [[NSInputStream alloc] initWithData:dataS];
    [readDataS open];
    //create a reader
    QredoWireFormatReader *readerS = [QredoWireFormatReader wireFormatReaderWithInputStream:readDataS];
    //Strip off header (version info)
    [readerS readMessageHeader];
    NSData *sequenceValueRawData  = [readerS readByteSequence];
    self.sequenceValue = [self decodeRawSequenceValue:sequenceValueRawData];
}


-(NSNumber*)decodeRawSequenceValue:(NSData*)rawdata{
    uint32_t seqVal;
    [rawdata getBytes:&seqVal range:NSMakeRange(0,4)];
    NSNumber *s = @(CFSwapInt32BigToHost(seqVal));
    return s;
}




-(QredoConversation*)buildConversationFromQueueID:(QredoQUID*)queueID{
 
    return nil;
    
}


-(BOOL)isBigPayload:(NSDictionary*)q{
    if (q[@"s"])return NO;
    return YES;
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
    [reader readMessageHeader];
    QredoQUID *incomingQueueID = (QredoQUID*)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
    return incomingQueueID;
}



-(NSString *)description{
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
    [dump appendFormat:@"SequenceValue:       %@\n",self.sequenceValue];
    return [dump copy];
}


@end
