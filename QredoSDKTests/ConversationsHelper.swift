/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class ConversationsHelper: NSObject {
    var creatorClient : QredoClient!
    var responderClient : QredoClient!

    var creatorConversation : QredoConversation!
    var responderConversation : QredoConversation!
    var conversationType = "com.qredo.test"
    let plainTextMessageType = "com.qredo.plaintext"

    var transportType = QredoClientOptionsTransportType.HTTP

    func setUp(testCase: XCTestCase) {
        let creatorClientExpectation = testCase.expectationWithDescription("authorize creator client")
        let options = QredoClientOptions.qtu_clientOptionsWithTransportType(transportType, resetData: true)
        QredoClient.authorizeWithConversationTypes([conversationType], vaultDataTypes: [], options: options) { authorizedClient, error in
            assert(error == nil, "failed to authorize client")

            if let actualClient = authorizedClient {
                self.creatorClient = actualClient
            }

            creatorClientExpectation.fulfill()
        }

        let responderClientExpectation = testCase.expectationWithDescription("authorize responder client")
        QredoClient.authorizeWithConversationTypes([conversationType], vaultDataTypes: [], options: options) { authorizedClient, error in
            assert(error == nil, "failed to authorize client")

            if let actualClient = authorizedClient {
                self.responderClient = actualClient
            }

            responderClientExpectation.fulfill()
        }
        testCase.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)


        let rendezvousExpectation = testCase.expectationWithDescription("create rendezvous")
        let randomTag = QredoQUID().QUIDString()
        let configuration = QredoRendezvousConfiguration(conversationType: conversationType)
        var creatorRendezvous : QredoRendezvous? = nil
        creatorClient.createAnonymousRendezvousWithTag(randomTag, configuration: configuration) { rendezvous, error in
            assert(error == nil, "failed to create rendezvos")

            if let actualRendezvous = rendezvous {
                creatorRendezvous = actualRendezvous
                rendezvousExpectation.fulfill()

                creatorRendezvous?.stopListening()
            }
        }

        testCase.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let receiveResponseForRendezvousExpectation = testCase.expectationWithDescription("get response for rendezvous")
        let respondToRendezvousExpectation = testCase.expectationWithDescription("respond to rendezvous")

        let rendezvousDelegate = RendezvousBlockDelegate()
        rendezvousDelegate.responseHandler = { conversation in
            self.creatorConversation = conversation
            receiveResponseForRendezvousExpectation.fulfill()
        }

        creatorRendezvous?.delegate = rendezvousDelegate
        creatorRendezvous?.startListening()

        // We know we're responding to anonymous rendezvous, so nil trustedRootPems is fine
        responderClient.respondWithTag(randomTag, trustedRootPems:nil, completionHandler: { conversation, error in
            assert(error == nil, "failed to respond")

            self.responderConversation = conversation
            respondToRendezvousExpectation.fulfill()
        })

        testCase.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }

    func tearDown() {
        responderConversation.stopListening()
        creatorConversation.stopListening()
        
        creatorClient.closeSession()
        responderClient.closeSession()
    }
}
