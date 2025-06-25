import SwiftSyntax
import SwiftParser

final class AccessControlRewriter: SyntaxRewriter {
    let accessChange: AccessControlChange

    init(accessChange: AccessControlChange) {
        self.accessChange = accessChange
        super.init(viewMode: .sourceAccurate)
    }

    private func newAccessModifierSyntax(for level: AccessControlLevel) -> DeclModifierSyntax {
        return DeclModifierSyntax(name: .keyword(level.keyword))
    }

    private func isNestedFunction(_ node: FunctionDeclSyntax) -> Bool {
        return node.parent?.parent?.parent?.parent?.is(FunctionDeclSyntax.self) ?? false
    }

    private func processModifiers(
        existingModifiers: DeclModifierListSyntax?,
        declKeywordOriginalLeadingTrivia: Trivia
    ) -> (finalModifiers: DeclModifierListSyntax, finalDeclKeywordLeadingTrivia: Trivia) {
        var modifiers: [DeclModifierSyntax] = existingModifiers?.children(viewMode: .sourceAccurate).compactMap { $0.as(DeclModifierSyntax.self) } ?? []

        let hasAccessModifier = modifiers.contains { $0.isAccessControl }

        var effectiveInitialLeadingTrivia: Trivia

        if let firstOriginalModifier = modifiers.first {
            effectiveInitialLeadingTrivia = firstOriginalModifier.leadingTrivia
        } else {
            effectiveInitialLeadingTrivia = declKeywordOriginalLeadingTrivia
        }

        var removedAccessModifierOriginalLeadingTrivia: Trivia? = nil

        let modifiersCopy = modifiers

        func removeAllAccessControlKeywords() {
            modifiers.removeAll { modifier in
                if modifier.isAccessControl {
                    if removedAccessModifierOriginalLeadingTrivia == nil && modifier == modifiersCopy.first {
                        removedAccessModifierOriginalLeadingTrivia = modifier.leadingTrivia
                    }
                    return true
                }
                return false
            }
        }

        switch accessChange {
        case let .setLevel(accessControlLevel, skipIfAlreadySet):
            if skipIfAlreadySet, hasAccessModifier {} else {
                removeAllAccessControlKeywords()
                modifiers.insert(DeclModifierSyntax(name: .keyword(accessControlLevel.keyword)), at: 0)
            }
        case .increaseLevel:
            for (index, modifier) in modifiersCopy.enumerated() {
                if case let .keyword(keyword) = modifier.name.tokenKind, let level = AccessControlLevel.forKeyword(keyword) {
                    removeAllAccessControlKeywords()
                    modifiers.insert(newAccessModifierSyntax(for: level.increase), at: index)
                    break
                }
            }
        case .decreaseLevel:
            for (index, modifier) in modifiersCopy.enumerated() {
                if case let .keyword(keyword) = modifier.name.tokenKind, let level = AccessControlLevel.forKeyword(keyword) {
                    removeAllAccessControlKeywords()
                    modifiers.insert(newAccessModifierSyntax(for: level.decrease), at: index)
                    break
                }
            }
        case .removeAccessControl:
            for modifier in modifiersCopy {
                if case let .keyword(keyword) = modifier.name.tokenKind, let _ = AccessControlLevel.forKeyword(keyword) {
                    removeAllAccessControlKeywords()
                    break
                }
            }
        }

        if let removedTrivia = removedAccessModifierOriginalLeadingTrivia {
            effectiveInitialLeadingTrivia = removedTrivia
        }

        var finalKeywordLeadingTrivia = declKeywordOriginalLeadingTrivia

        if modifiers.isEmpty {
            finalKeywordLeadingTrivia = effectiveInitialLeadingTrivia
            return (DeclModifierListSyntax([]), finalKeywordLeadingTrivia)
        }

        for i in 0 ..< modifiers.count {
            var currentModifier = modifiers[i]
            if i == 0 {
                currentModifier = currentModifier.with(\.leadingTrivia, effectiveInitialLeadingTrivia)
                finalKeywordLeadingTrivia = .init()
            } else {
                currentModifier = currentModifier.with(\.leadingTrivia, .init())
            }
            currentModifier = currentModifier.with(\.trailingTrivia, .spaces(1))
            modifiers[i] = currentModifier
        }

        return (DeclModifierListSyntax(modifiers), finalKeywordLeadingTrivia)
    }

    // MARK: - Visit Methods

