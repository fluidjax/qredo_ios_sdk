/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit
import XCTest


class KeychainReceiverMock : NSObject, QredoKeychainReceiverDelegate {
    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didCreateRendezvousWithTag tag: String!, cancelHandler: (() -> Void)!) {

    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didEstablishConnectionWithFingerprint fingerPrint: String!) {

    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didFailWithError error: NSError!) {

    }

    func qredoKeychainReceiverDidReceiveKeychain(receiver: QredoKeychainReceiver!) {

    }

    func qredoKeychainReceiverWillCreateRendezvous(receiver: QredoKeychainReceiver!) {
        
    }
}


class KeychainTransporterReceiverTests: XCTestCase {
    var senderClient : QredoClient!
    var receiverClient : QredoClient!

    override func setUp() {
        super.setUp()

        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: QredoClientOptions(resetData: true)) { client, error in
            XCTAssertNil(error, "Failed to authenticate the test")
            XCTAssertNotNil(client, "Client should not be nil")

            self.senderClient = client
        }

        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: [], options: QredoClientOptions(resetData: true)) { client, error in
            XCTAssertNil(error, "Failed to authenticate the test")
            XCTAssertNotNil(client, "Client should not be nil")

            self.receiverClient = client
        }
    }


}
