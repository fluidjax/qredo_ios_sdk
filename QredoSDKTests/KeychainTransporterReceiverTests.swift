/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class ConversationBlockDelegate : NSObject, QredoConversationDelegate {
    var messageHandler: ((QredoConversationMessage) -> Void)? = nil
    func qredoConversation(conversation: QredoConversation!, didReceiveNewMessage message: QredoConversationMessage!) {
        messageHandler?(message)
    }
}

class KeychainReceiverMock : NSObject, QredoKeychainReceiverDelegate {
    enum State {
        case Idle
        case Prepared
        case CreatedRendezvous
        case EstablishedConnection
        case ReceivedKeychain
        case InstalledKeychain
        case Failed
    }

    var state : State = .Idle
    var shouldCancelAt : State? = nil
    var cancelHandler : (() -> Void)! = nil
    var stateHandler : ((State) -> Void)! = nil

    var shouldPassConfirmation = false

    var didCallWillCreateRendezvous = false
    var didCallDidCreateRendezvous = false
    var didCallDidEstablishConnection = false
    var didCallDidFail = false
    var didCallDidReceiveKeychain = false

    var rendezvousTag : String? = nil
    var connectionFingerprint : String? = nil


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

    func qredoKeychainReceiverWillCreateRendezvous(receiver: QredoKeychainReceiver!, cancelHandler: (() -> Void)!) {
        didCallWillCreateRendezvous = true

        self.cancelHandler = cancelHandler

        if switchState(.Idle) { return }
        if switchState(.Prepared) { return }
    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didCreateRendezvousWithTag tag: String!) {
        didCallDidCreateRendezvous = true

        rendezvousTag = tag
        if switchState(.CreatedRendezvous) { return }
    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didEstablishConnectionWithFingerprint fingerPrint: String!) {
        didCallDidEstablishConnection = true

        connectionFingerprint = fingerPrint

        if switchState(.EstablishedConnection) { return }
    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didFailWithError error: NSError!) {
        didCallDidFail = true

        if switchState(.Failed) { return }
    }

    func qredoKeychainReceiverDidReceiveKeychain(receiver: QredoKeychainReceiver!, confirmationHandler: ((Bool) -> Void)!) {
        didCallDidReceiveKeychain = true

        if switchState(.ReceivedKeychain) { return }

        confirmationHandler(shouldPassConfirmation)

        if shouldPassConfirmation {
            if switchState(.InstalledKeychain) { return }
        }
    }
}


class KeychainTransporterReceiverTests: XCTestCase {
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

