//
//  Extensions.swift
//  Pods
//
//  Created by Kevin Delord on 01/04/17.
//
//

import Foundation
import UIKit

extension UICollectionView.ScrollDirection {
    static func direction(withConfiguration readerConfig: FolioReaderConfig) -> UICollectionView.ScrollDirection {
        return readerConfig.isDirection(.vertical, .horizontal, .horizontal)
    }
}

extension UICollectionView.ScrollPosition {
    static func direction(withConfiguration readerConfig: FolioReaderConfig) -> UICollectionView.ScrollPosition {
        return readerConfig.isDirection(.top, .left, .left)
    }
}

extension CGPoint {
    func forDirection(withConfiguration readerConfig: FolioReaderConfig, scrollType: ScrollType = .page) -> CGFloat {
        return readerConfig.isDirection(self.y, self.x, ((scrollType == .page) ? self.y : self.x))
    }
}

extension CGSize {
    func forDirection(withConfiguration readerConfig: FolioReaderConfig) -> CGFloat {
        return readerConfig.isDirection(height, width, height)
    }
    
    func forReverseDirection(withConfiguration readerConfig: FolioReaderConfig) -> CGFloat {
        return readerConfig.isDirection(width, height, width)
    }
}

extension CGRect {
    func forDirection(withConfiguration readerConfig: FolioReaderConfig) -> CGFloat {
        return readerConfig.isDirection(height, width, height)
    }
}

extension ScrollDirection {
    static func negative(withConfiguration readerConfig: FolioReaderConfig, scrollType: ScrollType = .page) -> ScrollDirection {
        return readerConfig.isDirection(.down, .right, .right)
    }
    
    static func positive(withConfiguration readerConfig: FolioReaderConfig, scrollType: ScrollType = .page) -> ScrollDirection {
        return readerConfig.isDirection(.up, .left, .left)
    }
}

// MARK: Helpers

@available(*, deprecated, message: "Use DispatchQueue.main.asyncAfter(delay:execute:) instead")
public func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(delay: delay, execute: closure)
}

extension DispatchQueue {
    public func asyncAfter(delay: Double, execute work: @escaping () -> Void) {
        self.asyncAfter(deadline: .now() + delay, execute: work)
    }
}

/// :nodoc:
extension Array {
    
    /**
     Return index if is safe, if not return nil
     http://stackoverflow.com/a/30593673/517707
     */
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
