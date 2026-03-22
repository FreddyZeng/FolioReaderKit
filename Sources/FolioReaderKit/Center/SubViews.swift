//
//  SubViews.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation
import UIKit

extension FolioReaderCenter {
    
    func updateSubviewFrames() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var collectionViewFrame = self.frameForCollectionView(outerBounds: screenBounds)
        collectionViewFrame = collectionViewFrame.insetBy(dx: tempCollectionViewInset, dy: tempCollectionViewInset)
        pageWidth = collectionViewFrame.width
        pageHeight = collectionViewFrame.height
//        let itemSize = CGSize(
//            width: collectionViewFrame.size.width,
//            height: collectionViewFrame.size.height)
//        self.collectionViewLayout.itemSize = itemSize
        self.collectionView.frame = collectionViewFrame

        self.pageIndicatorView?.frame = self.frameForPageIndicatorView(outerBounds: screenBounds)
        self.scrollScrubber?.frame = self.frameForScrollScrubber(outerBounds: screenBounds)
        
        self.collectionView.setContentOffset(
            self.readerConfig.isDirection(
                CGPoint(x: 0, y: CGFloat(self.currentPageNumber-1) * pageHeight),
                CGPoint(x: CGFloat(self.currentPageNumber-1) * pageWidth, y: 0),
                CGPoint(x: CGFloat(self.currentPageNumber-1) * pageWidth, y: 0))
            ,
            animated: false
        )
        self.collectionViewLayout.invalidateLayout()
    }

    func frameForPageIndicatorView(outerBounds: CGRect) -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        #if DEBUG
        pageIndicatorHeight = 40
        #endif
        var bounds = CGRect(x: 0, y: outerBounds.size.height-pageIndicatorHeight, width: outerBounds.size.width, height: pageIndicatorHeight)
        
        if #available(iOS 11.0, *) {
            bounds.size.height = bounds.size.height + view.safeAreaInsets.bottom
        }
        
        return bounds
    }

    func frameForScrollScrubber(outerBounds: CGRect) -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let currentPage = currentPage else { return .zero }
        
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let topComponentTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : navBarHeight
        let bottomComponentTotal = self.readerConfig.hidePageIndicator ? 0 : self.folioReader.readerCenter?.pageIndicatorHeight ?? CGFloat(0)
        
        let scrubberYforHorizontal: CGFloat = ((self.readerConfig.shouldHideNavigationOnTap == true || self.readerConfig.hideBars == true) ? 50 : 74)
        let scrubberYforVertical: CGFloat = self.pageHeight// + ((self.readerConfig.shouldHideNavigationOnTap == true || self.readerConfig.hideBars == true) ? 50 : 74)
        
        return currentPage.byWritingMode(
            CGRect(x: self.pageWidth + 10, y: scrubberYforHorizontal, width: 40, height: (self.pageHeight - 70 - topComponentTotal - bottomComponentTotal)),
            CGRect(x: self.pageWidth - 40, y: scrubberYforVertical, width: self.pageWidth - 100, height: 40)
        )
    }

    func frameForCollectionView(outerBounds: CGRect) -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var bounds = CGRect(x: 0, y: 0, width: outerBounds.size.width, height: outerBounds.size.height)
        
        if #available(iOS 11.0, *) {
            bounds.size.height = bounds.size.height + view.safeAreaInsets.bottom
        }
        return bounds
    }
    
    func getScreenBounds() -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var bounds = view.frame
        
        if #available(iOS 11.0, *) {
            if readerConfig.debug.contains(.viewTransition) {
                print("getScreenBounds view.frame=\(bounds) view.safeAreaInsets=\(view.safeAreaInsets)")
            }
            bounds.size.height = bounds.size.height - view.safeAreaInsets.bottom
        }
        
        if readerConfig.debug.contains(.borderHighlight) {
            print("getScreenBounds \(bounds) \(UIApplication.shared.statusBarOrientation.rawValue)")
        }
        
        return bounds
    }
    
    func configureNavBar() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        //let navBackground = folioReader.isNight(self.readerConfig.nightModeNavBackground, self.readerConfig.daysModeNavBackground)
        let navBackground = self.readerConfig.themeModeNavBackground[folioReader.themeMode]
        let tintColor = readerConfig.tintColor
        let navText = folioReader.isNight(UIColor.white, UIColor.black)
        let font = UIFont(name: "Avenir-Light", size: 17)!
        setTranslucentNavigation(color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
    }

    func configureNavBarButtons() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }


        // Navbar buttons
        let shareIcon = UIImage(readerImageNamed: "icon-navbar-share")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let audioIcon = UIImage(readerImageNamed: "icon-navbar-tts")?.ignoreSystemTint(withConfiguration: self.readerConfig) //man-speech-icon
        let closeIcon = UIImage(readerImageNamed: "icon-navbar-close")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let tocIcon = UIImage(readerImageNamed: "icon-navbar-toc")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let fontIcon = UIImage(readerImageNamed: "icon-navbar-font")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let logoIcon = UIImage(readerImageNamed: "icon-button-back")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let bookmarkIcon = UIImage(readerImageNamed: "icon-navbar-bookmark")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let space = 70 as CGFloat

        let menu = UIBarButtonItem(image: closeIcon, style: .plain, target: self, action:#selector(closeReader(_:)))
        let toc = UIBarButtonItem(image: tocIcon, style: .plain, target: self, action:#selector(presentChapterList(_:)))
        let bookmark = UIBarButtonItem(image: bookmarkIcon, style: .plain, target: self, action: #selector(presentBookmarkList(_:)))
        
        navigationItem.leftBarButtonItems = [menu, toc, bookmark]

        var rightBarIcons = [UIBarButtonItem]()

        if (self.readerConfig.allowSharing == true) {
            rightBarIcons.append(UIBarButtonItem(image: shareIcon, style: .plain, target: self, action:#selector(shareChapter(_:))))
        }

        if self.book.hasAudio || self.readerConfig.enableTTS {
            rightBarIcons.append(UIBarButtonItem(image: audioIcon, style: .plain, target: self, action:#selector(presentPlayerMenu(_:))))
        }

        let font = UIBarButtonItem(image: fontIcon, style: .plain, target: self, action: #selector(presentFontsMenu))
        let lrp = UIBarButtonItem(image: logoIcon, style: .plain, target: self, action: #selector(logoButtonAction(_:)))
        lrp.isEnabled = false

        rightBarIcons.append(contentsOf: [font, lrp])
        navigationItem.rightBarButtonItems = rightBarIcons
        
        if (self.readerConfig.displayTitle) {
            navigationItem.title = book.title
        }
        
    }

    // MARK: Change page progressive direction

    private func transformViewForRTL(_ view: UIView?) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if folioReader.needsRTLChange {
            view?.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            view?.transform = CGAffineTransform.identity
        }
    }

    func setCollectionViewProgressiveDirection() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.transformViewForRTL(self.collectionView)
    }

    func setPageProgressiveDirection(_ page: FolioReaderPage) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.transformViewForRTL(page)
    }
    // MARK: Status bar and Navigation bar

    func hideBars() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard self.readerConfig.shouldHideNavigationOnTap == true else {
            return
        }

        self.updateBarsStatus(true)
    }

    func showBars() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.configureNavBar()
        self.updateBarsStatus(false)
    }

    func toggleBars() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard self.readerConfig.shouldHideNavigationOnTap == true else {
            return
        }

        let shouldHide = !self.navigationController!.isNavigationBarHidden
        if shouldHide == false {
            self.configureNavBar()
        }

        self.updateBarsStatus(shouldHide)
    }

    private func updateBarsStatus(_ shouldHide: Bool, shouldShowIndicator: Bool = false) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let readerContainer = readerContainer else { return }
        readerContainer.shouldHideStatusBar = shouldHide

        UIView.animate(withDuration: 0.25, animations: {
            readerContainer.setNeedsStatusBarAppearanceUpdate()

            // Show minutes indicator
            if (shouldShowIndicator == true) {
                self.pageIndicatorView?.minutesLabel.alpha = shouldHide ? 0 : 1
            }
        })
        self.navigationController?.setNavigationBarHidden(shouldHide, animated: true)
    }

}
