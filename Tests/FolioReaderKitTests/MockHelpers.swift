// =================================================================
// 文件路径参考：Tests/FolioReaderKitTests/MockHelpers.swift
// 说明：该文件包含所有用于解耦测试的 Mock 实现
// =================================================================

import Foundation
import WebKit
@testable import FolioReaderKit

// MARK: - Mock Highlight Provider (配合 TEST-TASK-002)
public class MockHighlightProvider: FolioReaderHighlightProvider {
    
    // 内存存储字典，Key 为 highlightId
    private var storage: [String: FolioReaderHighlight] = [:]
    
    public init() {}
    
    public func folioReaderHighlight(_ folioReader: FolioReader, added highlight: FolioReaderHighlight, completion: Completion?) {
        storage[highlight.highlightId] = highlight
        completion?(nil)
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> FolioReaderHighlight? {
        return storage[highlightId]
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String) {
        storage.removeValue(forKey: highlightId)
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: FolioReaderHighlightStyle) {
        if let highlight = storage[highlightId] {
            highlight.type = style.rawValue
            storage[highlightId] = highlight
        }
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber? = nil) -> [FolioReaderHighlight] {
        let results = storage.values.filter { highlight in
            let matchBook = (highlight.bookId == bookId)
            if let targetPage = page {
                return matchBook && (highlight.page == targetPage.intValue)
            }
            return matchBook
        }
        
        // 按照页码和偏移量排序返回
        return results.sorted {
            if $0.page == $1.page {
                return $0.startOffset < $1.startOffset
            }
            return $0.page < $1.page
        }
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader) -> [FolioReaderHighlight] {
        return Array(storage.values)
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: FolioReaderHighlight) {
        storage[highlight.highlightId] = highlight
    }
    
    // 仅供测试验证使用的便捷方法
    public var totalStoredCount: Int {
        return storage.count
    }
}

// MARK: - Mock WKScriptMessage (配合 TEST-TASK-003)
/// 用于模拟从 JS 端传回的 Message 对象
public class MockWKScriptMessage: WKScriptMessage {
    private let mockBody: Any
    private let mockName: String
    
    public init(body: Any, name: String = "FolioReaderPage") {
        self.mockBody = body
        self.mockName = name
        super.init()
    }
    
    public override var body: Any {
        return mockBody
    }
    
    public override var name: String {
        return mockName
    }
}

// MARK: - Mock Script Message Handler (配合 TEST-TASK-003)
/// 用于验证 Swift 是否正确拦截和解析了 JS 回调
public class MockScriptMessageHandler: NSObject, WKScriptMessageHandler {
    public var lastReceivedMessageBody: Any?
    public var messageReceivedCount = 0
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.lastReceivedMessageBody = message.body
        self.messageReceivedCount += 1
    }
}

// MARK: - Mock Read Position Provider
public class MockReadPositionProvider: NSObject, FolioReaderReadPositionProvider {
    private var storage: [String: [FolioReaderReadPosition]] = [:]
    private let lock = NSLock()
    
    public override init() {}
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String) -> FolioReaderReadPosition? {
        lock.lock()
        defer { lock.unlock() }
        return storage[bookId]?.first { $0.takePrecedence } ?? storage[bookId]?.last
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, by pageNumber: Int) -> FolioReaderReadPosition? {
        lock.lock()
        defer { lock.unlock() }
        return storage[bookId]?.first { $0.pageNumber == pageNumber }
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, set position: FolioReaderReadPosition, completion: Completion?) {
        lock.lock()
        defer { lock.unlock() }
        var positions = storage[bookId] ?? []
        if let index = positions.firstIndex(where: { $0.cfi == position.cfi }) {
            positions[index] = position
        } else {
            positions.append(position)
        }
        storage[bookId] = positions
        completion?(nil)
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, remove readPosition: FolioReaderReadPosition) {
        lock.lock()
        defer { lock.unlock() }
        storage[bookId]?.removeAll { $0.cfi == readPosition.cfi }
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, getById deviceId: String) -> [FolioReaderReadPosition] {
        lock.lock()
        defer { lock.unlock() }
        return storage[bookId]?.filter { $0.deviceId == deviceId } ?? []
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, allByBookId bookId: String) -> [FolioReaderReadPosition] {
        lock.lock()
        defer { lock.unlock() }
        return storage[bookId] ?? []
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader) -> [FolioReaderReadPosition] {
        lock.lock()
        defer { lock.unlock() }
        return storage.values.flatMap { $0 }
    }
    
    public func folioReaderPositionHistory(_ folioReader: FolioReader, bookId: String) -> [FolioReaderReadPositionHistory] {
        return []
    }
}

