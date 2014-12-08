/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class RendezvousBlockDelegate : NSObject, QredoRendezvousDelegate {
    var responseHandler : ((QredoConversation) -> Void)? = nil

    func qredoRendezvous(rendezvous: QredoRendezvous!, didReceiveReponse conversation: QredoConversation!) {
        responseHandler?(conversation)
    }
}

class KeychainSenderMock : NSObject, QredoKeychainSenderDelegate {
    enum State {
        case Idle
        case DiscoveredRendezvous
        case VerifiedRendezvous
        case EstablishedConnection
        case ConfirmedConnection
        case Failed
        case Completed
    }

    var state : State = .Idle
    var shouldCancelAt : State? = nil

    var shouldPassConfirmation = false
    var shouldDiscoverTag = "a test tag"

    var didCallDiscoverRendezvous = false
    var didCallEstablishedConnection = false
    var didCallFail = false
    var didCallFinishSending = false

    var didVerifyTag : Bool? = nil

    var cancelHandler : (() -> Void)! = nil
    var stateHandler : ((State) -> Void)! = nil

    func switchState(state: State) -> Bool {
        self.state = state

        if let actualStateHandler = stateHandler {
            stateHandler(state)
        }

        if shouldCancelAt == state {
            cancelHandler()
            return true
        }
        return false
    }

    // Delegate methods

    func qredoKeychainSenderDiscoverRendezvous(sender: QredoKeychainSender!, completionHander completionHandler: ((/*rendezvousTag:*/ String!) -> Bool)!, cancelHandler: (() -> Void)!) {
        didCallDiscoverRendezvous = true

        self.cancelHandler = cancelHandler

        // If we want to cancel scanning
        if switchState(.Idle) { return }
        if switchState(.DiscoveredRendezvous) { return }

        didVerifyTag = completionHandler(shouldDiscoverTag)

        if didVerifyTag == true {
            if switchState(.VerifiedRendezvous) { return }
        }
    }

    func qredoKeychainSender(sender: QredoKeychainSender!, didEstablishConnectionWithDevice deviceInfo: QredoDeviceInfo!, fingerprint: String!, confirmationHandler: ((/*confirmed:*/ Bool) -> Void)!) {
        didCallEstablishedConnection = true

        if switchState(.EstablishedConnection) { return }
        confirmationHandler(shouldPassConfirmation);
        if switchState(.ConfirmedConnection) { return }
    }

    func qredoKeychainSender(sender: QredoKeychainSender!, didFailWithError error: NSError!) {
        didCallFail = true

        if switchState(.Failed) { return }
    }

    func qredoKeychainSenderDidFinishSending(sender: QredoKeychainSender!) {
        didCallFinishSending = true

        if switchState(.Completed) { return }
    }

}

class KeychainTransporterSenderTests: XCTestCase {
    var senderClient : QredoClient!
    var receiverClient : QredoClient!

    override func setUp() {
        super.setUp()

        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: QredoClientOptions(resetData: true)) { client, error in
            XCTAssertNil(error, "Failed to authenticate the test")
            XCTAssertNotNil(client, "Client should not be nil")

            self.senderClient = client
        }

        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: QredoClientOptions(resetData: true)) { client, error in
            XCTAssertNil(error, "Failed to authenticate the test")
            XCTAssertNotNil(client, "Client should not be nil")

            self.receiverClient = client
        }
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
        senderMock.shouldDiscoverTag = QredoQUID().QUIDString()
        senderMock.shouldCancelAt = .VerifiedRendezvous

        var completionHandlerCalls = 0
        sender.startWithCompletionHandler { error in
            completionHandlerCalls++
            XCTAssertNotNil(error, "There should be a cancelation error")
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
        senderMock.shouldDiscoverTag = QredoQUID().QUIDString()

        sender.startWithCompletionHandler { error in
            XCTAssertNotNil(error, "Should not find rendezvous with the tag")
            senderCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertTrue(senderMock.didVerifyTag == true, "should verify the tag")
        XCTAssertEqual(senderMock.state, KeychainSenderMock.State.Failed, "should pass verification, tag is a valid QUID")
    }

    func testKeychainSenderWrongConversationType() {
        let rendezvousTag = QredoQUID().QUIDString()

        let rendezvousExpectation = self.expectationWithDescription("new rendezvous")
        receiverClient.createRendezvousWithTag(rendezvousTag, configuration: QredoRendezvousConfiguration(conversationType: "invalid type", durationSeconds: 60, maxResponseCount: 1)) { rendezvous, error in
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
        var transporterConversation : QredoConversation? = nil

        let rendezvousDelegate = RendezvousBlockDelegate()
        rendezvousDelegate.responseHandler = { conversation in
            transporterConversation = conversation

            transporterConversation?.publishMessage(QredoConversationMessage(value: nil, dataType: QredoKeychainTransporterMessageKeyDeviceName, summaryValues: [:]), completionHandler: { watermark, error in
                XCTAssertNil(error, "failed to publish device info")
            })
        }

        let rendezvousExpectation = self.expectationWithDescription("new rendezvous")
        receiverClient.createRendezvousWithTag(rendezvousTag, configuration: QredoRendezvousConfiguration(conversationType: QredoKeychainTransporterConversationType, durationSeconds: 60, maxResponseCount: 1)) { rendezvous, error in
            XCTAssertNil(error, "failed to create rendezvous")
            XCTAssertNotNil(rendezvous, "rendezvous should not be nil")

            rendezvous.delegate = rendezvousDelegate
            rendezvous.startListening()

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
            XCTAssertNotNil(error, "Should fail to parse the device info")
            senderCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertNotNil(transporterConversation, "should get response to the rendezvous")
        XCTAssertFalse(senderMock.didCallEstablishedConnection, "Should not establish connection with the wrong conversation type")
        XCTAssertEqual(senderMock.state, KeychainSenderMock.State.Failed, "should pass verification, tag is a valid QUID")
    }

}
