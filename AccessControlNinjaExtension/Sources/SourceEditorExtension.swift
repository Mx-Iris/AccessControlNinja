import Foundation
import XcodeKit
import AccessControlNinjaCore

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    func extensionDidFinishLaunching() {}

    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        [
            SetPrivateLevelCommand(),
            SetFileprivateLevelCommand(),
            SetInternalLevelCommand(),
            SetPackageLevelCommand(),
            SetPublicLevelCommand(),
            SetOpenLevelCommand(),
            SetPrivateLevelSkipIfAlreadySetCommand(),
            SetFileprivateLevelSkipIfAlreadySetCommand(),
            SetInternalLevelSkipIfAlreadySetCommand(),
            SetPackageLevelSkipIfAlreadySetCommand(),
            SetPublicLevelSkipIfAlreadySetCommand(),
            SetOpenLevelSkipIfAlreadySetCommand(),
            IncreaseAccessLevelCommand(),
            DecreaseAccessLevelCommand(),
            RemoveAccessControlCommand()
        ].map(makeCommandDefinition)
    }
}

let identifierPrefix: String = Bundle.main.bundleIdentifier ?? ""

protocol SourceEditorCommand: NSObject {
    var commandClassName: String { get }
    var identifier: String { get }
    var name: String { get }
}

extension SourceEditorCommand {
    var commandClassName: String { Self.className() }
    var identifier: String { String(describing: Self.self) }

    func makeCommandDefinition() -> [XCSourceEditorCommandDefinitionKey: Any] {
        [.classNameKey: commandClassName,
         .identifierKey: identifierPrefix + "." + identifier,
         .nameKey: name]
    }
}

func makeCommandDefinition(_ command: SourceEditorCommand)
    -> [XCSourceEditorCommandDefinitionKey: Any] {
    command.makeCommandDefinition()
}
