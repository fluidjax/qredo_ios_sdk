/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit

class KeychainReceiverMock : NSObject, QredoKeychainReceiverDelegate {
    enum State {
        case Idle
        case Prepared
        case CreatedRendezvous
        case SentDeviceInfo
        case EstablishedConnection
        case ReceivedKeychain
        case InstalledKeychain
        case Failed
    }

    var state : State = .Idle
    var shouldCancelAt : State? = nil
    var cancelHandler : (() -> Void)! = nil
    var stateHandler : ((State) -> Void)! = nil

    var shouldPassConfirmation = false

    var didCallWillCreateRendezvous = false
    var didCallDidCreateRendezvous = false
    var didCallDidEstablishConnection = false
    var didCallDidFail = false
    var didCallDidReceiveKeychain = false
    var didCallDidInstallKeychain = false

    var didSendDeviceInfo = false

    var rendezvousTag : String? = nil
    var connectionFingerprint : String? = nil


    func switchState(state: State) -> Bool {
        self.state = state

        if let actualStateHandler = stateHandler {
            actualStateHandler(state)
        }

        if shouldCancelAt == state {
            cancelHandler()
            return true
        }
        return false
    }

    // Delegate methods

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, willCreateRendezvousWithCancelHandler cancelHandler: (() -> Void)!) {
        didCallWillCreateRendezvous = true

        self.cancelHandler = cancelHandler

        if switchState(.Idle) { return }
        if switchState(.Prepared) { return }
    }

    func qredoKeychainReceiverDidSendDeviceInfo(receiver: QredoKeychainReceiver!) {
        didSendDeviceInfo = true

        if switchState(.SentDeviceInfo) { return }
    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didCreateRendezvousWithTag tag: String!) {
        didCallDidCreateRendezvous = true

        rendezvousTag = tag
        if switchState(.CreatedRendezvous) { return }
    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didEstablishConnectionWithFingerprint fingerPrint: String!) {
        didCallDidEstablishConnection = true

        connectionFingerprint = fingerPrint

        if switchState(.EstablishedConnection) { return }
    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didFailWithError error: NSError!) {
        didCallDidFail = true

        if switchState(.Failed) { return }
    }

    func qredoKeychainReceiver(receiver: QredoKeychainReceiver!, didReceiveKeychainWithConfirmationHandler confirmationHandler: ((Bool) -> Void)!) {
        didCallDidReceiveKeychain = true

        if switchState(.ReceivedKeychain) { return }

        confirmationHandler(shouldPassConfirmation)
    }

    func qredoKeychainReceiverDidInstallKeychain(receiver: QredoKeychainReceiver!) {
        didCallDidInstallKeychain = true
        
        if shouldPassConfirmation {
            if switchState(.InstalledKeychain) { return }
        }
    }
}