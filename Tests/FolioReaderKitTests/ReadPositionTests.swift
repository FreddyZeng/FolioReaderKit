import XCTest
@testable import FolioReaderKit

class ReadPositionTests: XCTestCase {
    
    class MockFolioReaderDelegate: NSObject, FolioReaderDelegate {
        let positionProvider = MockReadPositionProvider()
        
        func folioReaderReadPositionProvider(_ folioReader: FolioReader) -> FolioReaderReadPositionProvider {
            return positionProvider
        }
    }
    
    func testCentralizedSaveLogicClearsPrecedence() {
        let folioReader = FolioReader()
        let delegate = MockFolioReaderDelegate()
        folioReader.delegate = delegate
        
        let bookId = "testBook"
        let p1 = FolioReaderReadPosition(deviceId: "d1", structuralStyle: .bundle, positionTrackingStyle: .linear, structuralRootPageNumber: 1, pageNumber: 1, cfi: "cfi1")
        p1.takePrecedence = true
        
        let p2 = FolioReaderReadPosition(deviceId: "d1", structuralStyle: .bundle, positionTrackingStyle: .linear, structuralRootPageNumber: 1, pageNumber: 2, cfi: "cfi2")
        p2.takePrecedence = true
        
        // 1. Save p1 with precedence
        folioReader.save(readPosition: p1, for: bookId)
        
        let expectation1 = XCTestExpectation(description: "Async save p1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation1.fulfill() }
        wait(for: [expectation1], timeout: 1.0)
        
        XCTAssertTrue(p1.takePrecedence)
        
        // 2. Save p2 with precedence. It should clear p1's precedence.
        folioReader.save(readPosition: p2, for: bookId)
        
        let expectation2 = XCTestExpectation(description: "Async save p2")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation2.fulfill() }
        wait(for: [expectation2], timeout: 1.0)
        
        XCTAssertFalse(p1.takePrecedence, "p1's precedence should be cleared")
        XCTAssertTrue(p2.takePrecedence, "p2 should maintain its precedence")
        
        let allPositions = delegate.positionProvider.folioReaderReadPosition(folioReader, allByBookId: bookId)
        XCTAssertEqual(allPositions.count, 2)
        XCTAssertEqual(allPositions.filter { $0.takePrecedence }.count, 1)
    }
}
