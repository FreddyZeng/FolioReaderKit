//
//  Bookmark.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 11/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

/// A Bookmark object
@objc open class FolioReaderBookmark: NSObject, Codable {
    open var bookId: String
    
    open var date: Date
    open var title: String
    open var page: Int = 0
    open var pos_type: String?      //should be epubcfi
    open var pos: String?       //like epubcfi(/2/4/4/1:10)

    public override init() {
        self.bookId = ""
        self.date = Date()
        self.title = ""
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bookId = try container.decodeIfPresent(String.self, forKey: .bookId) ?? ""
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 0
        self.pos_type = try container.decodeIfPresent(String.self, forKey: .pos_type)
        self.pos = try container.decodeIfPresent(String.self, forKey: .pos)
        super.init()
    }
    
    open override func copy() -> Any {
        let bookmark = FolioReaderBookmark()
        bookmark.bookId = self.bookId
        bookmark.date = self.date
        bookmark.title = self.title
        bookmark.page = self.page
        bookmark.pos_type = self.pos_type
        bookmark.pos = self.pos
        
        return bookmark
    }
}

public enum FolioReaderBookmarkError: Error {
    case emptyError(String)
    case duplicateError(String)
    case runtimeError(String)
}

extension FolioReaderBookmark: Comparable {
    public static let SeperatorSet: CharacterSet = ["/", ":", "(", ")"]
    
    public static func < (lhs: FolioReaderBookmark, rhs: FolioReaderBookmark) -> Bool {
        if lhs.page != rhs.page {
            return lhs.page < rhs.page
        }
        if let lStart = lhs.pos, let rStart = rhs.pos {
            let lSplit = lStart.split { $0.unicodeScalars.allSatisfy { scalar in
                SeperatorSet.contains(scalar)
            } }
            let rSplit = rStart.split { $0.unicodeScalars.allSatisfy { scalar in
                SeperatorSet.contains(scalar)
            } }
            for i in 0..<min(lSplit.count, rSplit.count) {
                var l = Int(lSplit[i]) ?? 0
                var r = Int(rSplit[i]) ?? 0
                if let square = lSplit[i].firstIndex(of: "[") {
                    l = Int(lSplit[i][lSplit[i].startIndex..<square]) ?? 0
                }
                if let square = rSplit[i].firstIndex(of: "[") {
                    r = Int(rSplit[i][rSplit[i].startIndex..<square]) ?? 0
                }
                if l != r {
                    return l < r
                }
            }
        }
        return lhs.title < rhs.title    //fallback
    }
    
}
