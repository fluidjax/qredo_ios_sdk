/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest


// WARNING: This test will be failing until https://github.com/Qredo/services/issues/261 is fixed

class TwoClientsHelper {
    var firstClient : QredoClient!
    var secondClient : QredoClient!

    func authorize(test : XCTestCase, options : QredoClientOptions!) {
        let authorizeExpectation1 = test.expectationWithDescription("authorize expectation")

        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: options) { (authorizedClient, error) -> Void in
            assert(error == nil, "Failed to authorize client")

            self.firstClient = authorizedClient
            authorizeExpectation1.fulfill()
        }
        test.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)


        let authorizeExpectation2 = test.expectationWithDescription("authorize expectation")
        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: options) { (authorizedClient, error) -> Void in
            assert(error == nil, "Failed to authorize client")

            self.secondClient = authorizedClient
            authorizeExpectation2.fulfill()
        }
        test.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        assert(firstClient != nil, "failed to authorized first client")
        assert(secondClient != nil, "failed to authorized first client")
    }

    func tearDown() {
        if (firstClient != nil) {
            firstClient.closeSession()
        }

        if (secondClient != nil) {
            secondClient.closeSession()
        }
    }
}

class RendezvousMultipleSubsription: XCTestCase {
    let clients = TwoClientsHelper()

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        let options = QredoClientOptions(MQTT: true, resetData: true)

        clients.authorize(self, options: options)
    }

    func testMultipleSubscriptions() {
        var createdRendezvous : QredoRendezvous!
        let rendezvousTag = QredoQUID().QUIDString()

        var createRendezvousExpectation : XCTestExpectation? = expectationWithDescription("create a rendezvous")
        clients.firstClient.createAnonymousRendezvousWithTag(rendezvousTag,
            configuration: QredoRendezvousConfiguration(conversationType: "test~")) { (rendezvous, error) -> Void in
                XCTAssertNil(error, "failed to register a rendezvous")
                XCTAssertNotNil(rendezvous, "rendezvous should not be nil")
                createdRendezvous = rendezvous

                createRendezvousExpectation?.fulfill()
        }

        waitForExpectationsWithTimeout(qtu_defaultTimeout) { error in
            createRendezvousExpectation = nil
        }



        var fetchedRendezvous : QredoRendezvous!
        var fetchRendezvousExpectation : XCTestExpectation? = expectationWithDescription("fetch rendezvous")
        clients.firstClient.fetchRendezvousWithTag(rendezvousTag, completionHandler: { (rendezvous, error) -> Void in
            XCTAssertNil(error, "failed to fetch the rendezvous")
            XCTAssertNotNil(rendezvous, "rendezvous should not be nil")

            fetchedRendezvous = rendezvous
            fetchRendezvousExpectation?.fulfill()
        })

        waitForExpectationsWithTimeout(qtu_defaultTimeout) { error in
            fetchRendezvousExpectation = nil
        }


        var respondExpectation : XCTestExpectation? = expectationWithDescription("responded to rendezvous")
        var receiveResponseExpectation : XCTestExpectation? = expectationWithDescription("received response on the delegate")

        var receivedResponse = false
        let createdRendezvousListener = RendezvousBlockDelegate()
        createdRendezvousListener.responseHandler = { conversation in
            println("createdRendezvousListener respond")
            XCTAssertFalse(receivedResponse, "Already received one response")

            receivedResponse = true
            receiveResponseExpectation?.fulfill()
        }

        createdRendezvousListener.errorHandler = { error in
            XCTFail("something failed in the listener \(error)")
        }

        // We know we're responding to anonymous rendezvous, so nil trustedRootRefs is fine for this test
        clients.secondClient.respondWithTag(rendezvousTag, trustedRootRefs:nil) { conversation, error in
            XCTAssertNil(error, "failed to respond")
            respondExpectation?.fulfill()
        }

        createdRendezvous.delegate = createdRendezvousListener
        createdRendezvous.startListening()

        waitForExpectationsWithTimeout(60) { error in
            receiveResponseExpectation = nil
            respondExpectation = nil
        }
        XCTAssertTrue(receivedResponse, "did not receive response")



        // Now start listening on both instances of the same rendezvous
        let fetchedRendezvousListener = RendezvousBlockDelegate()
        var receiveResponseOnFetchedRendezvousExpectation : XCTestExpectation? = expectationWithDescription("response on fetched rendezvous")
        var receiveResponseOnFetchedRendezvous = false
        fetchedRendezvousListener.responseHandler = { conversation in
            println("fetchedRendezvousListener respond")
            XCTAssertFalse(receiveResponseOnFetchedRendezvous, "Already received one response")

            receiveResponseOnFetchedRendezvous = true
            receiveResponseOnFetchedRendezvousExpectation?.fulfill()
        }

        fetchedRendezvousListener.errorHandler = { error in
            println("fetchedRendezvousListener: error \(error)")
            XCTFail("something failed in the listener \(error)")
        }

        fetchedRendezvous.delegate = fetchedRendezvousListener
        fetchedRendezvous.startListening()

        // reset listener on created rendezvous
        receiveResponseExpectation = expectationWithDescription("response on created rendezvos")
        receivedResponse = false

        respondExpectation = expectationWithDescription("respond")

        // We know we're responding to anonymous rendezvous, so nil trustedRootRefs is fine for this test
        clients.secondClient.respondWithTag(rendezvousTag, trustedRootRefs:nil) { conversation, error in
            XCTAssertNil(error, "failed to respond")
            respondExpectation?.fulfill()
        }

        waitForExpectationsWithTimeout(20) { error in
            respondExpectation = nil
            receiveResponseExpectation = nil
            receiveResponseOnFetchedRendezvousExpectation = nil
        }

    }
    
    override func tearDown() {
        clients.tearDown()
        super.tearDown()
    }

}
