import XCTest
@testable import FolioReaderKit

class MockProvidersTests: XCTestCase {
    
    func testMockHighlightProviderCRUD() {
        let provider = MockHighlightProvider()
        let folioReader = FolioReader()
        
        let highlight = FolioReaderHighlight()
        highlight.highlightId = "h1"
        highlight.bookId = "book1"
        highlight.content = "content"
        highlight.page = 1
        
        // Save
        let expectation = XCTestExpectation(description: "Save highlight")
        provider.folioReaderHighlight(folioReader, added: highlight) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Get
        let retrieved = provider.folioReaderHighlight(folioReader, getById: "h1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.content, "content")
        
        // Update
        provider.folioReaderHighlight(folioReader, updateById: "h1", type: .yellow)
        let updated = provider.folioReaderHighlight(folioReader, getById: "h1")
        XCTAssertEqual(updated?.type, FolioReaderHighlightStyle.yellow.rawValue)
        
        // Filter
        let allInBook = provider.folioReaderHighlight(folioReader, allByBookId: "book1", andPage: 1)
        XCTAssertEqual(allInBook.count, 1)
        
        let allInOtherBook = provider.folioReaderHighlight(folioReader, allByBookId: "book2", andPage: 1)
        XCTAssertEqual(allInOtherBook.count, 0)
        
        // Remove
        provider.folioReaderHighlight(folioReader, removedId: "h1")
        XCTAssertNil(provider.folioReaderHighlight(folioReader, getById: "h1"))
    }
}
