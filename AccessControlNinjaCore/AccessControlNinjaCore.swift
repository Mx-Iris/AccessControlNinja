import SwiftSyntax
import SwiftParser

public struct Core {
    private var lines: [String]

    public init(lines: [String]) {
        self.lines = lines
    }

    func selectedLines(in selections: [SourceTextRange]) -> [Int] {
        let selectedLines = selections.flatMap { lines($0, totalLinesInBuffer: lines.count) }
        let set = Set(selectedLines)
        return Array(set).sorted()
    }
    
    public func newLines(at selections: [SourceTextRange], accessChange: AccessControlChange) -> [Int: String] {
        var newLines: [Int: String] = [:]
        
        let selectedLines = selectedLines(in: selections)
        
        let sourceFile = Parser.parse(source: selectedLines.map { lines[$0] }.joined())

        let rewriter = AccessControlRewriter(accessChange: accessChange)

        let modifiedSyntax = rewriter.rewrite(sourceFile)

        let newContents = modifiedSyntax.description
        
        let splitContents = newContents.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        
        for (lineNumber, content) in zip(selectedLines, splitContents) {
            newLines[lineNumber] = content
        }

        return newLines
    }
    
    func lines(_ range: SourceTextRange, totalLinesInBuffer: Int) -> [Int] {
        // Always include the whole line UNLESS the start and end positions are exactly the same, in which return an empty array
        if range.start.line == range.end.line, range.start.column == range.end.column {
            return []
        } else if totalLinesInBuffer == range.end.line {
            return Array(range.start.line ..< range.end.line)
        } else if range.end.column == 0 {
            return Array(range.start.line ..< range.end.line)
        } else {
            return Array(range.start.line ... range.end.line)
        }
    }

}