    func testCancelBeforeCreatingRendezvous() {
        let receiverMock = KeychainReceiverMock()
        let receiver = QredoKeychainReceiver(client: receiverClient, delegate: receiverMock)

        let receiverCompletionExpectation = self.expectationWithDescription("receiver completion")

        receiverMock.shouldCancelAt = .Prepared

        receiver.startWithCompletionHandler { error in
            XCTAssertNotNil(error, "Should be the cancellation error")
            receiverCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertTrue(receiverMock.didCallWillCreateRendezvous, "should prepare the receiver delegate")
        XCTAssertFalse(receiverMock.didCallDidCreateRendezvous, "should cancel before the rendezvous is created")
    }

    func testCancelAfterCreatingRendezvous() {
        let receiverMock = KeychainReceiverMock()
        let receiver = QredoKeychainReceiver(client: receiverClient, delegate: receiverMock)

        var receiverCompletionExpectation : XCTestExpectation? = self.expectationWithDescription("receiver completion")

        receiverMock.shouldCancelAt = .CreatedRendezvous

        var completionHandlerCalls = 0
        receiver.startWithCompletionHandler { error in
            completionHandlerCalls++
            XCTAssertNotNil(error, "Should be the cancellation error")

            receiverCompletionExpectation?.fulfill()
            receiverCompletionExpectation = nil
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(completionHandlerCalls, 1, "should call the completion handler only once")
        XCTAssertTrue(receiverMock.didCallWillCreateRendezvous, "should prepare the receiver delegate")
        XCTAssertTrue(receiverMock.didCallDidCreateRendezvous, "should create the rendezvous")

        XCTAssertNotNil(receiverMock.rendezvousTag, "rendezvous tag should not be nil")
    }


    func testEstablishingConnection() {
        let receiverMock = KeychainReceiverMock()
        let receiver = QredoKeychainReceiver(client: receiverClient, delegate: receiverMock)

        var receiverCompletionExpectation : XCTestExpectation? = self.expectationWithDescription("receiver completion")
        var deviceInfoExpectation = self.expectationWithDescription("receive device info")

        var conversationDelegate = ConversationBlockDelegate()
        conversationDelegate.messageHandler = { message in
            println(message.summaryValues)
            deviceInfoExpectation.fulfill()
        }

        receiverMock.stateHandler = { state in
            if state == .CreatedRendezvous {
                XCTAssertNotNil(receiverMock.rendezvousTag, "rendezvous tag should not be nil")
                self.senderClient.respondWithTag(receiverMock.rendezvousTag, completionHandler: { (conversation, error) -> Void in
                    XCTAssertNotNil(conversation, "failed to respond to the rendezvous")
                    conversation.delegate = conversationDelegate
                    conversation.startListening()
                })
            }
        }

        receiverMock.shouldCancelAt = .EstablishedConnection

        var completionHandlerCalls = 0
        receiver.startWithCompletionHandler { error in
            completionHandlerCalls++
            XCTAssertNotNil(error, "Should be the cancellation error")

            receiverCompletionExpectation?.fulfill()
            receiverCompletionExpectation = nil
        }

        // double timeout, because we are doing quite a few operations here
        self.waitForExpectationsWithTimeout(2 * qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(completionHandlerCalls, 1, "should call the completion handler only once")
        XCTAssertTrue(receiverMock.didCallWillCreateRendezvous, "should prepare the receiver delegate")
        XCTAssertTrue(receiverMock.didCallDidCreateRendezvous, "should create the rendezvous")
        XCTAssertTrue(receiverMock.didCallDidEstablishConnection, "should establish the connection")
        XCTAssertNotNil(receiverMock.connectionFingerprint, "should have connection fingerprint")
        if let fingerprint = receiverMock.connectionFingerprint {
            XCTAssertEqual(fingerprint.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), QredoKeychainTransporterFingerprintLength, "Fingerprint length mismatch")
        }
    }


    func checkInvalidKeychainData(keychainMessage: QredoConversationMessage) {
        let receiverMock = KeychainReceiverMock()
        let receiver = QredoKeychainReceiver(client: receiverClient, delegate: receiverMock)

        var receiverCompletionExpectation : XCTestExpectation? = self.expectationWithDescription("receiver completion")
        var deviceInfoExpectation = self.expectationWithDescription("receive device info")
        var publishInvalidKeychain = self.expectationWithDescription("publish keychain")
        var acknowledgeExpectation = self.expectationWithDescription("confirm or cancel message")

        var transporterConversation : QredoConversation? = nil

        var conversationDelegate = ConversationBlockDelegate()
        conversationDelegate.messageHandler = { (message:QredoConversationMessage) -> Void in

            switch message.dataType {
            case QredoKeychainTransporterMessageTypeDeviceInfo:
                deviceInfoExpectation.fulfill()

                transporterConversation?.publishMessage(keychainMessage, completionHandler: { (highwatermark, error) -> Void in
                    XCTAssertNil(error, "failed to send the message")
                    publishInvalidKeychain.fulfill()
                })

            case QredoKeychainTransporterMessageTypeConfirmReceiving:
                XCTFail("Should not confirm")
                acknowledgeExpectation.fulfill()

            case QredoKeychainTransporterMessageTypeCancelReceiving:
                acknowledgeExpectation.fulfill()

            default:
                XCTFail("Unknown message type: \(message.dataType)")
            }

        }

        receiverMock.stateHandler = { state in
            if state == .CreatedRendezvous {
                XCTAssertNotNil(receiverMock.rendezvousTag, "rendezvous tag should not be nil")
                self.senderClient.respondWithTag(receiverMock.rendezvousTag, completionHandler: { (conversation, error) -> Void in
                    XCTAssertNotNil(conversation, "failed to respond to the rendezvous")
                    transporterConversation = conversation
                    conversation.delegate = conversationDelegate
                    conversation.startListening()
                })
            }
        }

        var completionHandlerCalls = 0
        receiver.startWithCompletionHandler { error in
            completionHandlerCalls++
            XCTAssertNotNil(error, "Should be the cancellation error")

            receiverCompletionExpectation?.fulfill()
            receiverCompletionExpectation = nil
        }

        // double timeout, because we are doing quite a few operations here
        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(completionHandlerCalls, 1, "should call the completion handler only once")
        XCTAssertFalse(receiverMock.didCallDidReceiveKeychain, "Should not receive keychain")
    }

    func testInvalidKeychainMessageType() {
        checkInvalidKeychainData(QredoConversationMessage(value: "hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), dataType: "invalid type", summaryValues: [:]))
    }

    func testInvalidKeychainMessageData() {
        checkInvalidKeychainData(QredoConversationMessage(value: "hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), dataType: QredoKeychainTransporterMessageTypeKeychain, summaryValues: [:]))
    }

}
