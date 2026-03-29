//
//  FolioReaderPage+Utils.swift
//  FolioReaderKit
//

import UIKit

public extension FolioReaderPage {
    func byWritingMode<T> (_ horizontal: T, _ vertical: T) -> T {
        if writingMode == "vertical-rl" {
            return vertical
        } else {
            return horizontal
        }
    }
    
    func byWritingMode (horizontal: () -> Void, vertical: () -> Void) {
        if writingMode == "vertical-rl" {
            vertical()
        } else {
            horizontal()
        }
    }
    
    func waitForLayoutFinish(completion: @escaping () -> Void, retry: Int = 99) {
        if layoutAdapting != nil, retry > 0 {
            delay(0.1) {
                self.waitForLayoutFinish(completion: completion, retry: retry - 1)
            }
        } else {
            completion()
        }
    }
    
    func delaySec(_ max: Double = 1.0) -> Double {
        let fileSize = self.book.spine.spineReferences[safe: pageNumber-1]?.resource.size ?? 102400
        let delaySec = min(0.2 + 0.2 * Double(fileSize / 51200), max)
        return delaySec
    }
}

struct NodeBoundingClientRect: Codable {
    let id: String
    let top: Double
    let left: Double
    let bottom: Double
    let right: Double
    let err: String
}
