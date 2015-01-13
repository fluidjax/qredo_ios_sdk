/*
*  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
*/

import Foundation


extension Dictionary {
    func contains<K, V where V : Equatable>(subdictionary:[K:V]) -> Bool {
        for (key, value) in subdictionary {
            let selfValue : Value? = self[key as Key]

            if let actualValue = selfValue {
                let subValue = subdictionary[key]!

                if !(actualValue is V) {
                    return false
                }

                if actualValue as V != subValue {
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }
}