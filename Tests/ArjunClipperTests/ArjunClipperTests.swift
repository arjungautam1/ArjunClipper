import XCTest
import AppKit
@testable import ArjunClipperLib

final class ArjunClipperTests: XCTestCase {
    
    func testAppExclusionFilter() {
        let filter = CopyFilter(
            excludedBundleIdentifiers: ["com.agilebits.onepassword", "com.apple.keychainaccess"],
            excludedAppNames: ["1Password", "Keychain Access"]
        )
        
        // 1. Blocked bundle ID
        let res1 = filter.shouldCopy(
            content: "SecretMasterPassword123!",
            sourceBundleId: "com.agilebits.onepassword",
            sourceAppName: "1Password",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(res1, .rejected(.appExcluded))
        
        // 2. Blocked app name
        let res2 = filter.shouldCopy(
            content: "AnotherSecret",
            sourceBundleId: "com.random.app",
            sourceAppName: "Keychain Access",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(res2, .rejected(.appExcluded))
        
        // 3. Allowed app
        let res3 = filter.shouldCopy(
            content: "Hello World",
            sourceBundleId: "com.apple.dt.Xcode",
            sourceAppName: "Xcode",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(res3, .allowed)
    }
    
    func testSensitiveDataFilters() {
        var filter = CopyFilter()
        filter.blockPrivateKeys = true
        filter.blockCreditCardNumbers = true
        filter.blockApiKeysAndTokens = true
        
        // Private key detection
        let privKey = "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0...\n-----END RSA PRIVATE KEY-----"
        let resKey = filter.shouldCopy(
            content: privKey,
            sourceBundleId: "com.apple.Terminal",
            sourceAppName: "Terminal",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(resKey, .rejected(.privateKeyDetected))
        
        // Credit card detection (16 digits)
        let cc = "4111 2222 3333 4444"
        let resCC = filter.shouldCopy(
            content: cc,
            sourceBundleId: "com.google.Chrome",
            sourceAppName: "Google Chrome",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(resCC, .rejected(.creditCardDetected))
        
        // AWS Access Key detection
        let awsKey = "export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE"
        let resAWS = filter.shouldCopy(
            content: awsKey,
            sourceBundleId: "com.apple.Terminal",
            sourceAppName: "Terminal",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(resAWS, .rejected(.apiKeyDetected))
    }
    
    func testLengthAndWhitespaceFilters() {
        var filter = CopyFilter()
        filter.ignoreWhitespaceOnly = true
        filter.minLength = 3
        filter.maxLength = 100
        
        // Whitespace only
        let resSpace = filter.shouldCopy(
            content: "   \n\t  ",
            sourceBundleId: "com.apple.Notes",
            sourceAppName: "Notes",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(resSpace, .rejected(.whitespaceOnly))
        
        // Below min length
        let resShort = filter.shouldCopy(
            content: "ab",
            sourceBundleId: "com.apple.Notes",
            sourceAppName: "Notes",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(resShort, .rejected(.tooShort))
        
        // Exceeds max length
        let resLong = filter.shouldCopy(
            content: String(repeating: "X", count: 101),
            sourceBundleId: "com.apple.Notes",
            sourceAppName: "Notes",
            pasteboardTypes: [.string]
        )
        XCTAssertEqual(resLong, .rejected(.tooLong))
    }
    
    func testTransientPasteboardTypeFilter() {
        let filter = CopyFilter(ignoreTransientPasteboardTypes: true)
        
        let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        let res = filter.shouldCopy(
            content: "CopiedFromPasswordManager",
            sourceBundleId: "com.apple.Safari",
            sourceAppName: "Safari",
            pasteboardTypes: [.string, transientType]
        )
        XCTAssertEqual(res, .rejected(.transientPasteboard))
    }
    
    func testClippingPreviewFormatting() {
        let multiline = "Line 1\nLine 2\r\nLine 3 with extra long text here"
        let clip = Clipping(content: multiline)
        
        let preview = clip.preview(maxLength: 20)
        XCTAssertFalse(preview.contains("\n"))
        XCTAssertTrue(preview.hasSuffix("…"))
    }
}
