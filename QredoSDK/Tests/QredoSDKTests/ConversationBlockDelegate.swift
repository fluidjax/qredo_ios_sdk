/* HEADER GOES HERE */
import UIKit

class ConversationBlockDelegate : NSObject, QredoConversationObserver {
    var messageHandler: ((QredoConversationMessage) -> Void)? = nil
    var otherPartyLeftHandler: (() -> Void)? = nil

    func qredoConversation(conversation: QredoConversation!, didReceiveNewMessage message: QredoConversationMessage!) {
        messageHandler?(message)
    }

    func qredoConversationOtherPartyHasLeft(conversation: QredoConversation!) {
        otherPartyLeftHandler?()
    }
}
