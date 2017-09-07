/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoKeyRef.h"


static float WAIT_FOR_LISTENER_TO_PROCESS_DELAY = 1.0;

//Extensions to QredoKeyRef to allow extracting of raw (Private) Key Data for testing purposes 
@interface QredoKeyRef (testing)
-(void)dump;
-(NSData*)debugValue;
@end



@interface QredoXCTestCase :XCTestCase {
    NSString *k_TEST_APPID;
    NSString *k_TEST_APPSECRET;
    
    NSString *k_TEST_USERID;
    NSString *k_TEST_USERSECRET;
    
    NSString *k_TEST_USERID2;
    NSString *k_TEST_USERSECRET2;

    
    //client
    QredoClient *testClient1;
    NSString *testClient1Password;
    NSString *testClient1User;
    
    QredoClient *testClient2;
    NSString *testClient2Password;
    NSString *testClient2User;
    
    
    //rendezvous
    QredoRendezvous *rendezvous1;
    
    NSString *rendezvous1Tag;
    
    
    //conversation
    QredoConversation *conversation1;
    QredoConversation *conversation2;
    
    //
    QredoConversationHighWatermark *conversationHWM;
}

@property (strong) QredoClientOptions *clientOptions;
@property (nonatomic) QredoClientOptionsTransportType transportType;



/* -------------------------------------------------------------------------------------------------------------------------------- */


/* Build the pre-defined test stacks  */

-(void)buildFixedCredentialStack1; //2 clients - create rendezvous, respond to rendezvous but preset credntials
-(void)buildStack1; //2 clients - create rendezvous, respond to rendezvous
-(void)buildStack2; //2 clients - create rendezvous, respond to rendezvous, C2 message to C1, C1 message to C2


/* -------------------------------------------------------------------------------------------------------------------------------- */

/* Generate Clients */
-(void)createRandomClients;
-(void)createRandomClient1;
-(void)createRandomClient2;
-(QredoClient *)createClientWithAppID:(NSString *)appId
                            appSecret:(NSString *)appSecret
                               userId:(NSString *)userId
                           userSecret:(NSString *)userSecret;


/* Rendezvous */
-(void)createRendezvous;
-(QredoConversation *)simpleRespondToRendezvous:(NSString *)tag;
-(void)respondToRendezvous;
-(int)countConversationsOnRendezvous:(QredoRendezvous *)rendezvous;
-(int)countConversationsOnClient:(QredoClient *)client;



/* Messages */
-(void)sendConversationMessageFrom1to2;
-(void)sendConversationMessageFrom2to1;
-(QredoConversationHighWatermark*)sendMessageFrom:(QredoConversation *)fromConversation to:(QredoConversation *)toConversation;


/* Vault */
-(QredoVaultItemMetadata *)createVaultItem;
-(QredoVaultItemMetadata *)updateVaultItem:(QredoVaultItem *)originalItem;
-(QredoVaultItemDescriptor *)deleteVaultItem:(QredoVaultItemMetadata *)originalMetadata;
-(QredoVaultItem *)getVaultItem:(QredoVaultItemDescriptor *)descriptor;
-(int)countEnumAllVaultItemsOnServer;
-(int)countEnumAllVaultItemsOnServerFromWatermark:(QredoVaultHighWatermark *)highWatermark;

/* Index */
-(int)countMetadataItemsInIndex;


-(QredoClientOptions *)clientOptions;





/* -------------------------------------------------------------------------------------------------------------------------------- */


/* Utility Methods for Gewneral Testing */
-(void)loggingOff;
-(void)loggingOn;
-(void)resetKeychain;
-(void)deleteAllKeysForSecClass:(CFTypeRef)secClass;

-(NSData *)randomDataWithLength:(int)length;
-(NSString *)randomStringWithLength:(int)len;
-(NSString *)randomPassword;
-(NSString *)randomUsername;

-(void)pauseForListenerToRegister;

@end
