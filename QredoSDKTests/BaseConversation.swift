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
    var conversationType = "com.qredo.test"
    let plainTextMessageType = "com.qredo.plaintext"

    var transportType = QredoClientOptionsTransportType.HTTP

    override func setUp() {
        super.setUp()

        
        let appSecret = "cafebabe"
        let userId = "testUserId"
        let userSecret = "randompassword"
        
        
        let creatorClientExpectation = expectationWithDescription("authorize creator client")
        let options = QredoClientOptions.qtu_clientOptionsWithTransportType(transportType, resetData: true)
        
        QredoClient.initializeWithAppSecret(appSecret, userId: userId, userSecret: userSecret, options: options) { authorizedClient, error in
            XCTAssertNil(error, "failed to authorize client")
            
            if let actualClient = authorizedClient {
                self.creatorClient = actualClient
            }
            
            creatorClientExpectation.fulfill()
        }
        
        let responderClientExpectation = expectationWithDescription("authorize responder client")
         QredoClient.initializeWithAppSecret(appSecret, userId: userId, userSecret: userSecret, options: options) { authorizedClient, error in
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
        creatorClient.createAnonymousRendezvousWithTag(randomTag, configuration: configuration) { rendezvous, error in
            XCTAssertNil(error, "failed to create rendezvos")

            if let actualRendezvous = rendezvous {
                creatorRendezvous = actualRendezvous
                rendezvousExpectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let receiveResponseForRendezvousExpectation = expectationWithDescription("get response for rendezvous")
        let respondToRendezvousExpectation = expectationWithDescription("respond to rendezvous")

        let rendezvousObserver = RendezvousBlockObserver()
        rendezvousObserver.responseHandler = { conversation in
            self.creatorConversation = conversation
            receiveResponseForRendezvousExpectation.fulfill()
        }

        creatorRendezvous?.addRendezvousObserver(rendezvousObserver)

        // We know we're responding to anonymous rendezvous, so nil trustedRootPems/crlPems is fine
        responderClient.respondWithTag(randomTag, trustedRootPems:nil, crlPems:nil, completionHandler: { conversation, error in
            XCTAssertNil(error, "failed to respond")

            self.responderConversation = conversation
            respondToRendezvousExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }

    override func tearDown() {
        creatorClient.closeSession()
        responderClient.closeSession()
    }
}
