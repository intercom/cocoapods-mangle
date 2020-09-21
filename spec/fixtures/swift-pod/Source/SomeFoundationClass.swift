import Foundation
import SystemConfiguration

class SomeFoundationClass: NSObject {
    let value = 0

    func someMethod(flags: SCNetworkReachabilityFlags) -> SCNetworkReachabilityFlags {
        return flags
    }
}
