//
//  UICollectionViewDelegation.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/13.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation
import UIKit

extension FolioReaderCenter: UICollectionViewDelegateFlowLayout {
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if readerConfig.debug.contains(.functionTrace) { FolioLogger.log("ENTER") }

        var size = CGSize(width: pageWidth, height: pageHeight)
        
        let orientation = UIDevice.current.orientation
        
        if orientation == .portrait || orientation == .portraitUpsideDown {
            if readerConfig.scrollDirection == .horizontalWithPagedContent {
                size.height = size.height - view.safeAreaInsets.bottom
            }
        }
        
        return size
    }
    
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if readerConfig.debug.contains(.functionTrace) { FolioLogger.log("ENTER") }
        if readerConfig.debug.contains(.viewTransition) {
            print("WILLDISPLAYTRANSROTATE \(indexPath)")
        }
    }
}
