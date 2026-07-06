//
//  FolioReaderHighlightProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderHighlightProvider: AnyObject {

    /// Save a Highlight with completion block
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - completion: Completion block.
    @objc func folioReaderHighlight(_ folioReader: FolioReader, added highlight: FolioReaderHighlight, completion: Completion?)
    
    /// Remove a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    @objc func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String)
    
    /// Update a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - type: The `HighlightStyle`
    @objc func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: FolioReaderHighlightStyle)
    
    /// Return a Highlight by ID
    ///
    /// - Parameter:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - page: Page number
    /// - Returns: Return a Highlight
    @objc func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> FolioReaderHighlight?
    
    /// Return a list of Highlights with a given ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - bookId: Book ID
    ///   - page: Page number
    /// - Returns: Return a list of Highlights
    @objc func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [FolioReaderHighlight]
    
    /// Return all Highlights
    ///
    /// - Parameter readerConfig: - readerConfig: Current folio reader configuration.
    /// - Returns: Return all Highlights
    @objc func folioReaderHighlight(_ folioReader: FolioReader) -> [FolioReaderHighlight]
    
    @objc func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: FolioReaderHighlight)
    
}

public class FolioReaderDummyHighlightProvider: FolioReaderHighlightProvider {
    
    public init() {
        
    }
    public func folioReaderHighlight(_ folioReader: FolioReader, added highlight: FolioReaderHighlight, completion: Completion?) {
        completion?(nil)
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: FolioReaderHighlightStyle) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> FolioReaderHighlight? {
        return nil
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [FolioReaderHighlight] {
        return []
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader) -> [FolioReaderHighlight] {
        return []
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: FolioReaderHighlight) {
        
    }
}

public protocol FolioReaderHighlightProviding {
    func addHighlight(_ highlight: FolioReaderHighlight, for folioReader: FolioReader) async throws
    func removeHighlight(id: String, for folioReader: FolioReader) async
    func updateHighlight(id: String, type style: FolioReaderHighlightStyle, for folioReader: FolioReader) async
    func highlight(byId id: String, for folioReader: FolioReader) async -> FolioReaderHighlight?
    func highlights(bookId: String, page: Int?, for folioReader: FolioReader) async -> [FolioReaderHighlight]
    func allHighlights(for folioReader: FolioReader) async -> [FolioReaderHighlight]
    func saveNote(for highlight: FolioReaderHighlight, folioReader: FolioReader) async
}

public struct FolioReaderHighlightProviderWrapper: FolioReaderHighlightProviding {
    private let provider: FolioReaderHighlightProvider

    public init(_ provider: FolioReaderHighlightProvider) {
        self.provider = provider
    }

    public func addHighlight(_ highlight: FolioReaderHighlight, for folioReader: FolioReader) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.provider.folioReaderHighlight(folioReader, added: highlight) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    public func removeHighlight(id: String, for folioReader: FolioReader) async {
        self.provider.folioReaderHighlight(folioReader, removedId: id)
    }

    public func updateHighlight(id: String, type style: FolioReaderHighlightStyle, for folioReader: FolioReader) async {
        self.provider.folioReaderHighlight(folioReader, updateById: id, type: style)
    }

    public func highlight(byId id: String, for folioReader: FolioReader) async -> FolioReaderHighlight? {
        self.provider.folioReaderHighlight(folioReader, getById: id)
    }

    public func highlights(bookId: String, page: Int?, for folioReader: FolioReader) async -> [FolioReaderHighlight] {
        let pageNumber: NSNumber? = page != nil ? NSNumber(value: page!) : nil
        return self.provider.folioReaderHighlight(folioReader, allByBookId: bookId, andPage: pageNumber)
    }

    public func allHighlights(for folioReader: FolioReader) async -> [FolioReaderHighlight] {
        self.provider.folioReaderHighlight(folioReader)
    }

    public func saveNote(for highlight: FolioReaderHighlight, folioReader: FolioReader) async {
        self.provider.folioReaderHighlight(folioReader, saveNoteFor: highlight)
    }
}

