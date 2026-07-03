//
//  HighlightCodableTests.swift
//  FolioReaderKitTests
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import XCTest
@testable import FolioReaderKit

class HighlightCodableTests: XCTestCase {
    
    func testHighlightSerializationRoundtrip() {
        let highlight = FolioReaderHighlight()
        highlight.bookId = "book-123"
        highlight.content = "This is a highlight content"
        highlight.contentPre = "pre content"
        highlight.contentPost = "post content"
        highlight.date = Date(timeIntervalSince1970: 10000000)
        highlight.highlightId = "h-456"
        highlight.page = 5
        highlight.type = 2
        highlight.style = "yellow"
        highlight.startOffset = 10
        highlight.endOffset = 25
        highlight.noteForHighlight = "Some personal note"
        highlight.cfiStart = "epubcfi(/6/4[chap-2]!/4/2/10:10)"
        highlight.cfiEnd = "epubcfi(/6/4[chap-2]!/4/2/10:25)"
        highlight.spineName = "chapter-2"
        highlight.tocFamilyTitles = ["Chapter 2", "Section 2.1"]
        highlight.encodeContents()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(highlight) else {
            XCTFail("Failed to encode FolioReaderHighlight")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let decoded = try? decoder.decode(FolioReaderHighlight.self, from: data) else {
            XCTFail("Failed to decode FolioReaderHighlight")
            return
        }
        
        XCTAssertEqual(decoded.bookId, highlight.bookId)
        XCTAssertEqual(decoded.content, highlight.content)
        XCTAssertEqual(decoded.contentPre, highlight.contentPre)
        XCTAssertEqual(decoded.contentPost, highlight.contentPost)
        XCTAssertEqual(decoded.date, highlight.date)
        XCTAssertEqual(decoded.highlightId, highlight.highlightId)
        XCTAssertEqual(decoded.page, highlight.page)
        XCTAssertEqual(decoded.type, highlight.type)
        XCTAssertEqual(decoded.style, highlight.style)
        XCTAssertEqual(decoded.startOffset, highlight.startOffset)
        XCTAssertEqual(decoded.endOffset, highlight.endOffset)
        XCTAssertEqual(decoded.noteForHighlight, highlight.noteForHighlight)
        XCTAssertEqual(decoded.cfiStart, highlight.cfiStart)
        XCTAssertEqual(decoded.cfiEnd, highlight.cfiEnd)
        XCTAssertEqual(decoded.contentEncoded, highlight.contentEncoded)
        XCTAssertEqual(decoded.contentPreEncoded, highlight.contentPreEncoded)
        XCTAssertEqual(decoded.contentPostEncoded, highlight.contentPostEncoded)
        XCTAssertEqual(decoded.spineName, highlight.spineName)
        XCTAssertEqual(decoded.tocFamilyTitles, highlight.tocFamilyTitles)
    }
}