    private func _visit<TargetDeclSyntax: AccessControlDeclSyntax>(_ node: TargetDeclSyntax) -> DeclSyntax {
        var newNode = node
        let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(existingModifiers: node.modifiers, declKeywordOriginalLeadingTrivia: node.keyword.leadingTrivia)
        newNode.modifiers = processedModifiers
        newNode.keyword = newNode.keyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        return DeclSyntax(newNode)
    }

    private func _visitWithMembers<TargetDeclSyntax: AccessControlDeclSyntax & HasMembersDeclSyntax>(_ node: TargetDeclSyntax, visitSelf: Bool = true) -> DeclSyntax {
        var members: [MemberBlockItemSyntax] = []
        for var member in node.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                member = member.with(\.decl, visit(variableDecl))
            }
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                member = member.with(\.decl, visit(functionDecl))
            }
            if let initializerDecl = member.decl.as(InitializerDeclSyntax.self) {
                member = member.with(\.decl, visit(initializerDecl))
            }
            if let subscriptDecl = member.decl.as(SubscriptDeclSyntax.self) {
                member = member.with(\.decl, visit(subscriptDecl))
            }
            if let typeAliasDecl = member.decl.as(TypeAliasDeclSyntax.self) {
                member = member.with(\.decl, visit(typeAliasDecl))
            }
            if let classDecl = member.decl.as(ClassDeclSyntax.self) {
                member = member.with(\.decl, visit(classDecl))
            }
            if let structDecl = member.decl.as(StructDeclSyntax.self) {
                member = member.with(\.decl, visit(structDecl))
            }
            if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
                member = member.with(\.decl, visit(enumDecl))
            }
            if let protocolDecl = member.decl.as(ProtocolDeclSyntax.self) {
                member = member.with(\.decl, visit(protocolDecl))
            }
            members.append(member)
        }
        let node = node.with(\.memberBlock.members, MemberBlockItemListSyntax(members))
        if visitSelf {
            return _visit(node)
        } else {
            return DeclSyntax(node)
        }
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if isNestedFunction(node) {
            return super.visit(node)
        }

        return _visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        return _visitWithMembers(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        return _visitWithMembers(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        return _visitWithMembers(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        return _visitWithMembers(node, visitSelf: node.memberBlock.members.isEmpty)
    }
}

protocol AccessControlDeclSyntax: DeclSyntaxProtocol {
    var keyword: TokenSyntax { set get }
    var modifiers: DeclModifierListSyntax { set get }
}

protocol HasMembersDeclSyntax: DeclSyntaxProtocol {
    var memberBlock: MemberBlockSyntax { set get }
}

extension FunctionDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { funcKeyword = newValue }
        get { funcKeyword }
    }
}

extension ClassDeclSyntax: AccessControlDeclSyntax, HasMembersDeclSyntax {
    var keyword: TokenSyntax {
        set { classKeyword = newValue }
        get { classKeyword }
    }
}

extension StructDeclSyntax: AccessControlDeclSyntax, HasMembersDeclSyntax {
    var keyword: TokenSyntax {
        set { structKeyword = newValue }
        get { structKeyword }
    }
}

extension EnumDeclSyntax: AccessControlDeclSyntax, HasMembersDeclSyntax {
    var keyword: TokenSyntax {
        set { enumKeyword = newValue }
        get { enumKeyword }
    }
}

extension ProtocolDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { protocolKeyword = newValue }
        get { protocolKeyword }
    }
}

extension VariableDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { bindingSpecifier = newValue }
        get { bindingSpecifier }
    }
}

extension InitializerDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { initKeyword = newValue }
        get { initKeyword }
    }
}

extension SubscriptDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { subscriptKeyword = newValue }
        get { subscriptKeyword }
    }
}

extension TypeAliasDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { typealiasKeyword = newValue }
        get { typealiasKeyword }
    }
}

extension ImportDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { importKeyword = newValue }
        get { importKeyword }
    }
}

extension ExtensionDeclSyntax: AccessControlDeclSyntax, HasMembersDeclSyntax {
    var keyword: TokenSyntax {
        set { extensionKeyword = newValue }
        get { extensionKeyword }
    }
}

extension DeclModifierSyntax {
    var isAccessControl: Bool {
        if case let .keyword(keyword) = name.tokenKind {
            return AccessControlLevel.allKeywords.contains(keyword)
        }
        return false
    }
}
