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
        
        let appSecret = "abcd1234"                 //provided by qredo
        let userId = "tutorialuser@test.com"    //user email or username etc
        let userSecret = "!%usertutorialPassword"   //user entered password
        
        
         QredoClient.initializeWithAppSecret(appSecret, userId: userId, userSecret: userSecret, options: options) { authorizedClient, error in
            assert(error == nil, "failed to authorize client")

            if let actualClient = authorizedClient {
                self.creatorClient = actualClient
            }

            creatorClientExpectation.fulfill()
        }

        let responderClientExpectation = testCase.expectationWithDescription("authorize responder client")
        QredoClient.initializeWithAppSecret(appSecret, userId: userId, userSecret: userSecret, options: options) { authorizedClient, error in
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
            }
        }

        testCase.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let receiveResponseForRendezvousExpectation = testCase.expectationWithDescription("get response for rendezvous")
        let respondToRendezvousExpectation = testCase.expectationWithDescription("respond to rendezvous")

        let rendezvousObserver = RendezvousBlockObserver()
        rendezvousObserver.responseHandler = { conversation in
            self.creatorConversation = conversation
            receiveResponseForRendezvousExpectation.fulfill()
        }

        creatorRendezvous?.addRendezvousObserver(rendezvousObserver)

        // We know we're responding to anonymous rendezvous, so nil trustedRootPems is fine
        responderClient.respondWithTag(randomTag, completionHandler: { conversation, error in
            assert(error == nil, "failed to respond")

            self.responderConversation = conversation
            respondToRendezvousExpectation.fulfill()
        })

        testCase.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }

    func tearDown() {
        creatorClient.closeSession()
        responderClient.closeSession()
    }
}
