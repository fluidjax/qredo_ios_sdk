/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

// establishes a conversation via untrusted rendezvous
// the conversation is persisted
class BaseConversation: XCTestCase {
    var creatorClient : QredoClient!
    var responderClient : QredoClient!

    var creatorConversation : QredoConversation!
    var responderConversation : QredoConversation!
    let conversationType = "com.qredo.test"
    let plainTextMessageType = "com.qredo.plaintext"

    var useMQTT = false

    override func setUp() {
        super.setUp()

        let creatorClientExpectation = expectationWithDescription("authorize creator client")
        let options = QredoClientOptions(MQTT: useMQTT, resetData: true)
        QredoClient.authorizeWithConversationTypes([conversationType], vaultDataTypes: [], options: options) { authorizedClient, error in
            XCTAssertNil(error, "failed to authorize client")

            if let actualClient = authorizedClient {
                self.creatorClient = actualClient
            }

            creatorClientExpectation.fulfill()
        }

        let responderClientExpectation = expectationWithDescription("authorize responder client")
        QredoClient.authorizeWithConversationTypes([conversationType], vaultDataTypes: [], options: options) { authorizedClient, error in
            XCTAssertNil(error, "failed to authorize client")

            if let actualClient = authorizedClient {
                self.responderClient = actualClient
            }

            responderClientExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)


        let rendezvousExpectation = expectationWithDescription("create rendezvous")
        let randomTag = QredoQUID().QUIDString()
        let configuration = QredoRendezvousConfiguration(conversationType: conversationType)
        var creatorRendezvous : QredoRendezvous? = nil
        creatorClient.createRendezvousWithTag(randomTag, configuration: configuration, signingHandler: nil) { rendezvous, error in
            XCTAssertNil(error, "failed to create rendezvos")

            if let actualRendezvous = rendezvous {
                creatorRendezvous = actualRendezvous
                rendezvousExpectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let receiveResponseForRendezvousExpectation = expectationWithDescription("get response for rendezvous")
        let respondToRendezvousExpectation = expectationWithDescription("respond to rendezvous")

        let rendezvousDelegate = RendezvousBlockDelegate()
        rendezvousDelegate.responseHandler = { conversation in
            self.creatorConversation = conversation
            receiveResponseForRendezvousExpectation.fulfill()
        }

        creatorRendezvous?.delegate = rendezvousDelegate
        creatorRendezvous?.startListening()

        responderClient.respondWithTag(randomTag, completionHandler: { conversation, error in
            XCTAssertNil(error, "failed to respond")

            self.responderConversation = conversation
            respondToRendezvousExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }
}
