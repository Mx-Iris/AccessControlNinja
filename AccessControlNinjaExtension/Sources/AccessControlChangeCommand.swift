import Foundation
import XcodeKit
import AccessControlNinjaCore
import UniformTypeIdentifiers

class AccessControlBaseCommand: NSObject, XCSourceEditorCommand, AccessControlCommand {
    var accessControlChange: AccessControlChange { fatalError() }

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping ((any Error)?) -> Void) {
        _perform(with: invocation, completionHandler: completionHandler)
    }
}

class SetPrivateLevelCommand: AccessControlBaseCommand {
    override var accessControlChange: AccessControlChange { .setLevel(.private, skipIfAlreadySet: false) }
}

class SetFileprivateLevelCommand: AccessControlBaseCommand {
    override var accessControlChange: AccessControlChange { .setLevel(.fileprivate, skipIfAlreadySet: false) }
}

class SetInternalLevelCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.internal, skipIfAlreadySet: false) }
}

class SetPackageLevelCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.package, skipIfAlreadySet: false) }
}

class SetPublicLevelCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.public, skipIfAlreadySet: false) }
}

class SetOpenLevelCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.open, skipIfAlreadySet: false) }
}

class SetPrivateLevelSkipIfAlreadySetCommand: AccessControlBaseCommand {
    override var accessControlChange: AccessControlChange { .setLevel(.private, skipIfAlreadySet: true) }
}

class SetFileprivateLevelSkipIfAlreadySetCommand: AccessControlBaseCommand {
    override var accessControlChange: AccessControlChange { .setLevel(.fileprivate, skipIfAlreadySet: true) }
}

class SetInternalLevelSkipIfAlreadySetCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.internal, skipIfAlreadySet: true) }
}

class SetPackageLevelSkipIfAlreadySetCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.package, skipIfAlreadySet: true) }
}

class SetPublicLevelSkipIfAlreadySetCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.public, skipIfAlreadySet: true) }
}

class SetOpenLevelSkipIfAlreadySetCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .setLevel(.open, skipIfAlreadySet: true) }
}

class IncreaseAccessLevelCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .increaseLevel }
}

class DecreaseAccessLevelCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .decreaseLevel }
}

class RemoveAccessControlCommand: AccessControlBaseCommand {

    override var accessControlChange: AccessControlChange { .removeAccessControl }
}

protocol AccessControlCommand: SourceEditorCommand {
    var accessControlChange: AccessControlChange { get }
}

extension AccessControlCommand {
    var name: String { accessControlChange.description }

    func _perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard (invocation.buffer.contentUTI == "com.apple.dt.playground") || (invocation.buffer.contentUTI == UTType.swiftSource.identifier) else {
            completionHandler(AccessControlError.unsupportedContentType)
            return
        }

        do {
            try applyAccessControlChange(buffer: invocation.buffer)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    func applyAccessControlChange(buffer: XCSourceTextBuffer) throws {
        guard let lines = buffer.lines as? [String], let selections = buffer.selections as? [XCSourceTextRange] else { return }

        if selections.isEmpty {
            throw AccessControlError.noSelection
        }

        let core = Core(lines: lines)

        let changedSelections = core.newLines(at: selections.map(\.sourceTextRange), accessChange: accessControlChange)

        for (line, content) in changedSelections {
            buffer.lines[line] = content
        }
    }
}

extension XCSourceTextRange {
    var sourceTextRange: SourceTextRange {
        .init(start: start.sourceTextPosition, end: end.sourceTextPosition)
    }
}

extension XCSourceTextPosition {
    var sourceTextPosition: SourceTextPosition {
        .init(line: line, column: column)
    }
}

public enum AccessControlError: LocalizedError, CustomNSError {
    case unsupportedContentType
    case noSelection

    var localizedDescription: String {
        switch self {
        case .unsupportedContentType: return "AccessControlKitty only works on Swift code."
        case .noSelection: return "AccessControlKitty needs a selection to work on."
        }
    }

    public var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: localizedDescription]
    }
}
