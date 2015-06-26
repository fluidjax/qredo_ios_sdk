/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class KeychainTransporterReceiverTests: XCTestCase {
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

    func stripURIPrefix(tag: String) -> String {
        let tagIndex = advance(tag.startIndex, QredoRendezvousURIProtocol.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        return tag.substringFromIndex(tagIndex)
    }

    func testCancelBeforeCreatingRendezvous() {
        let receiverMock = KeychainReceiverMock()
        let receiver = QredoKeychainReceiver(client: receiverClient, delegate: receiverMock)

        var receiverCompletionExpectation : XCTestExpectation? = self.expectationWithDescription("receiver completion")

        receiverMock.shouldCancelAt = .Prepared

        var completionHandlerCalls = 0

        receiver.startWithCompletionHandler { error in
            completionHandlerCalls++
            XCTAssertNil(error, "Should be the cancellation error")
            receiverCompletionExpectation?.fulfill()
            receiverCompletionExpectation = nil
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(completionHandlerCalls, 1, "should call the completion handler only once")
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
            XCTAssertNil(error, "Should be the cancellation error")

            receiverCompletionExpectation?.fulfill()
            receiverCompletionExpectation = nil
        }

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        XCTAssertEqual(completionHandlerCalls, 1, "should call the completion handler only once")
        XCTAssertTrue(receiverMock.didCallWillCreateRendezvous, "should prepare the receiver delegate")
        XCTAssertTrue(receiverMock.didCallDidCreateRendezvous, "should create the rendezvous")

        XCTAssertNotNil(receiverMock.rendezvousTag, "rendezvous tag should not be nil")
    }

    func testEstablishConnection() {
        let receiverMock = KeychainReceiverMock()
        let receiver = QredoKeychainReceiver(client: receiverClient, delegate: receiverMock)

        var receiverCompletionExpectation : XCTestExpectation? = self.expectationWithDescription("receiver completion")
        var deviceInfoExpectation = self.expectationWithDescription("receive device info")

        var conversationDelegate = ConversationBlockDelegate()
        conversationDelegate.messageHandler = { message in
            if message.dataType == QredoKeychainTransporterMessageTypeDeviceInfo {
                deviceInfoExpectation.fulfill()
            }
        }

        var transporterConversation : QredoConversation?

        receiverMock.stateHandler = { state in
            switch (state) {

            case .CreatedRendezvous:
                XCTAssertNotNil(receiverMock.rendezvousTag, "rendezvous tag should not be nil")

                // KeychainReceiver currently uses anonymous rendezvous. If this changes to X.509 authenticated rendezvous, a valid trustedRootPems/crlPems will be required
                self.senderClient.respondWithTag(self.stripURIPrefix(receiverMock.rendezvousTag!), trustedRootPems:nil, crlPems:nil, completionHandler: { (conversation, error) -> Void in
                    XCTAssertNil(error, "unexpected error")
                    XCTAssertNotNil(conversation, "failed to respond to the rendezvous")

                    transporterConversation = conversation

                    if let actualConversation = conversation {
                        actualConversation.addConversationObserver(conversationDelegate)
                    }
                })

            case .SentDeviceInfo:
                let deviceInfoMessage = QredoConversationMessage(
                    value: nil,
                    dataType: QredoKeychainTransporterMessageTypeDeviceInfo,
                    summaryValues: [QredoKeychainTransporterMessageKeyDeviceName: "test devie"])

                transporterConversation?.publishMessage(deviceInfoMessage, completionHandler: { (highwatermark, error) -> Void in
                    XCTAssertNil(error, "failed to send the message")
                })

            default: ()
            }
        }

        receiverMock.shouldCancelAt = .EstablishedConnection

        var completionHandlerCalls = 0
        receiver.startWithCompletionHandler { error in
            completionHandlerCalls++
            XCTAssertNil(error, "Should be success")

            receiverCompletionExpectation?.fulfill()
            receiverCompletionExpectation = nil
        }

        // double timeout, because we are doing quite a few operations here
        self.waitForExpectationsWithTimeout(60, handler: nil)
        
        transporterConversation?.removeConversationObaserver(conversationDelegate)

        XCTAssertEqual(completionHandlerCalls, 1, "should call the completion handler only once")
        XCTAssertTrue(receiverMock.didCallWillCreateRendezvous, "should prepare the receiver delegate")
        XCTAssertTrue(receiverMock.didCallDidCreateRendezvous, "should create the rendezvous")
        XCTAssertTrue(receiverMock.didSendDeviceInfo, "should send device info")
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
                // KeychainReceiver currently uses anonymous rendezvous. If this changes to X.509 authenticated rendezvous, a valid trustedRootPems/crlPems will be required
                self.senderClient.respondWithTag(self.stripURIPrefix(receiverMock.rendezvousTag!), trustedRootPems:nil, crlPems:nil, completionHandler: { (conversation, error) -> Void in
                    XCTAssertNotNil(conversation, "failed to respond to the rendezvous")
                    transporterConversation = conversation
                    if let actualConversation = conversation {
                        actualConversation.addConversationObserver(conversationDelegate)
                    }
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
        
        transporterConversation?.removeConversationObaserver(conversationDelegate)

        XCTAssertEqual(completionHandlerCalls, 1, "should call the completion handler only once")
        XCTAssertFalse(receiverMock.didCallDidReceiveKeychain, "Should not receive keychain")
    }

    func testInvalidKeychainMessageType() {
        checkInvalidKeychainData(
            QredoConversationMessage(
                value: "hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
                dataType: "invalid type",
                summaryValues: [:]))
    }

    func testInvalidKeychainMessageData() {
        checkInvalidKeychainData(
            QredoConversationMessage(
                value: "hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
                dataType: QredoKeychainTransporterMessageTypeKeychain,
                summaryValues: [:]))
    }

}
