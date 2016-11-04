/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoPrivate.h"

//#define QLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define QLog(...)


@interface QredoXCTestCase :XCTestCase {
    NSString *k_TEST_APPID;
    NSString *k_TEST_APPSECRET;
    
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


@property (nonatomic) QredoClientOptionsTransportType transportType;

/* -------------------------------------------------------------------------------------------------------------------------------- */


/* Build the pre-defined test stacks  */
-(void)buildStack1; //2 clients - create rendezvous, respond to rendezvous
-(void)buildStack2; //2 clients - create rendezvous, respond to rendezvous, C2 message to C1, C1 message to C2


/* -------------------------------------------------------------------------------------------------------------------------------- */

/* Generate Clients */
-(void)createClients;
-(void)createClient1;
-(void)createClient2;
-(QredoClient *)createClient:(NSString *)userSecret user:(NSString*)user;


/* Rendezvous */
-(void)createRendezvous;
-(QredoConversation *)simpleRespondToRendezvous:(NSString *)tag;
-(void)respondToRendezvous;
-(int)countConversationsOnRendezvous:(QredoRendezvous *)rendezvous;
-(int)countConversationsOnClient:(QredoClient *)client;



/* Messages */
-(void)sendConversationMessageFrom1to2;
-(void)sendConversationMessageFrom2to1;
-(void)sendMessageFrom:(QredoConversation *)fromConversation to:(QredoConversation *)toConversation;


/* Vault */
-(QredoVaultItemMetadata *)createVaultItem;
-(QredoVaultItemMetadata *)updateVaultItem:(QredoVaultItem *)originalItem;
-(QredoVaultItemDescriptor *)deleteVaultItem:(QredoVaultItemMetadata *)originalMetadata;
-(QredoVaultItem *)getVaultItem:(QredoVaultItemDescriptor *)descriptor;
-(int)countEnumAllVaultItemsOnServer;
-(int)countEnumAllVaultItemsOnServerFromWatermark:(QredoVaultHighWatermark *)highWatermark;

/* Index */
-(int)countMetadataItemsInIndex;


-(QredoClientOptions *)clientOptions:(BOOL)resetData;





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

@end
