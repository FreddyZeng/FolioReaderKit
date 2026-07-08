//
//  DataAccumulator.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import Foundation

/// A thread-safe data accumulator for concurrent closures.
public final class DataAccumulator: @unchecked Sendable {
    private let data = NSMutableData()
    private let lock = NSLock()

    public init() {}

    public func append(_ other: Data) {
        lock.lock()
        defer { lock.unlock() }
        data.append(other)
    }

    public var result: Data {
        lock.lock()
        defer { lock.unlock() }
        return data as Data
    }
}
