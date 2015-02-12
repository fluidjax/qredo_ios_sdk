/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit

class AuthenticationProtocolBlockDelegate : NSObject, QredoAuthenticationProtocolDelegate {
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