import Foundation

public enum AccessControlChange {
    case setLevel(AccessControlLevel, skipIfAlreadySet: Bool = true)
    case increaseLevel
    case decreaseLevel
    case removeAccessControl
}

extension AccessControlChange: CustomStringConvertible {
    public var description: String {
        switch self {
        case .setLevel(let accessControlLevel, let skipIfAlreadySet):
            if skipIfAlreadySet {
                return "Set \(accessControlLevel) Level Skip If Already Set"
            } else {
                return "Set \(accessControlLevel) Level"
            }
        case .increaseLevel:
            return "Increase Level"
        case .decreaseLevel:
            return "Decrease Level"
        case .removeAccessControl:
            return "Remove Access Control"
        }
    }
}
