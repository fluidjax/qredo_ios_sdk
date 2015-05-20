/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class KeychainTransporterTests: XCTestCase {

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

    func testFullCycle() {
        let senderMock = KeychainSenderMock()
        let sender = QredoKeychainSender(client: senderClient, delegate: senderMock)

        let receiverMock = KeychainReceiverMock()
        let receiver = QredoKeychainReceiver(client: receiverClient, delegate: receiverMock)

        let receiverCompletionExpectation = self.expectationWithDescription("finish receiving")
        let senderCompletionExpectation = self.expectationWithDescription("finish sending")

        senderMock.shouldWaitForRendezvousTag = true
        senderMock.shouldPassConfirmation = true

        receiverMock.shouldPassConfirmation = true

        receiverMock.stateHandler = { state in
            if state == .CreatedRendezvous {
                XCTAssertNotNil(receiverMock.rendezvousTag, "rendezvous tag should not be nil")

                if let tag = receiverMock.rendezvousTag {
                    senderMock.discoverTag(tag)
                }
            }
        }

        receiver.startWithCompletionHandler { error in
            XCTAssertNil(error, "failed receiving")
            receiverCompletionExpectation.fulfill()
        }

        sender.startWithCompletionHandler { error in
            XCTAssertNil(error, "failed sending")
            senderCompletionExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(100, handler: nil)

        XCTAssertTrue(receiverMock.didCallWillCreateRendezvous, "should prepare the receiver delegate")
        XCTAssertTrue(receiverMock.didCallDidCreateRendezvous, "did not create a rendezvous")
        XCTAssertTrue(receiverMock.didCallDidEstablishConnection, "did not establish connection")
        XCTAssertTrue(receiverMock.didCallDidReceiveKeychain, "did not receive the keychain")
        XCTAssertTrue(receiverMock.didCallDidInstallKeychain, "did not install the keychain")

        XCTAssertTrue(senderMock.didCallDiscoverRendezvous, "should prepare the sender delegate")
        XCTAssertTrue(senderMock.didCallEstablishedConnection, "should establish the connection")
        XCTAssertTrue(senderMock.didCallFinishSending, "did not send the keychain")
    }
    

}
