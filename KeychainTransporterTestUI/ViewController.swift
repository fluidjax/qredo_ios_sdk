/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import UIKit

func dispatch_time_from_now(delta: NSTimeInterval) -> dispatch_time_t {
    return dispatch_time(DISPATCH_TIME_NOW, Int64(delta * Double(NSEC_PER_SEC)))
}

class ViewController: UIViewController {

    var keychainReceiver: QredoKeychainReceiverQR?
    var keychainSender: QredoKeychainSenderQR?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func receiveKeychain(sender: AnyObject) {
        
        let rec = QredoKeychainReceiverQR()
        
        keychainReceiver = rec

        rec.qredoKeychainReceiver(nil, willCreateRendezvousWithCancelHandler: { () -> Void in})
        
        dispatch_after(dispatch_time_from_now(2), dispatch_get_main_queue()) { () -> Void in
            
            rec.qredoKeychainReceiver(nil, didCreateRendezvousWithTag: "test")
            
            dispatch_after(dispatch_time_from_now(2), dispatch_get_main_queue()) { () -> Void in
                
                rec.qredoKeychainReceiver(nil, didEstablishConnectionWithFingerprint: "My finger print!")
                
                dispatch_after(dispatch_time_from_now(2), nil, { () -> Void in
                    
                    rec.qredoKeychainReceiver(nil, didReceiveKeychainWithConfirmationHandler: { (confirmed) -> Void in
                        if confirmed {
                            dispatch_after(dispatch_time_from_now(2), nil, { () -> Void in
                                rec.qredoKeychainReceiverDidInstallKeychain(nil)
                            })
                        }
                    })
                    
                })
                
            }
            
        }
        
    }
    
    
    @IBAction func sendKeychain(sender: AnyObject) {
        
        let snd = QredoKeychainSenderQR()
        
        keychainSender = snd
        
        snd.qredoKeychainSenderDiscoverRendezvous(nil, completionHander: { (rendezvousTag) -> Bool in
            
            dispatch_after(dispatch_time_from_now(2), nil, { () -> Void in
                
                let deviceInfo = QredoDeviceInfo()
                deviceInfo.name = "my device"
                
                snd.qredoKeychainSender(
                    nil,
                    didEstablishConnectionWithDevice: deviceInfo,
                    fingerprint: "some fingerprint",
                    confirmationHandler: { (confirmed) -> Void in
                        
                        if confirmed {
                            
                            dispatch_after(dispatch_time_from_now(2), nil, { () -> Void in
                                snd.qredoKeychainSenderDidFinishSending(nil)
                            })
                            
                        }
                        
                    }
                )
                
            })
            
            return true
        }) { () -> Void in
            
        }
        
    }
    
}

