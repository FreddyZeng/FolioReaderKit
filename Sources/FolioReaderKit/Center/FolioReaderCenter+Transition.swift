//
//  FolioReaderCenter+Transition.swift
//  FolioReaderKit
//
//  Created by Antigravity on 07/07/26.
//

import UIKit

extension FolioReaderCenter {
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if readerConfig.debug.contains(.viewTransition) {
            print("BEGINTRANSROTATE fromBounds=\(collectionView.bounds) fromContentSize=\(collectionView.contentSize) fromItemSize=\(collectionViewLayout.itemSize) to=\(size) \(String(describing: coordinator.debugDescription))")
        }
        
        guard folioReader.isReaderReady else { return }

        if readerConfig.debug.contains(.viewTransition) {
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN2TRANSROTATE \($0.debugDescription)")
            }
        }
        
        //compute new screen bounds
        if readerConfig.debug.contains(.viewTransition) {
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN2TRANSROTATE \($0.debugDescription)")
            }
        }
        
        var bounds = view.frame
        bounds.size = size
        bounds.size.height = bounds.size.height - view.safeAreaInsets.bottom
        if readerConfig.debug.contains(.viewTransition) {
            FolioLogger.log("size=\(size) newBounds=\(bounds) screenBounds=\(String(describing: screenBounds)) collectionViewFrame=\(collectionView.frame)")
        }
        
        guard let currentPage = self.currentPage else { return }
        
        let currentIndexPath = getCurrentIndexPath()
        
        if currentPage.layoutAdapting == nil {
            currentPage.layoutAdapting = "Transitioning..."
            currentPage.updatePageOffsetRate()
        }
        let pageOffsetRate = currentPage.pageOffsetRate
        
        FolioLogger.log("TRANS1 pageOffsetRate=\(currentPage.pageOffsetRate) contentSize=\(currentPage.webView?.scrollView.contentSize ?? .zero) contentOffset=\(currentPage.webView?.scrollView.contentOffset ?? .zero)")
        
        coordinator.animate { _ in
            
        } completion: { [self] _ in
            self.changePageWith(indexPath: currentIndexPath, animated: false) {
                guard let currentPage = self.currentPage else { return }
                
                self.setPageProgressiveDirection(currentPage)

                // After rotation fix internal page offset
                DispatchQueue.main.asyncAfter(delay: currentPage.delaySec()) {    //wait for webView finish resizing
                    FolioLogger.log("TRANS2 pageOffsetRate=\(currentPage.pageOffsetRate) contentSize=\(currentPage.webView?.scrollView.contentSize ?? .zero) contentOffset=\(currentPage.webView?.scrollView.contentOffset ?? .zero)")
                    
                    currentPage.webView?.js(
                    """
                        document.body.style.minHeight = null;
                        document.body.style.minWidth = null;
                    """) { _ in
                        currentPage.setNeedsLayout()
                        
                        DispatchQueue.main.asyncAfter(delay: currentPage.delaySec() + 0.5) {   //need some time for webView finishing paging
                            currentPage.updatePageInfo() {
                                currentPage.updateStyleBackgroundPadding(delay: 0.2) {
                                    currentPage.pageOffsetRate = pageOffsetRate
                                    currentPage.scrollWebViewByPageOffsetRate(animated: false)
                                    DispatchQueue.main.asyncAfter(delay: 0.2) {
                                        FolioLogger.log("TRANS3 pageOffsetRate=\(currentPage.pageOffsetRate) contentSize=\(currentPage.webView?.scrollView.contentSize ?? .zero) contentOffset=\(currentPage.webView?.scrollView.contentOffset ?? .zero)")
                                        currentPage.updatePageOffsetRate()
                                        currentPage.layoutAdapting = nil
                                        FolioLogger.log("TRANS4 pageOffsetRate=\(currentPage.pageOffsetRate) contentSize=\(currentPage.webView?.scrollView.contentSize ?? .zero) contentOffset=\(currentPage.webView?.scrollView.contentOffset ?? .zero)")
                                        currentPage.updatePageInfo()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
