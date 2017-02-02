/* HEADER GOES HERE */
#import "QredoXCTestListeners.h"
#import "Qredo.h"
#import "QredoPrivate.h"
#import <XCTest/XCTest.h>



@implementation TestRendezvousListener
XCTestExpectation *timeoutExpectation;

-(void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation {
    if (self.expectation){
        NSLog(@"2Incoming Listener response");
        self.incomingConversation = conversation;
        [self.expectation fulfill];
    }
}


@end


@implementation TestConversationMessageListener


-(void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message {
    //Can't use XCTAsset, because this class is not QredoXCTestCase
    
    @synchronized(self) {
        if (_listening){
            self.failed |= (message == nil);
            self.failed |= !([message.value isEqualToData:[self.expectedMessageValue dataUsingEncoding:NSUTF8StringEncoding]]);
            
            _fulfilledtime = @(_fulfilledtime.intValue + 1);
            _listening = NO;
            [_expectation fulfill];
        }
    }
}


@end




@implementation TestVaultListener

-(void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error {
    self.error = error;
    
    if (self.didFailWithErrorExpectation){
        [self.didFailWithErrorExpectation fulfill];
    }
}


-(void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata {
    if (!self.receivedItems){
        self.receivedItems = [NSMutableArray array];
    }
    
    [self.receivedItems addObject:itemMetadata];
    
    if (self.didReceiveVaultItemMetadataExpectation){
        [self.didReceiveVaultItemMetadataExpectation fulfill];
    }
}


@end
