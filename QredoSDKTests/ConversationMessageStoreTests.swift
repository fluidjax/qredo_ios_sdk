/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class ConversationMessageStoreTests: BaseConversation {

    override func setUp() {
        super.setUp()

        XCTAssertNotNil(responderConversation, "failed to create responder conversation")
        XCTAssertNotNil(creatorConversation, "failed to create creator conversation")
        XCTAssertTrue(responderConversation.metadata().persistent, "conversation should be persistent")
        XCTAssertTrue(creatorConversation.metadata().persistent, "conversation should be persistent")
    }

    func testStorage() {
        // message from responder
        var message1Expectation : XCTestExpectation? = expectationWithDescription("message 1 sent")
        let message1 = QredoConversationMessage(value: nil, dataType: "com.qredo.test", summaryValues: ["title" : "1c"]);
        responderConversation.publishMessage(message1, completionHandler: { hwm, error in
            XCTAssertNil(error, "failed to send a message")
            message1Expectation?.fulfill()
        })

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { error in
            message1Expectation = nil
        })

        // message from creator
        var message2Expectation : XCTestExpectation? = expectationWithDescription("message 2 sent")
        let message2 = QredoConversationMessage(value: nil, dataType: "com.qredo.test", summaryValues: ["title" : "2c"]);
        creatorConversation.publishMessage(message2, completionHandler: { hwm, error in
            XCTAssertNil(error, "failed to send a message")
            message2Expectation?.fulfill()
        })

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { error in
            message2Expectation = nil
        })


        // waiting for the messages to arrive
        let responderDelegate = ConversationBlockDelegate()
        var totalMessageCount = 0
        let expectMessagesCount = 2

        var messageArrivedExpectation : XCTestExpectation? = expectationWithDescription("messages arrived")

        responderDelegate.messageHandler = { message in
            totalMessageCount++

            if totalMessageCount == expectMessagesCount {
                messageArrivedExpectation?.fulfill()
                messageArrivedExpectation = nil
            }

            XCTAssert(totalMessageCount <= expectMessagesCount, "Recevied more messages than expected")
        }
        responderConversation.addConversationObserver(responderDelegate)
        creatorConversation.addConversationObserver(responderDelegate)

        
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            messageArrivedExpectation = nil
        })

        XCTAssertEqual(totalMessageCount, expectMessagesCount, "Didn't receive the messages, or received more than expected")


        let responderStore = responderConversation.store()
        XCTAssertNotNil(responderStore, "store should not be nil")

        let creatorStore = creatorConversation.store()
        XCTAssertNotNil(creatorConversation, "store should not be nil")


        var responderStoreExpectation : XCTestExpectation? = expectationWithDescription("responder store")
        var responderStoreItems = 0
        var mineMessages = 0
        responderStore.enumerateVaultItemsUsingBlock({ (vaultItemMetadata : QredoVaultItemMetadata!, stop) -> Void in
            responderStoreItems++
            let isMine = vaultItemMetadata.summaryValues["_mine"] as? NSNumber
            if let value = isMine?.boolValue {
                if value == true {
                    mineMessages++
                }
            }

            println(vaultItemMetadata.summaryValues)
        }, completionHandler: { error in
            XCTAssertNil(error, "failed to enumerate store")
            responderStoreExpectation?.fulfill()
        })

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            responderStoreExpectation = nil
        })

        XCTAssertEqual(responderStoreItems, totalMessageCount, "Didn't get all the expected messages in the store")
        XCTAssertEqual(mineMessages, 1, "Should be just 1 my message")
        
        responderConversation.removeConversationObserver(responderDelegate)
        creatorConversation.removeConversationObserver(responderDelegate)

    }
    
}
