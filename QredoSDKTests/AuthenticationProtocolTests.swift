/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest

class AuthenticationProtocolTests: BaseConversation {

    override func setUp() {
        conversationType = "com.qredo.attestation.authentication"

        super.setUp()
    }

    func testFullCycle() {
        let responseLF = QredoAuthenticationResponse(credentialValidationResults: [], sameIdentity: true, authenticatorCertChain: NSData(), signature: NSData())
        let response = QredoPrimitiveMarshallers.marshalObject(responseLF, marshaller: QredoClientMarshallers.authenticationResponseMarshaller())
        let responseMessage = QredoConversationMessage(value: response, dataType: "com.qredo.attestation.authentication.result", summaryValues: nil)

        sendRequest(responseMessage, expectErrorCode: nil)
    }


    func testMalformedResponseData() {
        let response = "malformed data".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let responseMessage = QredoConversationMessage(value: response, dataType: "com.qredo.attestation.authentication.result", summaryValues: nil)

        sendRequest(responseMessage, expectErrorCode: QredoErrorCode.ConversationProtocolReceivedMalformedData)
    }

    func testWrong() {
        let responseLF = QredoAuthenticationResponse(credentialValidationResults: [], sameIdentity: true, authenticatorCertChain: NSData(), signature: NSData())
        let response = QredoPrimitiveMarshallers.marshalObject(responseLF, marshaller: QredoClientMarshallers.authenticationResponseMarshaller())
        let responseMessage = QredoConversationMessage(value: response, dataType: "com.qredo.attestation.authentication.result.wrong", summaryValues: nil)

        sendRequest(responseMessage, expectErrorCode: QredoErrorCode.ConversationProtocolUnexpectedMessageType)
    }

    func testCancelByAuthenticatorAfterReceivingRequest() {
        let receivedRequestExpectation = self.expectationWithDescription("received authentication request")
        let publishedCancelExpectation = self.expectationWithDescription("published cancel message")

        let cancelMessage = QredoConversationMessage(value: nil, dataType: "com.qredo.attestation.cancel", summaryValues: nil)

        let cancelMessageCompletionHandler = { (hwm : QredoConversationHighWatermark!, error : NSError!) -> Void in
            XCTAssertNil(error, "failed to publish cancel message")
            publishedCancelExpectation.fulfill()
        }

        let validatorDelegate = ConversationBlockDelegate()
        validatorDelegate.messageHandler = { (message : QredoConversationMessage) in
            println("Received \(message.dataType)")

            if message.dataType == "com.qredo.attestation.authentication.claims" {
                receivedRequestExpectation.fulfill()

                self.creatorConversation.publishMessage(cancelMessage, completionHandler: cancelMessageCompletionHandler)
            }
        }

        sendRequest(QredoErrorCode.ConversationProtocolCancelledByOtherSide, validatorDelegate: validatorDelegate)
    }

    func testCancelByRelyingPartyBeforeSendingClaims() {
        let authProtocol = QredoAuthenticationProtocol(conversation: responderConversation)

        let cancelMessageExpectation = self.expectationWithDescription("cancel message received")

        let validatorDelegate = ConversationBlockDelegate()
        validatorDelegate.messageHandler = { (message : QredoConversationMessage) in
            println("Received \(message.dataType)")

            if message.dataType == "com.qredo.attestation.cancel" {
                cancelMessageExpectation.fulfill()
            }
        }

        creatorConversation.delegate = validatorDelegate
        creatorConversation.startListening()


        let authDelegate = AuthenticationProtocolBlockDelegate()

        authDelegate.sentClaimsBlock = {
            XCTFail("should not be called")
        }

        authDelegate.failureBlock = { (error : NSError) in
            XCTFail("should not be called")
        }

        authDelegate.successBlock = { result in
            XCTFail("should not be called")
        }

        authProtocol.delegate = authDelegate
        authProtocol.cancel()

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }

    func sendRequest(responseMessage: QredoConversationMessage, expectErrorCode: QredoErrorCode?) {
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

        sendRequest(expectErrorCode, validatorDelegate: validatorDelegate)
    }


    func sendRequest(expectErrorCode: QredoErrorCode?, validatorDelegate : QredoConversationDelegate) {
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

        creatorConversation.delegate = validatorDelegate
        creatorConversation.startListening()


        let authDelegate = AuthenticationProtocolBlockDelegate()

        let sentClaimsExpectation = self.expectationWithDescription("sent claims")
        let successOrFailureExpectation = self.expectationWithDescription("finish authentication protocol")

        authDelegate.sentClaimsBlock = {
            println("Sent claims")
            sentClaimsExpectation.fulfill()
        }

        authDelegate.failureBlock = { (error : NSError) in
            println("received error \(error)")
            successOrFailureExpectation.fulfill()

            if let errorCode = expectErrorCode?.rawValue {
                XCTAssertEqual(errorCode, error.code, "wrong error code")
            } else {
                XCTFail("failed")
            }
        }

        authDelegate.successBlock = { result in
            println("received response \(result)")
            successOrFailureExpectation.fulfill()

            if expectErrorCode != nil {
                XCTFail("should fail")
            }
        }

        authProtocol.delegate = authDelegate
        authProtocol.sendAuthenticationRequest(authRequest)

        self.waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }

}