// MARK: - Mock Bookmark Provider
public class MockBookmarkProvider: NSObject, FolioReaderBookmarkProvider {
    private var storage: [String: FolioReaderBookmark] = [:]
    
    public override init() {}
    
    public func folioReaderBookmark(_ folioReader: FolioReader, added bookmark: FolioReaderBookmark, completion: Completion?) {
        if let pos = bookmark.pos {
            storage[pos] = bookmark
        }
        completion?(nil)
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, removed bookmarkPos: String) {
        storage.removeValue(forKey: bookmarkPos)
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, updated bookmarkPos: String, title: String) {
        if let bookmark = storage[bookmarkPos] {
            bookmark.title = title
            storage[bookmarkPos] = bookmark
        }
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, getBy bookmarkPos: String) -> FolioReaderBookmark? {
        return storage[bookmarkPos]
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [FolioReaderBookmark] {
        let results = storage.values.filter { bookmark in
            let matchBook = (bookmark.bookId == bookId)
            if let targetPage = page {
                return matchBook && (bookmark.page == targetPage.intValue)
            }
            return matchBook
        }
        return results.sorted {
            if $0.page == $1.page {
                return ($0.pos ?? "") < ($1.pos ?? "")
            }
            return $0.page < $1.page
        }
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader) -> [FolioReaderBookmark] {
        return Array(storage.values)
    }
}

// MARK: - Mock Preference Provider
public class MockPreferenceProvider: NSObject, FolioReaderPreferenceProvider {
    private var storage: [String: Any] = [:]
    public var profiles: [String] = ["Default"]
    public var currentProfile: String = "Default"
    
    public override init() {}
    
    public func preference(stringFor key: String, default defaultValue: String) -> String {
        return storage[key] as? String ?? defaultValue
    }
    
    public func preference(setString value: String, for key: String) {
        storage[key] = value
    }
    
    public func preference(intFor key: String, default defaultValue: Int) -> Int {
        return storage[key] as? Int ?? defaultValue
    }
    
    public func preference(setInt value: Int, for key: String) {
        storage[key] = value
    }
    
    public func preference(boolFor key: String, default defaultValue: Bool) -> Bool {
        return storage[key] as? Bool ?? defaultValue
    }
    
    public func preference(setBool value: Bool, for key: String) {
        storage[key] = value
    }
    
    public func preference(listProfile filter: String?) -> [String] {
        if let filter = filter {
            return profiles.filter { $0.contains(filter) }
        }
        return profiles
    }
    
    public func preference(saveProfile name: String) {
        if !profiles.contains(name) {
            profiles.append(name)
        }
        currentProfile = name
    }
    
    public func preference(loadProfile name: String) {
        if profiles.contains(name) {
            currentProfile = name
        }
    }
    
    public func preference(removeProfile name: String) {
        profiles.removeAll { $0 == name }
        if currentProfile == name {
            currentProfile = "Default"
        }
    }
}

// MARK: - Mock FolioReader Delegate
public class MockFolioReaderDelegate: NSObject, FolioReaderDelegate {
    public let highlightProvider = MockHighlightProvider()
    public let bookmarkProvider = MockBookmarkProvider()
    public let preferenceProvider = MockPreferenceProvider()
    public let readPositionProvider = MockReadPositionProvider()
    
    public func folioReaderHighlightProvider(_ folioReader: FolioReader) -> FolioReaderHighlightProvider {
        return highlightProvider
    }
    
    public func folioReaderBookmarkProvider(_ folioReader: FolioReader) -> FolioReaderBookmarkProvider {
        return bookmarkProvider
    }
    
    public func folioReaderPreferenceProvider(_ folioReader: FolioReader) -> FolioReaderPreferenceProvider {
        return preferenceProvider
    }
    
    public func folioReaderReadPositionProvider(_ folioReader: FolioReader) -> FolioReaderReadPositionProvider {
        return readPositionProvider
    }
}
