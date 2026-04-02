//
//  FolioReaderPage+Gestures.swift
//  FolioReaderKit
//

import UIKit

extension FolioReaderPage {
    // MARK: Gesture recognizer

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let viewName = touch.view.map { "\(type(of: $0))" } ?? "nil"
        print("FolioReaderPage shouldReceive touch in \(viewName) at \(touch.location(in: self.contentView)) - Page \(self.pageNumber ?? -1)")
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("FolioReaderPage shouldRecognizeSimultaneouslyWith \(type(of: gestureRecognizer)) and \(type(of: otherGestureRecognizer))")
        if gestureRecognizer.view is FolioReaderWebView {
            if otherGestureRecognizer is UILongPressGestureRecognizer {
                if UIMenuController.shared.isMenuVisible {
                    webView?.setMenuVisible(false)
                }
                return false
            }
            return true
        }
        return false
    }

    @objc public func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        print("FolioReaderPage handleTapGesture state=\(recognizer.state.rawValue) - Page \(self.pageNumber ?? -1)")
        self.shouldShowBar = true
        self.delegate?.pageTap?(recognizer)
        
        if let _navigationController = self.folioReader.readerCenter?.navigationController, (_navigationController.isNavigationBarHidden == true) {
            webView?.js("getSelectedText()") { selected in
                guard (selected == nil || selected?.isEmpty == true) else {
                    return
                }
            
                let delay = 0.4 * Double(NSEC_PER_SEC) // 0.4 seconds * nanoseconds per seconds
                let dispatchTime = (DispatchTime.now() + (Double(Int64(delay)) / Double(NSEC_PER_SEC)))
                
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    if (self.shouldShowBar == true && self.menuIsVisible == false) {
                        self.folioReader.readerCenter?.toggleBars()
                    }
                })
            }
        } else if (self.readerConfig.shouldHideNavigationOnTap == true) {
            self.folioReader.readerCenter?.hideBars()
            self.menuIsVisible = false
        }
    }

    public func pushNavigateWebViewScrollPositions() {
        guard let readerCenter = self.folioReader.readerCenter,
              let currentPageNumber = self.pageNumber,
              let currentOffset = self.webView?.scrollView.contentOffset
        else { return }
        
        readerCenter.navigateWebViewScrollPositions.append((currentPageNumber, currentOffset))
        readerCenter.navigationItem.rightBarButtonItems?.last?.isEnabled = true
    }

    // MARK: - Deadzone Pan Gesture
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow tap gesture to begin regardless of view
        if gestureRecognizer is UITapGestureRecognizer {
            return true
        }
        
        if gestureRecognizer.view == panDeadZoneTop || gestureRecognizer.view == panDeadZoneBot || gestureRecognizer.view == panDeadZoneLeft || gestureRecognizer.view == panDeadZoneRight {
            return true
        }
        return false
    }
}
