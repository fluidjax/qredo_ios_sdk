/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class KeychainTransporterSenderTests: XCTestCase {
    var senderClient : QredoClient!
    var receiverClient : QredoClient!

    override func setUp() {
        super.setUp()

        let senderClientExpectation = expectationWithDescription("sender client")
        let receiverClientExpectation = expectationWithDescription("receiver client")
        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: QredoClientOptions.qtu_clientOptionsWithResetData(true)) { client, error in
            XCTAssertNil(error, "Failed to authenticate the test")
            XCTAssertNotNil(client, "Client should not be nil")

            self.senderClient = client
            senderClientExpectation.fulfill()
        }

        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: QredoClientOptions.qtu_clientOptionsWithResetData(true)) { client, error in
            XCTAssertNil(error, "Failed to authenticate the test")
            XCTAssertNotNil(client, "Client should not be nil")

            self.receiverClient = client
            receiverClientExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

    }
    

    func testKeychainSenderInvalidTag() {
        let senderMock = KeychainSenderMock()
        let sender = QredoKeychainSender(client: senderClient, delegate: senderMock)

        let senderCompletionExpectation = self.expectationWithDescription("sender completion")

        senderMock.shouldPassConfirmation = false
        senderMock.shouldDiscoverTag = "a random, non-QUID, tag"

        sender.startWithCompletionHandler { error in
            XCTAssertNotNil(error, "There should be a verification error")
            senderCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(senderMock.state, KeychainSenderMock.State.DiscoveredRendezvous, "should not pass verification, tag is not a QUID")
        XCTAssertTrue(senderMock.didCallDiscoverRendezvous, "should call qredoKeychainSenderDiscoverRendezvous")
    }

    func testKeychainSenderValidTag() {
        let senderMock = KeychainSenderMock()
        let sender = QredoKeychainSender(client: senderClient, delegate: senderMock)

        var senderCompletionExpectation : XCTestExpectation? = self.expectationWithDescription("sender completion")

        senderMock.shouldPassConfirmation = false
        senderMock.shouldDiscoverTag = QredoRendezvousURIProtocol.stringByAppendingString(QredoQUID().QUIDString())
        senderMock.shouldCancelAt = .VerifiedRendezvous

        var completionHandlerCalls = 0
        sender.startWithCompletionHandler { error in
            completionHandlerCalls++
            XCTAssertNil(error, "There should finish without error")
            senderCompletionExpectation?.fulfill()
            senderCompletionExpectation = nil
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(completionHandlerCalls, 1, "Completion handler should be called only once")

        XCTAssertEqual(senderMock.state, KeychainSenderMock.State.VerifiedRendezvous, "should pass verification, tag is a valid QUID")
        XCTAssertTrue(senderMock.didCallDiscoverRendezvous, "should call qredoKeychainSenderDiscoverRendezvous")
        XCTAssertTrue(senderMock.didVerifyTag == true, "should verify the tag")
    }

    func testKeychainSenderFailConnection() {
        let senderMock = KeychainSenderMock()
        let sender = QredoKeychainSender(client: senderClient, delegate: senderMock)

        let senderCompletionExpectation = self.expectationWithDescription("sender completion")

        senderMock.shouldPassConfirmation = false
        senderMock.shouldDiscoverTag = QredoRendezvousURIProtocol.stringByAppendingString(QredoQUID().QUIDString())

        sender.startWithCompletionHandler { error in
            XCTAssertNotNil(error, "Should not find rendezvous with the tag")
            senderCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertTrue(senderMock.didVerifyTag == true, "should verify the tag")
        XCTAssertEqual(senderMock.state, KeychainSenderMock.State.Failed, "should pass verification, tag is a valid QUID")
    }

    func testKeychainSenderWrongConversationType() {
        let rendezvousTag = QredoRendezvousURIProtocol.stringByAppendingString(QredoQUID().QUIDString())

        let rendezvousExpectation = self.expectationWithDescription("new rendezvous")
        receiverClient.createAnonymousRendezvousWithTag(rendezvousTag, configuration: QredoRendezvousConfiguration(conversationType: "invalid type", durationSeconds: 60, maxResponseCount: 1)) { rendezvous, error in
            XCTAssertNil(error, "failed to create rendezvous")
            XCTAssertNotNil(rendezvous, "rendezvous should not be nil")

            rendezvousExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let senderMock = KeychainSenderMock()
        let sender = QredoKeychainSender(client: senderClient, delegate: senderMock)

        let senderCompletionExpectation = self.expectationWithDescription("sender completion")

        senderMock.shouldPassConfirmation = false
        senderMock.shouldDiscoverTag = rendezvousTag
        senderMock.shouldCancelAt = .EstablishedConnection // Should not get there

        sender.startWithCompletionHandler { error in
            XCTAssertNotNil(error, "Should detect mismatch of the conversation type")
            senderCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertFalse(senderMock.didCallEstablishedConnection, "Should not establish connection with the wrong conversation type")
        XCTAssertTrue(senderMock.didVerifyTag == true, "should verify the tag")
        XCTAssertEqual(senderMock.state, KeychainSenderMock.State.Failed, "should pass verification, tag is a valid QUID")
    }

    func testKeychainSenderWrongDeviceInfo() {
        let rendezvousTag = QredoQUID().QUIDString()
        let rendezvousTagWithURI = QredoRendezvousURIProtocol.stringByAppendingString(rendezvousTag)
        var transporterConversation : QredoConversation? = nil

        var publishDeviceInfoExpectation : XCTestExpectation?
        var receivedResponseExpectation : XCTestExpectation?

        let rendezvousDelegate = RendezvousBlockDelegate()
        rendezvousDelegate.responseHandler = { conversation in
            transporterConversation = conversation

            receivedResponseExpectation?.fulfill()

            transporterConversation?.publishMessage(
                QredoConversationMessage(
                    value: nil,
                    dataType: QredoKeychainTransporterMessageTypeDeviceInfo,
                    summaryValues: [:]),
                completionHandler: { watermark, error in
                    XCTAssertNil(error, "failed to publish device info")

                    publishDeviceInfoExpectation?.fulfill()
            })
        }

        var receiverRendezvous : QredoRendezvous?
        let rendezvousExpectation = self.expectationWithDescription("create rendezvous")
        receiverClient.createAnonymousRendezvousWithTag(rendezvousTag, configuration: QredoRendezvousConfiguration(conversationType: QredoKeychainTransporterConversationType, durationSeconds: 60, maxResponseCount: 1)) { rendezvous, error in
            XCTAssertNil(error, "failed to create rendezvous")
            XCTAssertNotNil(rendezvous, "rendezvous should not be nil")

            receiverRendezvous = rendezvous
            rendezvousExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        receiverRendezvous?.delegate = rendezvousDelegate
        receiverRendezvous?.startListening()

        let senderMock = KeychainSenderMock()
        let sender = QredoKeychainSender(client: senderClient, delegate: senderMock)

        let senderCompletionExpectation = self.expectationWithDescription("sender completion")
        receivedResponseExpectation = expectationWithDescription("received response to rendezvous")
        publishDeviceInfoExpectation = expectationWithDescription("publish device info message")

        senderMock.shouldPassConfirmation = false
        senderMock.shouldDiscoverTag = rendezvousTagWithURI
        senderMock.shouldCancelAt = .EstablishedConnection // Should not get there

        sender.startWithCompletionHandler { error in
            XCTAssertNotNil(error, "Should fail to parse the device info")
            senderCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(50, handler: nil)

        receiverRendezvous?.stopListening()

        XCTAssertNotNil(transporterConversation, "should get response to the rendezvous")

        XCTAssertTrue(senderMock.didCallDiscoverRendezvous, "Should discover rendezvous")
        XCTAssertFalse(senderMock.didCallEstablishedConnection, "Should not establish connection with the wrong conversation type")
        XCTAssertEqual(senderMock.state, KeychainSenderMock.State.Failed, "should pass verification, tag is a valid QUID")
    }

}
