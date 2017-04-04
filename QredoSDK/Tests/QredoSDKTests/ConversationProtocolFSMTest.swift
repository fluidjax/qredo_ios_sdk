/* HEADER GOES HERE */
import UIKit
import XCTest

class ConversationProtocolFSMTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func publishMultipleMessages(statesCount:Int) {
        let conversationHelper = ConversationsHelper()
        conversationHelper.setUp(self)

        let messageTypePrefix = "com.test"

        let conversationProtocol = QredoConversationProtocolFSM(conversation: conversationHelper.creatorConversation)
        var states : [QredoConversationProtocolFSMState] = []
        var sendExpectations : [XCTestExpectation] = []

        for stateIndex in 1...statesCount {

            let expectation = self.expectationWithDescription("send message \(stateIndex)")
            sendExpectations.append(expectation)

            states.append(
                QredoConversationProtocolPublishingState { () -> QredoConversationMessage in
                    expectation.fulfill()
                    return QredoConversationMessage(
                        value: "Hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
                        dataType: "\(messageTypePrefix).\(stateIndex)",
                        summaryValues: [:])
                }
            )
        }

        conversationProtocol.addStates(states)

        var protocolSuccessExpectation : XCTestExpectation? = expectationWithDescription("finish protocol")
        let protocolDelegate = QredoConversationProtocolFSMBlockDelegate()
        protocolDelegate.onSuccess = {
            protocolSuccessExpectation?.fulfill()
        }

