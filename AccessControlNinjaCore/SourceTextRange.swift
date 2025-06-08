public struct SourceTextRange: Hashable {
    public let start: SourceTextPosition
    public let end: SourceTextPosition

    public init(start: SourceTextPosition, end: SourceTextPosition) {
        self.start = start
        self.end = end
    }

    public var isEmpty: Bool {
        return start == end
    }

    public var length: Int {
        return end.line - start.line + 1
    }
}

public struct SourceTextPosition: Hashable {
    public let line: Int
    public let column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
}
