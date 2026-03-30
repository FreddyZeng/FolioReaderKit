import XCTest
@testable import FolioReaderKit

class FolioReaderHighlightTests: XCTestCase {
    
    func testHighlightInitialization() {
        let highlight = FolioReaderHighlight()
        highlight.bookId = "testBook"
        highlight.page = 1
        highlight.startOffset = 10
        highlight.endOffset = 20
        highlight.highlightId = "id1"
        
        XCTAssertEqual(highlight.bookId, "testBook")
        XCTAssertEqual(highlight.page, 1)
        XCTAssertEqual(highlight.startOffset, 10)
        XCTAssertEqual(highlight.highlightId, "id1")
    }
    
    func testHighlightComparison() {
        let h1 = FolioReaderHighlight()
        h1.page = 1
        h1.startOffset = 10
        
        let h2 = FolioReaderHighlight()
        h2.page = 1
        h2.startOffset = 20
        
        let h3 = FolioReaderHighlight()
        h3.page = 2
        h3.startOffset = 5
        
        XCTAssertTrue(h1 < h2)
        XCTAssertTrue(h1 < h3)
        XCTAssertTrue(h2 < h3)
        XCTAssertFalse(h2 < h1)
    }
    
    func testMatchHighlight() {
        let html = """
        <p>This is a <highlight id="hl1" onclick="someAction()" class="highlight-yellow">highlighted text</highlight> in HTML.</p>
        """
        let matching = FolioReaderHighlight.MatchingHighlight(
            text: html,
            id: "hl1",
            startOffset: "100",
            endOffset: "115",
            bookId: "testBook",
            currentPage: 5
        )
        
        let result = FolioReaderHighlight.matchHighlight(matching)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.highlightId, "hl1")
        XCTAssertEqual(result?.content, "highlighted text")
        XCTAssertEqual(result?.bookId, "testBook")
        XCTAssertEqual(result?.page, 5)
        XCTAssertEqual(result?.startOffset, 100)
    }
}
