/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class AuthenticationProtocolBlockDelegate : QredoAuthenticationProtocolDelegate {
    var failureBlock : ((NSError) -> Void)?
    var successBlock : ((QredoAuthenticationResponse) -> Void)?
    var sentClaimsBlock : (Void -> Void)?

    func qredoAuthenticationProtocol(authProtocol: QredoAuthenticationProtocol!, didFailWithError error: NSError!) {
        failureBlock?(error)
    }

    func qredoAuthenticationProtocol(authProtocol: QredoAuthenticationProtocol!, didFinishWithResults results: QredoAuthenticationResponse!) {
        successBlock?(results)
    }

    func qredoAuthenticationProtocolDidSendClaims(authProtocol: QredoAuthenticationProtocol!) {
        sentClaimsBlock?()
    }
}

class AuthenticationProtocolTests: BaseConversation {

    override func setUp() {
        conversationType = "com.qredo.attestation.authentication"

        super.setUp()
    }

    func testFullCycle() {
        let responseLF = QredoAuthenticationResponse(credentialValidationResults: [], sameIdentity: true, authenticatorCertChain: NSData(), signature: NSData())
        let response = QredoPrimitiveMarshallers.marshalObject(responseLF, marshaller: QredoClientMarshallers.authenticationResponseMarshaller())
        let responseMessage = QredoConversationMessage(value: response, dataType: "com.qredo.attestation.authentication.result", summaryValues: nil)

        sendRequest(responseMessage, expectSuccess: true)
    }


    func testMalformedResponseData() {
        let response = "malformed data".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let responseMessage = QredoConversationMessage(value: response, dataType: "com.qredo.attestation.authentication.result", summaryValues: nil)

        sendRequest(responseMessage, expectSuccess: false)
    }

    func testWrong() {
        let responseLF = QredoAuthenticationResponse(credentialValidationResults: [], sameIdentity: true, authenticatorCertChain: NSData(), signature: NSData())
        let response = QredoPrimitiveMarshallers.marshalObject(responseLF, marshaller: QredoClientMarshallers.authenticationResponseMarshaller())
        let responseMessage = QredoConversationMessage(value: response, dataType: "com.qredo.attestation.authentication.result.wrong", summaryValues: nil)

        sendRequest(responseMessage, expectSuccess: false)
    }


    func sendRequest(responseMessage: QredoConversationMessage, expectSuccess: Bool) {
        let authProtocol = QredoAuthenticationProtocol(conversation: responderConversation)

        let credential1 = QredoCredential(
            serialNumber: "123",
            claimant: "Alice".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
            hashedClaim: QredoQUID().data(),
            notBefore: "",
            notAfter: "",
            revocationLocator: "",
            attesterInfo: "VISA",
            signature: "signature".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))


        let claimMessage = QredoClaimMessage(claimHash: QredoQUID().data(), credential: credential1)


        let authRequest = QredoAuthenticationRequest(
            claimMessages: [claimMessage],
            conversationSecret: "secret".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))


        let receivedRequestExpectation = self.expectationWithDescription("received authentication request")

        let publishedResponseExpectation = self.expectationWithDescription("publish authentication response")

        let publishResponseCompletionHandler = { (hwm : QredoConversationHighWatermark!, error : NSError!) -> Void in
            XCTAssertNil(error, "failed to publish response")
            publishedResponseExpectation.fulfill()

        }

        let validatorDelegate = ConversationBlockDelegate()
        validatorDelegate.messageHandler = { (message : QredoConversationMessage) in
            println("Received \(message.dataType)")

            if message.dataType == "com.qredo.attestation.authentication.claims" {
                receivedRequestExpectation.fulfill()

                println("publishing response")

                self.creatorConversation.publishMessage(responseMessage, completionHandler: publishResponseCompletionHandler)
            }
        }

        creatorConversation.delegate = validatorDelegate
        creatorConversation.startListening()


        let authDelegate = AuthenticationProtocolBlockDelegate()

        let sentClaimsExpectation = self.expectationWithDescription("sent claims")
        let successOrFailureExpectation = self.expectationWithDescription("finish authentication protocol")

        authDelegate.sentClaimsBlock = {
            println("Sent claims")
            sentClaimsExpectation.fulfill()
        }

        authDelegate.failureBlock = { error in
            println("received error \(error)")
            successOrFailureExpectation.fulfill()

            if expectSuccess {
                XCTFail("failed")
            }
        }

        authDelegate.successBlock = { result in
            println("received response \(result)")
            successOrFailureExpectation.fulfill()

            if !expectSuccess {
                XCTFail("should fail")
            }
        }

        authProtocol.delegate = authDelegate
        authProtocol.sendAuthenticationRequest(authRequest)

        self.waitForExpectationsWithTimeout(20 * qtu_defaultTimeout, handler: nil)
    }

}
