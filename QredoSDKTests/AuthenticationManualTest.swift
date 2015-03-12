/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class AuthenticationManualTest: XCTestCase {

    let rendezvousTag = "MEGAVISA11"

    func testExample() {
        let clientExpectation = expectationWithDescription("create client")
        var client : QredoClient!

        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: []) { (authorizedClient, error) -> Void in
            client = authorizedClient
            clientExpectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(2, handler: nil)

        XCTAssertNotNil(client, "didn't authorize")


        let conversationExpectation = expectationWithDescription("respond to rendezvous")
        var conversation : QredoConversation!
        client.respondWithTag(rendezvousTag, completionHandler: { (conversation_, error) -> Void in
            if error != nil {
                println("failed to respond: \(error)")
            }
            conversation = conversation_
            conversationExpectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(2, handler: nil)

        XCTAssertNotNil(conversation, "failed to respond")


        let credential1 = QredoCredential(
            serialNumber: "123",
            claimant: "Alice".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
            hashedClaim: QredoQUID().data(),
            notBefore: "",
            notAfter: "",
            revocationLocator: "",
            attesterInfo: "VISA",
            signature: "signature".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))

        let claimMessage1 = QredoClaimMessage(claimHash: QredoQUID().data(), credential: credential1)


        let authRequest = QredoAuthenticationRequest(
            claimMessages: [claimMessage1],
            conversationSecret: "secret".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))


        let finishExpectation = expectationWithDescription("success or fail")

        let authenticationProtocol = QredoAuthenticationProtocol(conversation: conversation)
        let authenticationDelegate = AuthenticationProtocolBlockDelegate()

        authenticationDelegate.failureBlock = { error in
            println("error: \(error)")
            finishExpectation.fulfill()
        }

        authenticationDelegate.successBlock = { response in
            println("success: \(response)")
            finishExpectation.fulfill()
        }

        authenticationDelegate.sentClaimsBlock = {
            println("sent claims")
        }


        authenticationProtocol.delegate = authenticationDelegate
        authenticationProtocol.sendAuthenticationRequest(authRequest)

        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
