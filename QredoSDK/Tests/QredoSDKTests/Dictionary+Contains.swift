/* HEADER GOES HERE */
import Foundation


extension Dictionary {
    func contains<K, V where V : Equatable>(subdictionary:[K:V]) -> Bool {
        for (key, _) in subdictionary {
            let selfValue : Value? = self[key as! Key]

            if let actualValue = selfValue {
                let subValue = subdictionary[key]!

                if !(actualValue is V) {
                    return false
                }

                if actualValue as! V != subValue {
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }
}