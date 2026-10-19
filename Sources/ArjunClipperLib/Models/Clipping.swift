import Foundation

public struct Clipping: Identifiable, Codable, Equatable {
    public let id: UUID
    public let content: String
    public let htmlContent: String?
    public let timestamp: Date
    public let sourceAppName: String?
    public let sourceBundleId: String?
    public var isPinned: Bool
    
    public init(
        id: UUID = UUID(),
        content: String,
        htmlContent: String? = nil,
        timestamp: Date = Date(),
        sourceAppName: String? = nil,
        sourceBundleId: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.content = content
        self.htmlContent = htmlContent
        self.timestamp = timestamp
        self.sourceAppName = sourceAppName
        self.sourceBundleId = sourceBundleId
        self.isPinned = isPinned
    }
    
    public var characterCount: Int {
        content.count
    }
    
    public func preview(maxLength: Int = 40) -> String {
        let singleLine = content
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if singleLine.count <= maxLength {
            return singleLine
        }
        let endIndex = singleLine.index(singleLine.startIndex, offsetBy: maxLength)
        return String(singleLine[..<endIndex]) + "…"
    }
}
