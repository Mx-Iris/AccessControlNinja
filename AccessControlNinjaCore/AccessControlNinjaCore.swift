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

        let selectedLines = selectedLines(in: selections)

        let sourceFile = Parser.parse(source: selectedLines.map { lines[$0] }.joined())

        let rewriter = AccessControlRewriter(accessChange: accessChange)

        let modifiedSyntax = rewriter.rewrite(sourceFile)

        guard let sourceFile = modifiedSyntax.as(SourceFileSyntax.self) else {
            return selectedLines.reduce(into: [:]) { $0[$1] = lines[$1] }
        }

        return contentByLine(sourceFile: sourceFile, targetLines: selectedLines)
        
//        let newContents = modifiedSyntax.description
//
//        let splitContents = newContents.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
//
//        for (lineNumber, content) in zip(selectedLines, splitContents) {
//            newLines[lineNumber] = content
//        }

    }

    private func contentByLine(sourceFile: SourceFileSyntax, targetLines: [Int]) -> [Int: String] {
        // 1. Create a SourceLocationConverter for the source file.
        let converter = SourceLocationConverter(fileName: "Source.swift", tree: sourceFile)

        // 2. Get the location of the end of the file to validate the line number.
        let endOfFileLocation = converter.location(for: sourceFile.endPosition)
        func content(byLine lineNumber: Int) -> String {

            // 3. Get the starting byte position of the requested line.
            let startPosition = converter.position(ofLine: lineNumber, column: 1)

            // 4. Determine the ending byte position.
            // It's the start of the next line, or the end of the file if it's the last line.
            let endPosition: AbsolutePosition
            if lineNumber < endOfFileLocation.line {
                // It's not the last line, so the end is the start of the next line.
                endPosition = converter.position(ofLine: lineNumber + 1, column: 1)
            } else {
                // It's the last line, so the end is the end of the file.
                endPosition = sourceFile.endPosition
            }

            // 5. Get the raw bytes of the source file.
            let sourceBytes = sourceFile.syntaxTextBytes

            // 6. Slice the bytes corresponding to the line.
            // The range is from the start of the line to just before the start of the next line.
            let lineBytes = sourceBytes[startPosition.utf8Offset ..< endPosition.utf8Offset]

            // 7. Convert the byte slice to a String.
            let lineString = String(decoding: lineBytes, as: UTF8.self)
            return lineString
        }
        var result: [Int: String] = [:]
        for (index, targetLine) in targetLines.sorted().enumerated() {
            let lineNumber = index + 1
            result[targetLine] = content(byLine: lineNumber)
        }
        return result
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
