import Foundation
import SwiftSyntax

public enum AccessControlLevel: String, CaseIterable {
    case `private`
    case `fileprivate`
    case `internal`
    case `package`
    case `public`
    case `open`

    static let allKeywords: [Keyword] = [.public, .private, .internal, .fileprivate, .open, .package]


    static func forKeyword(_ keyword: Keyword) -> AccessControlLevel? {
        switch keyword {
        case .public: return .public
        case .private: return .private
        case .internal: return .internal
        case .fileprivate: return .fileprivate
        case .open: return .open
        case .package: return .package
        default: return nil
        }
    }
    
    var keyword: Keyword {
        switch self {
        case .public:
            return .public
        case .private:
            return .private
        case .internal:
            return .internal
        case .package:
            return .package
        case .fileprivate:
            return .fileprivate
        case .open:
            return .open
        }
    }
    
    var increase: AccessControlLevel {
        switch self {
        case .private: return .fileprivate
        case .fileprivate: return .internal
        case .internal: return .package
        case .package: return .public
        case .public: return .open
        case .open: return .open
        }
    }
    
    var decrease: AccessControlLevel {
        switch self {
        case .private: return .private
        case .fileprivate: return .private
        case .internal: return .fileprivate
        case .package: return .internal
        case .public: return .package
        case .open: return .public
        }
    }
}

extension AccessControlLevel: Comparable {
    public static func < (_ lhs: AccessControlLevel, _ rhs: AccessControlLevel) -> Bool {
        return lhs.order < rhs.order
    }

    var order: Int {
        switch self {
        case .private: return -2
        case .fileprivate: return -1
        case .internal: return 0
        case .package: return 1
        case .public: return 2
        case .open: return 3
        }
    }
}

extension AccessControlLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .private:
            "Private"
        case .fileprivate:
            "Fileprivate"
        case .internal:
            "Internal"
        case .package:
            "Package"
        case .public:
            "Public"
        case .open:
            "Open"
        }
    }
}
