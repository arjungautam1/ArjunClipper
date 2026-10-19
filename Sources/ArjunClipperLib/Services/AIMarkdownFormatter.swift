import Foundation
import AppKit

public final class AIMarkdownFormatter {
    
    /// Detects if text contains common AI Markdown formatting (e.g., from ChatGPT, Claude, Gemini, DeepSeek)
    public static func containsAIMarkdown(_ text: String) -> Bool {
        // Paired bold asterisks: **word** or __word__
        let hasBold = text.range(of: #"\*\*[^\*\n]+\*\*"#, options: .regularExpression) != nil ||
                      text.range(of: #"__[^_\n]+__"#, options: .regularExpression) != nil
        // Inline code: `code`
        let hasCode = text.range(of: #"`[^`\n]+`"#, options: .regularExpression) != nil
        // Markdown headings: # Heading
        let hasHeading = text.range(of: #"(?m)^#{1,6}\s+.+"#, options: .regularExpression) != nil
        // Markdown list markers: * item or - item
        let hasList = text.range(of: #"(?m)^\s*[-*]\s+.+"#, options: .regularExpression) != nil
        
        return hasBold || hasCode || hasHeading || hasList
    }
    
    /// Cleans raw Markdown symbols (e.g. **bold** -> bold) for plain-text destinations like LinkedIn, Twitter, Slack, Terminal
    public static func cleanMarkdown(_ text: String) -> String {
        var result = text
        
        // 1. Triple asterisks (bold italic): ***text*** -> text
        result = result.replacingOccurrences(
            of: #"\*\*\*([^\*\n]+)\*\*\*"#,
            with: "$1",
            options: .regularExpression
        )
        
        // 2. Double asterisks (bold): **text** -> text
        result = result.replacingOccurrences(
            of: #"\*\*([^\*\n]+)\*\*"#,
            with: "$1",
            options: .regularExpression
        )
        
        // 3. Double underscores (bold): __text__ -> text
        result = result.replacingOccurrences(
            of: #"__([^_\n]+)__"#,
            with: "$1",
            options: .regularExpression
        )
        
        // 4. Standalone single asterisks for italic: *text* -> text
        result = result.replacingOccurrences(
            of: #"(?<!\*)\*([^\*\s\n][^\*\n]*?[^\*\s\n]|\S)\*(?!\*)"#,
            with: "$1",
            options: .regularExpression
        )
        
        // 5. Code blocks: ```lang\ncode\n``` -> code
        result = result.replacingOccurrences(
            of: #"```(?:\w+)?\n([\s\S]+?)\n```"#,
            with: "$1",
            options: .regularExpression
        )
        
        // 6. Inline code: `code` -> code
        result = result.replacingOccurrences(
            of: #"`([^`\n]+)`"#,
            with: "$1",
            options: .regularExpression
        )
        
        // 7. Markdown headings: ### Heading -> Heading
        result = result.replacingOccurrences(
            of: #"(?m)^#{1,6}\s+(.+)$"#,
            with: "$1",
            options: .regularExpression
        )
        
        // 8. Markdown list bullets: * item or - item -> • item
        result = result.replacingOccurrences(
            of: #"(?m)^(\s*)[-*]\s+(.+)$"#,
            with: "$1• $2",
            options: .regularExpression
        )
        
        return result
    }
    
    /// Converts Markdown text into rich HTML for rich-text destinations like Google Docs, Pages, Word, Notes, Mail
    public static func toHTML(_ text: String) -> String {
        // Escape HTML special characters
        var escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        // 1. Triple asterisks (bold italic): ***text*** -> <strong><em>text</em></strong>
        escaped = escaped.replacingOccurrences(
            of: #"\*\*\*([^\*\n]+)\*\*\*"#,
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )
        
        // 2. Bold: **text** -> <strong>text</strong>
        escaped = escaped.replacingOccurrences(
            of: #"\*\*([^\*\n]+)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        escaped = escaped.replacingOccurrences(
            of: #"__([^_\n]+)__"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        
        // 3. Italic: *text* -> <em>text</em>
        escaped = escaped.replacingOccurrences(
            of: #"(?<!\*)\*([^\*\s\n][^\*\n]*?[^\*\s\n]|\S)\*(?!\*)"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )
        
        // 4. Inline code: `code` -> <code>code</code>
        escaped = escaped.replacingOccurrences(
            of: #"`([^`\n]+)`"#,
            with: "<code style=\"background-color: rgba(27,31,35,0.06); padding: 2px 4px; border-radius: 4px; font-family: monospace;\">$1</code>",
            options: .regularExpression
        )
        
        // 5. Code blocks: ```lang\ncode\n``` -> <pre><code>code</code></pre>
        escaped = escaped.replacingOccurrences(
            of: #"```(?:\w+)?\n([\s\S]+?)\n```"#,
            with: "<pre style=\"background-color: #f6f8fa; padding: 12px; border-radius: 6px; font-family: monospace; overflow-x: auto;\"><code>$1</code></pre>",
            options: .regularExpression
        )
        
        // 6. Markdown headings
        escaped = escaped.replacingOccurrences(
            of: #"(?m)^###\s+(.+)$"#,
            with: "<h3 style=\"margin: 12px 0 6px 0;\">$1</h3>",
            options: .regularExpression
        )
        escaped = escaped.replacingOccurrences(
            of: #"(?m)^##\s+(.+)$"#,
            with: "<h2 style=\"margin: 16px 0 8px 0;\">$1</h2>",
            options: .regularExpression
        )
        escaped = escaped.replacingOccurrences(
            of: #"(?m)^#\s+(.+)$"#,
            with: "<h1 style=\"margin: 20px 0 10px 0;\">$1</h1>",
            options: .regularExpression
        )
        
        // 7. Bullet lists: * item or - item -> bullet styled div
        escaped = escaped.replacingOccurrences(
            of: #"(?m)^(\s*)[-*]\s+(.+)$"#,
            with: "<div style=\"margin-left: 20px;\">• $2</div>",
            options: .regularExpression
        )
        
        // 8. Convert newlines to <br> for regular paragraphs
        let lines = escaped.components(separatedBy: "\n")
        var processedLines: [String] = []
        for line in lines {
            if line.hasPrefix("<h") || line.hasPrefix("<pre") || line.hasPrefix("<div") || line.hasPrefix("</pre") {
                processedLines.append(line)
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                processedLines.append("<br>")
            } else {
                processedLines.append("<p style=\"margin: 4px 0;\">\(line)</p>")
            }
        }
        
        let bodyContent = processedLines.joined(separator: "\n")
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 14px; line-height: 1.6; color: #1f2328;">
        \(bodyContent)
        </body>
        </html>
        """
    }
    
    /// Converts HTML into macOS RTF Data for Apple Notes, Mail, Pages, TextEdit
    public static func toRTF(html: String) -> Data? {
        guard let data = html.data(using: .utf8) else { return nil }
        guard let attrStr = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else {
            return nil
        }
        return try? attrStr.data(
            from: NSRange(location: 0, length: attrStr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}
