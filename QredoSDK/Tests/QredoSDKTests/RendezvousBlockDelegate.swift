/* HEADER GOES HERE */
import UIKit

class RendezvousBlockObserver : NSObject, QredoRendezvousObserver {
    var responseHandler : (QredoConversation -> Void)? = nil
    var errorHandler : (NSError -> Void)? = nil

    func RendezvousBlockObserver(responseBlock : (QredoConversation! -> Void), errorHandler: (NSError -> Void)) {
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