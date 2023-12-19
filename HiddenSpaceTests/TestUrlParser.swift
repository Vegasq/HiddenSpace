import XCTest
@testable import HiddenSpace


class GeminiTextParserTests: XCTestCase {
    var geminiTextParser: GeminiTextParser!

    override func setUp() {
        super.setUp()
        self.geminiTextParser = GeminiTextParser(data: Data(), parentUrl: "")
    }

    override func tearDown() {
        self.geminiTextParser = nil
        super.tearDown()
    }

    func testUrlParser(){
        let testCases: [[String: String]] = [
            ["parent": "gemini://example.com", "url": "index.gmi", "expected": "gemini://example.com/index.gmi"],
            ["parent": "gemini://example.com/", "url": "index.gmi", "expected": "gemini://example.com/index.gmi"],
            ["parent": "gemini://example.com", "url": "/index.gmi", "expected": "gemini://example.com/index.gmi"],
            ["parent": "gemini://example.com/path/file.gmi", "url": "/index.gmi", "expected": "gemini://example.com/index.gmi"],
            ["parent": "gemini://example.com/path/file.gmi", "url": "index.gmi", "expected": "gemini://example.com/path/index.gmi"],
            ["parent": "gemini://example.com", "url": "gemini://example2.com", "expected": "gemini://example2.com"],
        ];

        for testCase in testCases {
            self.geminiTextParser.parentUrl = testCase["parent"]!;
            XCTAssertEqual(geminiTextParser.addPrefixIfNeeded(url: testCase["url"]!), testCase["expected"]!);
        }
    }
}
