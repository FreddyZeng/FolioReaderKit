import XCTest
@testable import FolioReaderKit

class FolioReaderBookmarkTests: XCTestCase {
    
    func testBookmarkComparison() {
        let b1 = FolioReaderBookmark()
        b1.page = 1
        b1.pos = "epubcfi(/2/4/4/1:10)"
        
        let b2 = FolioReaderBookmark()
        b2.page = 1
        b2.pos = "epubcfi(/2/4/4/1:20)"
        
        let b3 = FolioReaderBookmark()
        b3.page = 2
        b3.pos = "epubcfi(/2/4/4/1:5)"
        
        XCTAssertTrue(b1 < b2)
        XCTAssertTrue(b1 < b3)
        XCTAssertTrue(b2 < b3)
    }
}
