//
//  BookmarkCodableTests.swift
//  FolioReaderKitTests
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import XCTest
@testable import FolioReaderKit

class BookmarkCodableTests: XCTestCase {
    
    func testBookmarkSerializationRoundtrip() {
        let bookmark = FolioReaderBookmark()
        bookmark.bookId = "book-789"
        bookmark.date = Date(timeIntervalSince1970: 20000000)
        bookmark.title = "Bookmark Title"
        bookmark.page = 12
        bookmark.pos_type = "epubcfi"
        bookmark.pos = "epubcfi(/6/6[chap-3]!/4/2/8:15)"
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(bookmark) else {
            XCTFail("Failed to encode FolioReaderBookmark")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let decoded = try? decoder.decode(FolioReaderBookmark.self, from: data) else {
            XCTFail("Failed to decode FolioReaderBookmark")
            return
        }
        
        XCTAssertEqual(decoded.bookId, bookmark.bookId)
        XCTAssertEqual(decoded.date, bookmark.date)
        XCTAssertEqual(decoded.title, bookmark.title)
        XCTAssertEqual(decoded.page, bookmark.page)
        XCTAssertEqual(decoded.pos_type, bookmark.pos_type)
        XCTAssertEqual(decoded.pos, bookmark.pos)
    }
}
