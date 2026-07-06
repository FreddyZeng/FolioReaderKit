//
//  DataAccumulator.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import Foundation

/// A thread-safe data accumulator for concurrent closures.
final class DataAccumulator: @unchecked Sendable {
    private let data = NSMutableData()
    private let lock = NSLock()

    func append(_ other: Data) {
        lock.lock()
        defer { lock.unlock() }
        data.append(other)
    }

    var result: Data {
        lock.lock()
        defer { lock.unlock() }
        return data as Data
    }
}
