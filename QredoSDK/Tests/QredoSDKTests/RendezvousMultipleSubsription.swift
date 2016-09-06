/* HEADER GOES HERE */
import UIKit
import XCTest


// WARNING: This test will be failing until https://github.com/Qredo/services/issues/261 is fixed

class TwoClientsHelper {
    var firstClient: QredoClient!
    var secondClient : QredoClient!

    func authorize(test : XCTestCase, options : QredoClientOptions!) {
        let authorizeExpectation1 = test.expectationWithDescription("authorize expectation")

        var appSecret   = "cafebabe"
        var userId      = "testUserId"
        var userSecret  = QredoTestUtils.randomPassword()
        
        QredoClient.initializeWithAppSecret(appSecret, userId: userId, userSecret: userSecret, options: options) { authorizedClient, error in
            assert(error == nil, "Failed to authorize client")

            self.firstClient = authorizedClient
            authorizeExpectation1.fulfill()
        }
        test.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)


        let authorizeExpectation2 = test.expectationWithDescription("authorize expectation")
        
        appSecret   = "cafebabe"
        userId      = "testUserId"
        userSecret  = QredoTestUtils.randomPassword()
        
         QredoClient.initializeWithAppSecret(appSecret, userId: userId, userSecret: userSecret, options: options) { authorizedClient, error in
            assert(error == nil, "Failed to authorize client")

            self.secondClient = authorizedClient
            authorizeExpectation2.fulfill()
        }
        test.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        assert(firstClient != nil, "failed to authorized first client")
        assert(secondClient != nil, "failed to authorized second client")
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
        let options = QredoClientOptions.qtu_clientOptionsWithTransportType(.MQTT, resetData: true)

        clients.authorize(self, options: options)
    }

    func testMultipleSubscriptions() {
        var createdRendezvous : QredoRendezvous!
        let rendezvousTag = QredoQUID().QUIDString()
        var rendezvousRef : QredoRendezvousRef!

        var createRendezvousExpectation : XCTestExpectation? = expectationWithDescription("create a rendezvous")
        clients.firstClient.createAnonymousRendezvousWithTag(rendezvousTag,
            configuration: QredoRendezvousConfiguration(conversationType: "test~")) { (rendezvous, error) -> Void in
                XCTAssertNil(error, "failed to register a rendezvous")
                XCTAssertNotNil(rendezvous, "rendezvous should not be nil")
                createdRendezvous = rendezvous
                rendezvousRef = rendezvous.metadata.rendezvousRef

                createRendezvousExpectation?.fulfill()
        }

        waitForExpectationsWithTimeout(qtu_defaultTimeout) { error in
            createRendezvousExpectation = nil
        }
        XCTAssertNotNil(rendezvousRef, "RendezvousRef should not be nil")


        var fetchedRendezvous : QredoRendezvous!
        var fetchRendezvousExpectation : XCTestExpectation? = expectationWithDescription("fetch rendezvous")
        clients.firstClient.fetchRendezvousWithRef(rendezvousRef, completionHandler: { (rendezvous, error) -> Void in
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
        let createdRendezvousListener = RendezvousBlockObserver()
        createdRendezvousListener.responseHandler = { conversation in
            print("createdRendezvousListener respond")
            XCTAssertFalse(receivedResponse, "Already received one response")

            receivedResponse = true
            receiveResponseExpectation?.fulfill()
        }

        createdRendezvousListener.errorHandler = { error in
            XCTFail("something failed in the listener \(error)")
        }

        // We know we're responding to anonymous rendezvous, so nil trustedRootPems/crlPems is fine for this test
        clients.secondClient.respondWithTag(rendezvousTag, trustedRootPems:nil, crlPems:nil) { conversation, error in
            XCTAssertNil(error, "failed to respond")
            respondExpectation?.fulfill()
        }

        createdRendezvous.addRendezvousObserver(createdRendezvousListener)

        waitForExpectationsWithTimeout(60) { error in
            receiveResponseExpectation = nil
            respondExpectation = nil
        }
        XCTAssertTrue(receivedResponse, "did not receive response")



        // Now start listening on both instances of the same rendezvous
        let fetchedRendezvousListener = RendezvousBlockObserver()
        var receiveResponseOnFetchedRendezvousExpectation : XCTestExpectation? = expectationWithDescription("response on fetched rendezvous")
        var receiveResponseOnFetchedRendezvous = false
        fetchedRendezvousListener.responseHandler = { conversation in
            print("fetchedRendezvousListener respond")
            XCTAssertFalse(receiveResponseOnFetchedRendezvous, "Already received one response")

            receiveResponseOnFetchedRendezvous = true
            receiveResponseOnFetchedRendezvousExpectation?.fulfill()
        }

        fetchedRendezvousListener.errorHandler = { error in
            print("fetchedRendezvousListener: error \(error)")
            XCTFail("something failed in the listener \(error)")
        }

        fetchedRendezvous.addRendezvousObserver(fetchedRendezvousListener)

        // reset listener on created rendezvous
        receiveResponseExpectation = expectationWithDescription("response on created rendezvos")
        receivedResponse = false

        respondExpectation = expectationWithDescription("respond")

        // We know we're responding to anonymous rendezvous, so nil trustedRootPems/crlPems is fine for this test
        clients.secondClient.respondWithTag(rendezvousTag, trustedRootPems:nil, crlPems:nil) { conversation, error in
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
