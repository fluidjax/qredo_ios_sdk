/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoPrivate.h"
#import <XCTest/XCTest.h>




@interface TestRendezvousListener :NSObject <QredoRendezvousObserver>
@property XCTestExpectation *expectation;
@property QredoConversation *incomingConversation;
@property int count;
@end



@interface TestConversationMessageListener :NSObject <QredoConversationObserver>
@property NSString *expectedMessageValue;
@property BOOL failed;

@property BOOL listening;
@property XCTestExpectation *expectation;
@property NSNumber *fulfilledtime;
@end


@interface TestVaultListener :NSObject<QredoVaultObserver>
@property XCTestExpectation *didReceiveVaultItemMetadataExpectation;
@property XCTestExpectation *didFailWithErrorExpectation;
@property NSMutableArray *receivedItems;
@property NSError *error;
@end
