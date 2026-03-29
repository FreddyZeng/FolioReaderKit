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
    
    public func save(_ highlight: FolioReaderHighlight) {
        storage[highlight.highlightId] = highlight
    }
    
    public func getById(_ highlightId: String) -> FolioReaderHighlight? {
        return storage[highlightId]
    }
    
    public func removeById(_ highlightId: String) {
        storage.removeValue(forKey: highlightId)
    }
    
    public func remove(_ highlight: FolioReaderHighlight) {
        removeById(highlight.highlightId)
    }
    
    public func updateById(_ highlightId: String, type: Int) {
        if let highlight = storage[highlightId] {
            highlight.type = type
            storage[highlightId] = highlight
        }
    }
    
    public func allByBookId(_ bookId: String, andPage page: NSNumber? = nil) -> [FolioReaderHighlight] {
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
    
    public func all() -> [FolioReaderHighlight] {
        return Array(storage.values)
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
