/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit

class KeychainSenderMock : NSObject, QredoKeychainSenderDelegate {
    enum State {
        case Idle
        case DiscoveredRendezvous
        case VerifiedRendezvous
        case EstablishedConnection
        case ConfirmedConnection
        case Failed
        case Completed
    }

    var state : State = .Idle
    var shouldCancelAt : State? = nil

    var shouldPassConfirmation = false
    var shouldDiscoverTag = "a test tag"

    var didCallDiscoverRendezvous = false
    var didCallEstablishedConnection = false
    var didCallFail = false
    var didCallFinishSending = false

    var didVerifyTag : Bool? = nil

    var cancelHandler : (() -> Void)! = nil
    var stateHandler : ((State) -> Void)! = nil

    var shouldWaitForRendezvousTag = false

    var discoverSemaphore = dispatch_semaphore_create(0)

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

    func discoverTag(tag: String) {
        shouldDiscoverTag = tag
        dispatch_semaphore_signal(discoverSemaphore)
    }

    // Delegate methods

    func qredoKeychainSenderDiscoverRendezvous(sender: QredoKeychainSender!, completionHander completionHandler: ((/*rendezvousTag:*/ String!) -> Bool)!, cancelHandler: (() -> Void)!) {
        didCallDiscoverRendezvous = true

        self.cancelHandler = cancelHandler

        // If we want to cancel scanning
        if switchState(.Idle) { return }
        if switchState(.DiscoveredRendezvous) { return }

        if self.shouldWaitForRendezvousTag {
            dispatch_semaphore_wait(discoverSemaphore, DISPATCH_TIME_FOREVER);
            println("discovered tag \(self.shouldDiscoverTag)")
        }

        didVerifyTag = completionHandler(shouldDiscoverTag)

        if didVerifyTag == true {
            if switchState(.VerifiedRendezvous) { return }
        }
    }

    func qredoKeychainSender(sender: QredoKeychainSender!, didEstablishConnectionWithDevice deviceInfo: QredoDeviceInfo!, fingerprint: String!, confirmationHandler: ((/*confirmed:*/ Bool) -> Void)!) {
        didCallEstablishedConnection = true

        if switchState(.EstablishedConnection) { return }
        confirmationHandler(shouldPassConfirmation);
        if shouldPassConfirmation {
            if switchState(.ConfirmedConnection) { return }
        }
    }

    func qredoKeychainSender(sender: QredoKeychainSender!, didFailWithError error: NSError!) {
        didCallFail = true

        if switchState(.Failed) { return }
    }

    func qredoKeychainSenderDidFinishSending(sender: QredoKeychainSender!) {
        didCallFinishSending = true
        
        if switchState(.Completed) { return }
    }
    
}