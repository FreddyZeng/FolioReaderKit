//
//  FolioReaderPage+Gestures.swift
//  FolioReaderKit
//

import UIKit

extension FolioReaderPage {
    // MARK: Gesture recognizer

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            tapStartLocation = touch.location(in: contentView)
            tapStartPageNumber = pageNumber
            tapStartedWhileScrolling = folioReader.readerCenter?.isScrollMotionActive() ?? false
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view is FolioReaderWebView {
            if otherGestureRecognizer is UILongPressGestureRecognizer {
                if webView?.isMenuVisible ?? false {
                    webView?.setMenuVisible(false)
                }
                return false
            }
            return true
        }
        return false
    }

    @objc public func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        delegate?.pageTap?(recognizer)

        guard let readerCenter = folioReader.readerCenter else { return }
        guard isValidBarRevealTap(recognizer) else {
            readerCenter.invalidatePendingBarReveal()
            return
        }

        if readerCenter.barHostingNavigationController?.isNavigationBarHidden == true {
            let pageNumberForTap = tapStartPageNumber ?? pageNumber
            webView?.js("getSelectedText()") { selected in
                guard (selected == nil || selected?.isEmpty == true) else {
                    return
                }

                readerCenter.requestBarReveal(forPageNumber: pageNumberForTap)
            }
        } else if (self.readerConfig.shouldHideNavigationOnTap == true) {
            readerCenter.hideBars()
            self.menuIsVisible = false
        }
    }

    private func isValidBarRevealTap(_ recognizer: UITapGestureRecognizer) -> Bool {
        guard readerConfig.hideBars == false else { return false }
        guard tapStartedWhileScrolling == false else { return false }
        guard folioReader.readerCenter?.isScrollMotionActive() == false else { return false }
        guard menuIsVisible == false else { return false }

        if let tapStartPageNumber = tapStartPageNumber, tapStartPageNumber != pageNumber {
            return false
        }

        if let tapStartLocation = tapStartLocation {
            let tapEndLocation = recognizer.location(in: contentView)
            let deltaX = tapEndLocation.x - tapStartLocation.x
            let deltaY = tapEndLocation.y - tapStartLocation.y
            let distance = hypot(deltaX, deltaY)
            if distance > 8 {
                return false
            }
        }

        return true
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
