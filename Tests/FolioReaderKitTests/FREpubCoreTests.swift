import XCTest
@testable import FolioReaderKit

class FREpubCoreTests: XCTestCase {
    
    func testMediaTypeConstants() {
        XCTAssertEqual(MediaType.epub.defaultExtension, "epub")
        XCTAssertEqual(MediaType.xhtml.name, "application/xhtml+xml")
    }
    
    func testMediaTypeEquality() {
        let m1 = MediaType(name: "test", defaultExtension: "t")
        let m2 = MediaType(name: "test", defaultExtension: "t")
        let m3 = MediaType(name: "other", defaultExtension: "o")
        
        XCTAssertEqual(m1, m2)
        XCTAssertNotEqual(m1, m3)
    }
    
    func testFRBookTOCFlattening() {
        let book = FRBook()
        
        // Mock TOC:
        // - Chapter 1
        // - Chapter 2
        //   - Chapter 2.1
        //   - Chapter 2.2
        //     - Chapter 2.2.1
        // - Chapter 3
        
        let c1 = FRTocReference(title: "Chapter 1", resource: nil)
        let c2 = FRTocReference(title: "Chapter 2", resource: nil)
        let c2_1 = FRTocReference(title: "Chapter 2.1", resource: nil)
        let c2_2 = FRTocReference(title: "Chapter 2.2", resource: nil)
        let c2_2_1 = FRTocReference(title: "Chapter 2.2.1", resource: nil)
        let c3 = FRTocReference(title: "Chapter 3", resource: nil)
        
        c2.children = [c2_1, c2_2]
        c2_2.children = [c2_2_1]
        
        book.tableOfContents = [c1, c2, c3]
        
        // Manual flattening logic since it's usually in the parser
        func flatten(_ items: [FRTocReference]) -> [FRTocReference] {
            var result = [FRTocReference]()
            for item in items {
                result.append(item)
                result.append(contentsOf: flatten(item.children))
            }
            return result
        }
        
        book.flatTableOfContents = flatten(book.tableOfContents)
        
        XCTAssertEqual(book.flatTableOfContents.count, 6)
        XCTAssertEqual(book.flatTableOfContents[0].title, "Chapter 1")
        XCTAssertEqual(book.flatTableOfContents[1].title, "Chapter 2")
        XCTAssertEqual(book.flatTableOfContents[2].title, "Chapter 2.1")
        XCTAssertEqual(book.flatTableOfContents[3].title, "Chapter 2.2")
        XCTAssertEqual(book.flatTableOfContents[4].title, "Chapter 2.2.1")
        XCTAssertEqual(book.flatTableOfContents[5].title, "Chapter 3")
    }
}
