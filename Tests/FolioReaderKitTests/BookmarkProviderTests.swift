//
//  BookmarkProviderTests.swift
//  FolioReaderKitTests
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import XCTest
@testable import FolioReaderKit

class BookmarkProviderTests: XCTestCase {
    
    func testMockBookmarkProviderCRUD() {
        let provider = MockBookmarkProvider()
        let folioReader = FolioReader()
        
        let bookmark1 = FolioReaderBookmark()
        bookmark1.bookId = "book-a"
        bookmark1.title = "Bookmark A"
        bookmark1.pos = "pos-1"
        bookmark1.page = 1
        
        let bookmark2 = FolioReaderBookmark()
        bookmark2.bookId = "book-a"
        bookmark2.title = "Bookmark B"
        bookmark2.pos = "pos-2"
        bookmark2.page = 2
        
        let bookmark3 = FolioReaderBookmark()
        bookmark3.bookId = "book-b"
        bookmark3.title = "Bookmark C"
        bookmark3.pos = "pos-3"
        bookmark3.page = 3
        
        // Add bookmarks
        let exp1 = expectation(description: "Added bookmark1")
        provider.folioReaderBookmark(folioReader, added: bookmark1) { error in
            XCTAssertNil(error)
            exp1.fulfill()
        }
        
        let exp2 = expectation(description: "Added bookmark2")
        provider.folioReaderBookmark(folioReader, added: bookmark2) { error in
            XCTAssertNil(error)
            exp2.fulfill()
        }
        
        let exp3 = expectation(description: "Added bookmark3")
        provider.folioReaderBookmark(folioReader, added: bookmark3) { error in
            XCTAssertNil(error)
            exp3.fulfill()
        }
        
        wait(for: [exp1, exp2, exp3], timeout: 1.0)
        
        // Test allBookmarks
        let all = provider.folioReaderBookmark(folioReader)
        XCTAssertEqual(all.count, 3)
        
        // Test getBy bookmarkPos
        let retrieved = provider.folioReaderBookmark(folioReader, getBy: "pos-1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Bookmark A")
        
        // Test allByBookId
        let bookA = provider.folioReaderBookmark(folioReader, allByBookId: "book-a", andPage: nil)
        XCTAssertEqual(bookA.count, 2)
        XCTAssertEqual(bookA.first?.title, "Bookmark A")
        XCTAssertEqual(bookA.last?.title, "Bookmark B")
        
        // Test update bookmark
        provider.folioReaderBookmark(folioReader, updated: "pos-1", title: "Updated Title A")
        let retrievedUpdated = provider.folioReaderBookmark(folioReader, getBy: "pos-1")
        XCTAssertEqual(retrievedUpdated?.title, "Updated Title A")
        
        // Test remove bookmark
        provider.folioReaderBookmark(folioReader, removed: "pos-1")
        XCTAssertNil(provider.folioReaderBookmark(folioReader, getBy: "pos-1"))
        XCTAssertEqual(provider.folioReaderBookmark(folioReader).count, 2)
    }
}
