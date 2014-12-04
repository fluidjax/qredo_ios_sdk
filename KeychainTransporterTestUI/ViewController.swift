/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func receiveKeychain(sender: AnyObject) {
        let receiver = QredoKeychainReceiverQR()

        receiver.qredoKeychainReceiverWillCreateRendezvous(nil)
    }
}

