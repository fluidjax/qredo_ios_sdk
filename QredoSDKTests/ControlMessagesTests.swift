/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class ControlMessagesTests: BaseConversation {
    func testJoinedControlMessage() {
        var joinedMessageCounter = 0

        let enumerationExpectation = expectationWithDescription("enumerate messages on responder")

        responderConversation.enumerateMessagesUsingBlock({ (message, stop) -> Void in
            if message.isControlMessage() && message.controlMessageType() == .Joined {
                joinedMessageCounter++
            }
        }, incoming: true, completionHandler: { (error) -> Void in
            enumerationExpectation.fulfill()
        }, since: QredoConversationHighWatermarkOrigin, highWatermarkHandler: nil, excludeControlMessages: false)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(joinedMessageCounter, 1, "Should be one 'joined' control message")
    }

    func commonDeleteControlMessage(conversationToBeDeleted : QredoConversation, listeningConversation : QredoConversation) {
        var listenerExpectation : XCTestExpectation? = expectationWithDescription("receive delete message responder")
        var deleteCompletionExpectation = expectationWithDescription("delete completion")

        conversationToBeDeleted.deleteConversationWithCompletionHandler { error -> Void in
            XCTAssertNil(error, "failed to delete conversation")
            deleteCompletionExpectation.fulfill()
        }

        var leftMessageCounter = 0

        let listeningDelegate = ConversationBlockDelegate()

        listeningDelegate.otherPartyLeftHandler = {

            leftMessageCounter++

            if leftMessageCounter == 1 {

                listenerExpectation?.fulfill()
                listenerExpectation = nil
            }
        }

        listeningConversation.delegate = listeningDelegate
        listeningConversation.startListening()

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { error in
            listenerExpectation = nil
        })
        
        XCTAssertEqual(leftMessageCounter, 1, "Should be one 'joined' control message")
    }


    func testDeleteControlMessageOnCreatorSide() {
        commonDeleteControlMessage(creatorConversation, listeningConversation: responderConversation)
    }


    func testDeleteControlMessageOnResponderSide() {
        commonDeleteControlMessage(responderConversation, listeningConversation: creatorConversation)
    }


    func commonPublishMessageAfterDeletion(conversation: QredoConversation, client : QredoClient) {
        let deleteExpectation = expectationWithDescription("delete conversation")

        conversation.deleteConversationWithCompletionHandler { (error) -> Void in
            XCTAssertNil(error, "failed to delete conversation")
            deleteExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let publishExpectation = expectationWithDescription("publish message")
        let messageValue = "hello, world".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let message = QredoConversationMessage(value: messageValue, dataType: plainTextMessageType, summaryValues: nil)
        conversation.publishMessage(message) {
            (highwatermark, error) -> Void in
            XCTAssertNotNil(error, "message should not be published after deleting the conversation")
            publishExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let fetchConversationExpectation = expectationWithDescription("fetch conversation")
        client.fetchConversationWithId(conversation.metadata().conversationId, completionHandler: { (conversation, error) -> Void in
            XCTAssertNotNil(error, "should fail to load the conversation")
            XCTAssertNil(conversation, "conversation should be nil")
            fetchConversationExpectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }

    func testPublishMessageAfterDeletionOnCreatorSide() {
        commonPublishMessageAfterDeletion(creatorConversation, client: creatorClient)
    }

    func testPublishMessageAfterDeletionOnResponderSide() {
        commonPublishMessageAfterDeletion(responderConversation, client: responderClient)
    }

}