        protocolDelegate.onError = { error in
            XCTFail("failed with error: \(error.localizedDescription)")
        }
        conversationProtocol.startWithDelegate(protocolDelegate)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            protocolSuccessExpectation = nil
        })


        // make sure that the other side of the converation receives the message

        var receiveMessageExpectation : XCTestExpectation? = expectationWithDescription("received message")
        let conversationDelegate = ConversationBlockDelegate()
        var count = 0
        conversationDelegate.messageHandler = { message in
            print("Received message \(message.dataType)")
            count++

            XCTAssertEqual(message.dataType, "\(messageTypePrefix).\(count)")

            if count >= statesCount {
                receiveMessageExpectation?.fulfill()
            }
        }
        conversationHelper.responderConversation.addConversationObserver(conversationDelegate)


        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            receiveMessageExpectation = nil
        })
        
        conversationHelper.responderConversation.removeConversationObserver(conversationDelegate)
        
        conversationHelper.tearDown()
    }


    func expectMultipleMessages(statesCount:Int) {
        let conversationHelper = ConversationsHelper()
        conversationHelper.setUp(self)

        let messageTypePrefix = "com.test"


        let conversation = conversationHelper.responderConversation
        for messageIndex in 1...statesCount {
            let message = QredoConversationMessage(
                value: "hello \(messageIndex)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
                dataType: "\(messageTypePrefix).\(messageIndex)",
                summaryValues: [:])
            let publishExpectation = expectationWithDescription("publish message \(messageIndex)")
            conversation.publishMessage(message, completionHandler: { (hwm, error) -> Void in
                print("published message \(messageIndex)")
                publishExpectation.fulfill()
            })

            waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        }



        let conversationProtocol = QredoConversationProtocolFSM(conversation: conversationHelper.creatorConversation)
        var states : [QredoConversationProtocolFSMState] = []
        var sendExpectations : [XCTestExpectation] = []

        for stateIndex in 1...statesCount {
            let expectation = self.expectationWithDescription("receive message \(stateIndex)")
            sendExpectations.append(expectation)
            let index = stateIndex
            let state = QredoConversationProtocolExpectingState { (message) -> Bool in
                let expectedMessageType = "\(messageTypePrefix).\(index)"
                print("received message \(message.dataType), expecting \(expectedMessageType)")
                expectation.fulfill()


                XCTAssertEqual(message.dataType, expectedMessageType, "received wrong message")

                return message.dataType == expectedMessageType
            }
            states.append(state)
        }

        conversationProtocol.addStates(states)

        var protocolSuccessExpectation : XCTestExpectation? = expectationWithDescription("finish protocol")
        let protocolDelegate = QredoConversationProtocolFSMBlockDelegate()
        protocolDelegate.onSuccess = {
            protocolSuccessExpectation?.fulfill()
        }

        protocolDelegate.onError = { error in
            XCTFail("failed with error: \(error.localizedDescription)")
        }
        conversationProtocol.startWithDelegate(protocolDelegate)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            protocolSuccessExpectation = nil
        })

        conversationHelper.tearDown()
    }

    func testPublishOne() {
        publishMultipleMessages(1)
    }

    func testPublishMultiple() {
        publishMultipleMessages(10)
    }

    func testExpectOne() {
        expectMultipleMessages(1)
    }

    func testExpectMultiple() {
        expectMultipleMessages(10)
    }

    func testExpectFail() {
        let conversationHelper = ConversationsHelper()
        conversationHelper.setUp(self)

        let conversationProtocol = QredoConversationProtocolFSM(conversation: conversationHelper.creatorConversation)

        conversationProtocol.addStates([
            QredoConversationProtocolExpectingState { message -> Bool in
                message.dataType == "com.test.correct"

            }
            ])


        let message = QredoConversationMessage(
            value: "hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true),
            dataType: "com.test.wrong",
            summaryValues: [:])

        let publishExpectation = expectationWithDescription("publish message")
        conversationHelper.responderConversation.publishMessage(message, completionHandler:
            { (hwm, error) -> Void in
                print("published message")
                publishExpectation.fulfill()
            })

        var protocolFailureExpectation : XCTestExpectation? = expectationWithDescription("finish protocol")
        let protocolDelegate = QredoConversationProtocolFSMBlockDelegate()
        protocolDelegate.onSuccess = {
            XCTFail("protocol should not succeed")
        }

        protocolDelegate.onError = { error in
            protocolFailureExpectation?.fulfill()
        }
        conversationProtocol.startWithDelegate(protocolDelegate)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            protocolFailureExpectation = nil
        })
        
        conversationHelper.tearDown()
    }

    func processMultipleStates(statesCount: Int) {
        let conversationHelper = ConversationsHelper()
        conversationHelper.setUp(self)

       // let messageTypePrefix = "com.test"

        let conversationProtocol = QredoConversationProtocolFSM(conversation: conversationHelper.creatorConversation)
        var states : [QredoConversationProtocolFSMState] = []
        var processExpectation : [XCTestExpectation] = []

        for stateIndex in 1...statesCount {

            let expectation = self.expectationWithDescription("process \(stateIndex)")
            processExpectation.append(expectation)

            let state = QredoConversationProtocolProcessingState { state in
                print("processing state \(stateIndex)")
                expectation.fulfill()
                state.finishProcessing()
            }

            states.append(state)
        }

        conversationProtocol.addStates(states)

        var protocolSuccessExpectation : XCTestExpectation? = expectationWithDescription("finish protocol")
        let protocolDelegate = QredoConversationProtocolFSMBlockDelegate()
        protocolDelegate.onSuccess = {
            protocolSuccessExpectation?.fulfill()
        }

        protocolDelegate.onError = { error in
            XCTFail("failed with error: \(error.localizedDescription)")
        }
        conversationProtocol.startWithDelegate(protocolDelegate)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            protocolSuccessExpectation = nil
        })

        conversationHelper.tearDown()
    }

    func testProcess1() {
        processMultipleStates(1)
    }

    func testProcessMultiple() {
        processMultipleStates(10)
    }

    func testProcessFail() {
        let conversationHelper = ConversationsHelper()
        conversationHelper.setUp(self)

        let errorDomain = "testdomain"

        let conversationProtocol = QredoConversationProtocolFSM(conversation: conversationHelper.creatorConversation)
        conversationProtocol.addStates([
            QredoConversationProtocolProcessingState { (state : QredoConversationProtocolProcessingState) -> Void in
                print("calling failWithError")
                state.failWithError(NSError(domain: errorDomain, code: 1, userInfo: nil))
            }
        ])

        var protocolFailExpectation : XCTestExpectation? = expectationWithDescription("fail protocol")
        let protocolDelegate = QredoConversationProtocolFSMBlockDelegate()
        protocolDelegate.onSuccess = {
            XCTFail("should not succeed")
        }

        protocolDelegate.onError = { error in
            XCTAssertEqual(error.domain, errorDomain, "error domains are different")
            protocolFailExpectation?.fulfill()
        }
        conversationProtocol.startWithDelegate(protocolDelegate)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            protocolFailExpectation = nil
        })


        // When processing state fails, the protocol also sends error message to the other side
        var receiveMessageExpectation : XCTestExpectation? = expectationWithDescription("received message")
        let conversationDelegate = ConversationBlockDelegate()
        conversationDelegate.messageHandler = { message in
            print("Received message \(message.dataType)")

            let stringValue = NSString(data: message.value, encoding: NSUTF8StringEncoding)
            print("message value: \(stringValue)")

            receiveMessageExpectation?.fulfill()
        }
        conversationHelper.responderConversation.addConversationObserver(conversationDelegate)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            receiveMessageExpectation = nil
        })

        conversationHelper.responderConversation.removeConversationObserver(conversationDelegate)

        conversationHelper.tearDown()
    }


    func testProcessInterruptBySelfCancel() {
        let conversationHelper = ConversationsHelper()
        conversationHelper.setUp(self)

        let conversationProtocol = QredoConversationProtocolFSM(conversation: conversationHelper.creatorConversation)
        conversationProtocol.addStates([
            QredoConversationProtocolProcessingState { (state : QredoConversationProtocolProcessingState) -> Void in
                var keepGoing = true
                print("start processing")

                state.onInterrupted {
                    print("interrupted")
                    keepGoing = false
                }

                while (keepGoing) {
                    NSThread.sleepForTimeInterval(0.1)
                }

                print("exit processing")
                state.finishProcessing()
            }
            ])

        var protocolSuccessExpectation : XCTestExpectation? = expectationWithDescription("finish protocol")
        let protocolDelegate = QredoConversationProtocolFSMBlockDelegate()
        protocolDelegate.onSuccess = {
            protocolSuccessExpectation?.fulfill()
        }

        protocolDelegate.onError = { error in
            XCTFail("should succeed")
        }
        conversationProtocol.startWithDelegate(protocolDelegate)

        // it should get to the state
        NSThread.sleepForTimeInterval(1.0)
        conversationProtocol.cancel()


        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            protocolSuccessExpectation = nil
        })


        // When processing state fails, the protocol also sends error message to the other side
        var receiveMessageExpectation : XCTestExpectation? = expectationWithDescription("received message")
        let conversationDelegate = ConversationBlockDelegate()
        conversationDelegate.messageHandler = { message in
            print("Received message \(message.dataType)")

            let stringValue = NSString(data: message.value, encoding: NSUTF8StringEncoding)
            print("message value: \(stringValue)")

            receiveMessageExpectation?.fulfill()
        }
        conversationHelper.responderConversation.addConversationObserver(conversationDelegate)

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            receiveMessageExpectation = nil
        })

        conversationHelper.responderConversation.removeConversationObserver(conversationDelegate)
        
        conversationHelper.tearDown()
    }


    func testProcessInterruptByOtherCancel() {
        let conversationHelper = ConversationsHelper()
        conversationHelper.setUp(self)

        let conversationProtocol = QredoConversationProtocolFSM(conversation: conversationHelper.creatorConversation)
        conversationProtocol.addStates([
            QredoConversationProtocolProcessingState { (state : QredoConversationProtocolProcessingState) -> Void in
                var keepGoing = true
                print("start processing")

                state.onInterrupted {
                    print("interrupted")
                    keepGoing = false
                }

                while (keepGoing) {
                    NSThread.sleepForTimeInterval(0.1)
                }

                print("exit processing")
                state.finishProcessing()
            }
            ])

        var protocolFailExpectation : XCTestExpectation? = expectationWithDescription("fail protocol")
        let protocolDelegate = QredoConversationProtocolFSMBlockDelegate()
        protocolDelegate.onSuccess = {
            XCTFail("should not succeed")
        }

        protocolDelegate.onError = { error in
            print("protocol.onError=\(error)")
            protocolFailExpectation?.fulfill()
        }
        conversationProtocol.startWithDelegate(protocolDelegate)

        // it should get to the state
        NSThread.sleepForTimeInterval(1.0)

        print("sending cancel message")
        conversationHelper.responderConversation.publishMessage(
            QredoConversationMessage(value: nil, dataType: "com.qredo.cancel", summaryValues: [:]),
            completionHandler: { (hwm, error) -> Void in
                print("sent cancel message")
                XCTAssertNil(error, "failed to send cancel message")
            }
        )

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: { (error) -> Void in
            protocolFailExpectation = nil
        })
        
        conversationHelper.tearDown()
    }

}
