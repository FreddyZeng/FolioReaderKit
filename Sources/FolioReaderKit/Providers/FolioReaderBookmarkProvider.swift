//
//  FolioReaderBookmarkProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderBookmarkProvider: AnyObject {

    /// Save a Bookmark with completion block
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, added bookmark: FolioReaderBookmark, completion: Completion?)
    
    /// Remove a Bookmark by pos(cfi)
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, removed bookmarkPos: String)
    
    /// Update a Bookmark Title by pos
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, updated bookmarkPos: String, title: String)
    
    /// Return a Bookmark by Pos
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, getBy bookmarkPos: String) -> FolioReaderBookmark?
    
    /// Return a list of Bookmarks with specified book and optionally page
    ///
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - page: Page number
    /// - Returns: Return a list of Bookmarks
    @objc func folioReaderBookmark(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [FolioReaderBookmark]
    
    /// Return all Bookmarks
    ///
    /// - Returns: Return all Bookmarks
    @objc func folioReaderBookmark(_ folioReader: FolioReader) -> [FolioReaderBookmark]
}

public class FolioReaderNaiveBookmarkProvider: FolioReaderBookmarkProvider {
    
    var bookmarks = [String:FolioReaderBookmark]()  //key: pos
    
    public init() {
        let bookmark = FolioReaderBookmark()
        bookmark.pos_type = "epubcfi"
        bookmark.pos = "epubcfi(/22/2/4/10/1:316)"
        bookmark.page = 11
        bookmark.bookId = ""
        bookmark.title = "Test Bookmark"
        bookmark.date = Date(timeIntervalSince1970: 1660614468.141)
        bookmarks[bookmark.pos!] = bookmark
        
    }
    public func folioReaderBookmark(_ folioReader: FolioReader, added bookmark: FolioReaderBookmark, completion: Completion?) {
        var error:NSError? = nil
        defer {
            completion?(error)
        }
        
        guard let pos = bookmark.pos else {
            error = FolioReaderBookmarkError.emptyError("") as NSError
            return
        }
        
        guard bookmarks[pos] == nil else {
            error = FolioReaderBookmarkError.duplicateError(bookmarks[pos]?.title ?? "Untitled Bookmark") as NSError
            return
        }
        
        bookmarks[pos] = bookmark
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, removed bookmarkPos: String) {
        bookmarks.removeValue(forKey: bookmarkPos)
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, updated bookmarkPos: String, title: String) {
        bookmarks[bookmarkPos]?.title = title
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, getBy bookmarkPos: String) -> FolioReaderBookmark? {
        return bookmarks[bookmarkPos]
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [FolioReaderBookmark] {
        return bookmarks.values.filter { return $0.page == (page?.intValue ?? $0.page) }
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader) -> [FolioReaderBookmark] {
        return bookmarks.values.map { $0 }
    }
    
}

public protocol FolioReaderBookmarkProviding {
    func addBookmark(_ bookmark: FolioReaderBookmark, for folioReader: FolioReader) async throws
    func removeBookmark(pos: String, for folioReader: FolioReader) async
    func updateBookmark(pos: String, title: String, for folioReader: FolioReader) async
    func bookmark(byPos pos: String, for folioReader: FolioReader) async -> FolioReaderBookmark?
    func bookmarks(bookId: String, page: Int?, for folioReader: FolioReader) async -> [FolioReaderBookmark]
    func allBookmarks(for folioReader: FolioReader) async -> [FolioReaderBookmark]
}

public struct FolioReaderBookmarkProviderWrapper: FolioReaderBookmarkProviding {
    private let provider: FolioReaderBookmarkProvider

    public init(_ provider: FolioReaderBookmarkProvider) {
        self.provider = provider
    }

    public func addBookmark(_ bookmark: FolioReaderBookmark, for folioReader: FolioReader) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.provider.folioReaderBookmark(folioReader, added: bookmark) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    public func removeBookmark(pos: String, for folioReader: FolioReader) async {
        self.provider.folioReaderBookmark(folioReader, removed: pos)
    }

    public func updateBookmark(pos: String, title: String, for folioReader: FolioReader) async {
        self.provider.folioReaderBookmark(folioReader, updated: pos, title: title)
    }

    public func bookmark(byPos pos: String, for folioReader: FolioReader) async -> FolioReaderBookmark? {
        self.provider.folioReaderBookmark(folioReader, getBy: pos)
    }

    public func bookmarks(bookId: String, page: Int?, for folioReader: FolioReader) async -> [FolioReaderBookmark] {
        let pageNumber: NSNumber? = page != nil ? NSNumber(value: page!) : nil
        return self.provider.folioReaderBookmark(folioReader, allByBookId: bookId, andPage: pageNumber)
    }

    public func allBookmarks(for folioReader: FolioReader) async -> [FolioReaderBookmark] {
        self.provider.folioReaderBookmark(folioReader)
    }
}

