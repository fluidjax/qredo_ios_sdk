/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit

class RendezvousBlockDelegate : NSObject, QredoRendezvousDelegate {
    var responseHandler : (QredoConversation -> Void)? = nil
    var errorHandler : (NSError -> Void)? = nil

    func RendezvousBlockDelegate(responseBlock : (QredoConversation! -> Void), errorHandler: (NSError -> Void)) {
        self.responseHandler = responseBlock
        self.errorHandler = errorHandler
    }

    func qredoRendezvous(rendezvous: QredoRendezvous!, didReceiveReponse conversation: QredoConversation!) {
        responseHandler?(conversation);
    }

    func qredoRendezvous(rendezvous: QredoRendezvous!, didTimeout error: NSError!) {
        errorHandler?(error)
    }
}