//
//  Navigation.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation
import UIKit

extension FolioReaderCenter {
    
    func getCurrentIndexPath() -> IndexPath {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let contentOffset = self.collectionView.contentOffset
        let indexPaths = collectionView.indexPathsForVisibleItems.compactMap { indexPath -> (indexPath: IndexPath, layoutAttributes: UICollectionViewLayoutAttributes)? in
            guard let layoutAttributes = self.collectionView.layoutAttributesForItem(at: indexPath) else { return nil }
            return (indexPath: indexPath, layoutAttributes: layoutAttributes)
        }.filter {
            let layoutAttributes = $0.layoutAttributes
            
            guard layoutAttributes.frame.maxX >= contentOffset.x,
                  layoutAttributes.frame.minX <= contentOffset.x + layoutAttributes.size.width
            else { return false }
            
            guard layoutAttributes.frame.maxY >= contentOffset.y,
                  layoutAttributes.frame.minY <= contentOffset.y + layoutAttributes.size.height
            else { return false }
            
            return true
        }
        
        let indexPath = indexPaths.min {
            abs($0.layoutAttributes.frame.minX - contentOffset.x) + abs($0.layoutAttributes.frame.minY - contentOffset.y) <
                abs($1.layoutAttributes.frame.minX - contentOffset.x) + abs($1.layoutAttributes.frame.minY - contentOffset.y)
        }?.indexPath ?? IndexPath(row: 0, section: 0)

        return indexPath
    }

    func frameForPage(_ page: Int) -> CGRect {
        return paginationEngine.frameForPage(page)
    }

    public func changePageWith(page: Int, andFragment fragment: String, animated: Bool = false, completion: (() -> Void)? = nil) {
        paginationEngine.changePageWith(page: page, andFragment: fragment, animated: animated, completion: completion)
    }

    public func changePageWith(href: String, animated: Bool = false, completion: (() -> Void)? = nil) {
        paginationEngine.changePageWith(href: href, animated: animated, completion: completion)
    }

    public func changePageWith(href: String, andAudioMarkID markID: String) {
        paginationEngine.changePageWith(href: href, andAudioMarkID: markID)
    }

    public func changePageWith(indexPath: IndexPath, retryDelaySec: Double = 0.4, animated: Bool = false, completion: (() -> Void)? = nil) {
        paginationEngine.changePageWith(indexPath: indexPath, retryDelaySec: retryDelaySec, animated: animated, completion: completion)
    }
    
    public func changePageWith(href: String, pageItem: Int, animated: Bool = false, completion: (() -> Void)? = nil) {
        paginationEngine.changePageWith(href: href, pageItem: pageItem, animated: animated, completion: completion)
    }

    public func changePageToNext(_ completion: (() -> Void)? = nil) {
        paginationEngine.changePageToNext(completion)
    }

    public func changePageToPrevious(_ completion: (() -> Void)? = nil) {
        paginationEngine.changePageToPrevious(completion)
    }
    
    public func changePageItemToNext(_ completion: (() -> Void)? = nil) {
        paginationEngine.changePageItemToNext(completion)
    }

    func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        return paginationEngine.indexPathIsValid(indexPath)
    }

    public func changePageItemToPrevious(_ completion: (() -> Void)? = nil) {
        paginationEngine.changePageItemToPrevious(completion)
    }

    public func changePageItemToLast(animated: Bool = true, _ completion: (() -> Void)? = nil) {
        paginationEngine.changePageItemToLast(animated: animated, completion)
    }

    public func changePageItem(to: Int, animated: Bool = true, completion: (() -> Void)? = nil) {
        paginationEngine.changePageItem(to: to, animated: animated, completion: completion)
    }

    /**
     Find and return the chapter name, first of current page, or last of previous pages
     */
    public func getChapterName(pageNumber: Int) -> FRTocReference? {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var foundChapterName: FRTocReference?
        
        var findPageNumber = pageNumber
        
        while( findPageNumber > 0 ) {
            if let reference = self.book.spine.spineReferences[safe: findPageNumber - 1],
               let tocReferences = self.book.resourceTocMap[reference.resource],
               tocReferences.isEmpty == false {
                if findPageNumber == pageNumber {
                    foundChapterName = tocReferences.first
                } else {
                    foundChapterName = tocReferences.last
                }
                break
            } else {
                findPageNumber -= 1
            }
        }
        
        return foundChapterName
    }

    /**
     Find and return the chapter name, limit to current page only
     */
    public func getChapterNames(pageNumber: Int) -> [FRTocReference] {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var foundChapterNames = [FRTocReference]()
        
        if let reference = self.book.spine.spineReferences[safe: pageNumber - 1],
           let tocReferences = self.book.resourceTocMap[reference.resource],
           tocReferences.isEmpty == false {
            foundChapterNames.append(contentsOf: tocReferences)
        }
        
        return foundChapterNames
    }

    // MARK: Public page methods

    /**
     Changes the current page of the reader.

     - parameter page: The target page index. Note: The page index starts at 1 (and not 0).
     - parameter animated: En-/Disables the animation of the page change.
     - parameter completion: A Closure which is called if the page change is completed.
     */
    public func changePageWith(page: Int, animated: Bool = false, completion: (() -> Void)? = nil) {
        paginationEngine.changePageWith(page: page, animated: animated, completion: completion)
    }

    // MARK: - Audio Playing

    func audioMark(href: String, fragmentID: String) {
        paginationEngine.changePageWith(href: href, andAudioMarkID: fragmentID)
    }

}
