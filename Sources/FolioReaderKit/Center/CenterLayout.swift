//
//  FolioReaderCenterLayout.swift
//  Example
//
//  Created by liyi on 2021/5/27.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation
import UIKit

class FolioReaderCenterLayout : UICollectionViewFlowLayout {
    
    var contentSize = CGSize()

    var layoutAttributes = [UICollectionViewLayoutAttributes]()
    
//    open override var collectionViewContentSize: CGSize {
//        return contentSize
//    }
    
    override func prepare() {
        super.prepare()
        
        sectionInset = UIEdgeInsets.zero
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        
        guard let collectionView = self.collectionView else { return }
        
        self.itemSize = collectionView.bounds.size
        
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        
        print("PREPAREROTATE collectionViewContentSize=\(collectionViewContentSize.debugDescription) w=\(collectionViewContentSize.width) h=\(collectionViewContentSize.height) collectionView.bounds=\(collectionView.bounds) w=\(collectionView.bounds.width) h=\(collectionView.bounds.height) collectionView.frame=\(collectionView.frame) numberOfItems=\(numberOfItems)")
        
        layoutAttributes.removeAll()
        
    }
    
//    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//
//        return layoutAttributes[indexPath.row]
//    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        print("PROPOSEROTATE \(proposedContentOffset)")
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        print("PROPOSEROTATE \(proposedContentOffset)")
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        guard let collectionView = collectionView else {
            return false
        }
        
        print("SHOULDTRANSROTATE oldBounds=\(collectionView.bounds) newBounds=\(newBounds)")
        
//        let oldBounds = collectionView.bounds
//        guard oldBounds.size != newBounds.size else { return false }
//        
//        self.itemSize = newBounds.size
//        self.estimatedItemSize = newBounds.size
//        collectionView.setContentOffset(
//            CGPoint(
//                x: oldBounds.minX / oldBounds.width * newBounds.width,
//                y: oldBounds.minY / oldBounds.height * newBounds.height
//            ), animated: false)
        
        return true
    }
}
