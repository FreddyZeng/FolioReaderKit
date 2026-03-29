//
//  FolioReaderPage+Layout.swift
//  FolioReaderKit
//

import UIKit

extension FolioReaderPage {
    // MARK: Change layout orientation
    func setScrollDirection(_ direction: FolioReaderScrollDirection) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let readerCenter = self.folioReader.readerCenter, let webView = webView else { return }
        let currentPageNumber = readerCenter.currentPageNumber
        
        self.layoutAdapting = "Changing Document Layout..."

        // Get internal page offset before layout change
        self.updatePageOffsetRate()
        
        // Change layout
        self.readerConfig.scrollDirection = direction
        readerCenter.collectionViewLayout.scrollDirection = .direction(withConfiguration: self.readerConfig)
        self.setNeedsLayout()
        readerCenter.collectionView.collectionViewLayout.invalidateLayout()
        let frameForPage = readerCenter.frameForPage(currentPageNumber)
        readerCenter.collectionView.setContentOffset(frameForPage.origin, animated: false)

        // Page progressive direction
        readerCenter.setCollectionViewProgressiveDirection()
        delay(0.2) { readerCenter.setPageProgressiveDirection(self) }

        /**
         *  This delay is needed because the page will not be ready yet
         *  so the delay wait until layout finished the changes.
         */
        
        delay(delaySec()) {
            webView.setupScrollDirection()
            self.updateOverflowStyle(delay: self.delaySec()) {
                self.scrollWebViewByPageOffsetRate(animated: false)
                
                delay(self.delaySec() + 0.2) {
                    self.updatePageInfo() {
                        self.updateScrollPosition(delay: self.delaySec()) {
                            self.updateStyleBackgroundPadding(delay: self.delaySec()) {
                                self.layoutAdapting = nil
                            }
                        }
                    }
                }
            }
        }
    }

    func updateOverflowStyle(delay bySecond: Double, completion: (() -> Void)? = nil) {
        guard let webView = webView else { return }
        
        self.layoutAdapting = "Preparing Document Layout..."
        
        webView.js(
"""
writingMode = window.getComputedStyle(document.body).getPropertyValue("writing-mode")

{
    var viewport = document.querySelector("meta[name=viewport]");
    if (viewport) {
        if (writingMode == "vertical-rl") {
            viewport.setAttribute('content', 'height=device-height, initial-scale=1.0, maximum-scale=1.0, user-scalable=0');
        } else {
            viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0');
        }
    } else {
        var metaTag=document.createElement('meta');
        metaTag.name = "viewport"
        if (writingMode == "vertical-rl") {
            metaTag.content = "height=device-height, initial-scale=1.0, maximum-scale=1.0, user-scalable=0"
        } else {
            metaTag.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0"
        }
        document.head.appendChild(metaTag);
    }
}

{
    var overflow = "\(webView.cssOverflowProperty)"
    var head = document.head
    var style = document.getElementById("folio_style_overflow")
    if (style == null) {
        style = document.createElement('style')
        style.type = "text/css"
        style.id = "folio_style_overflow"
        head.appendChild(style)
    }
    while (style.firstChild) {
        style.removeChild(style.firstChild)
    }
    
    var cssText = "html { overflow: " + overflow + " !important; display: block !important; text-align: justify !important;}"
    if (overflow == "-webkit-paged-x") {
        if (writingMode == "vertical-rl") {
            cssText += " body { min-width: 100vw; margin: 0 0 !important; }"
        } else {
            cssText += " body { min-height: 100vh; margin: 0 0 !important; }"
        }
    }
    style.appendChild( document.createTextNode(cssText) )

    document.body.style.minHeight = null;
    document.body.style.minWidth = null;
}
/*window.webkit.messageHandlers.FolioReaderPage.postMessage("bridgeFinished " + getHTML())*/

writingMode
"""
        ) { writingMode in
            if let writingMode = writingMode {
                self.writingMode = writingMode
            }
            delay(bySecond) {
                completion?()
            }
        }
    }
    
    func updateRuntimStyle(delay bySecond: Double, completion: (() -> Void)? = nil) {
        guard let webView = webView else { return }

        self.layoutAdapting = "Preparing Document Style..."
        self.updatePageOffsetRate()
        webView.js(
"""
{
    themeMode(\(folioReader.themeMode))

    var styleOverride = \(folioReader.styleOverride.rawValue)

    removeClasses(document.body, 'folioStyle\\\\w+')
    if (writingMode == 'vertical-rl') {
        addClass(document.body, 'folioStyleBodyPaddingTop\(folioReader.currentMarginTop/5)')
        addClass(document.body, 'folioStyleBodyPaddingBottom\(folioReader.currentMarginBottom/5)')
        document.body.style.minWidth = "100vw";
    } else {
        addClass(document.body, 'folioStyleBodyPaddingLeft\(folioReader.currentMarginLeft/5)')
        addClass(document.body, 'folioStyleBodyPaddingRight\(folioReader.currentMarginRight/5)')
        document.body.style.minHeight = "100vh";
    }
    while (styleOverride > 0) {
        var folioStyleLevel = 'folioStyleL' + styleOverride
        addClass(document.body, folioStyleLevel + 'FontFamily\(folioReader.currentFont.replacingOccurrences(of: " ", with: "_"))')
        addClass(document.body, folioStyleLevel + 'FontSize\(folioReader.currentFontSize.replacingOccurrences(of: ".", with: ""))')
        addClass(document.body, folioStyleLevel + 'FontWeight\(folioReader.currentFontWeight)')
        addClass(document.body, folioStyleLevel + 'LetterSpacing\(folioReader.currentLetterSpacing)')
        addClass(document.body, folioStyleLevel + 'LineHeight\(folioReader.currentLineHeight)')
        if (writingMode == 'vertical-rl') {
            addClass(document.body, folioStyleLevel + 'MarginV\(folioReader.currentLineHeight)')
        } else {
            addClass(document.body, folioStyleLevel + 'MarginH\(folioReader.currentLineHeight)')
        }
        addClass(document.body, folioStyleLevel + 'TextIndent\(folioReader.currentTextIndent+4)')
        styleOverride -= 1
    }
}

window.webkit.messageHandlers.FolioReaderPage.postMessage("bridgeFinished " + getHTML())

window.webkit.messageHandlers.FolioReaderPage.postMessage("getComputedStyle document.documentElement " + window.getComputedStyle(document.documentElement).cssText)
window.webkit.messageHandlers.FolioReaderPage.postMessage("getComputedStyle document.body" + window.getComputedStyle(document.body).cssText)

window.webkit.messageHandlers.FolioReaderPage.postMessage("writingMode " + writingMode)

writingMode
"""
        ) { _ in
            let delaySec = self.delaySec() + bySecond
            delay(delaySec) {
                self.layoutAdapting = "Almost Ready..."
                self.updatePageInfo {
                    delay(delaySec) {
                        self.updateStyleBackgroundPadding(delay: delaySec, completion: completion != nil ? completion : {
                            self.updatePageInfo() {
                                self.scrollWebViewByPageOffsetRate()
                                delay(delaySec) {
                                    self.updatePageOffsetRate()
                                    self.layoutAdapting = nil
                                    self.updatePageInfo()
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    func updateStyleBackgroundPadding(delay bySecond: Double, tryShrinking: Bool = true, completion: (() -> Void)? = nil) {
        self.layoutAdapting = "Finalizing..."
        
        var minScreenCount = 1
        if self.byWritingMode(self.readerConfig.scrollDirection == .horitonzalWithPagedContent, true) {
            minScreenCount = self.totalPages ?? minScreenCount
            if minScreenCount < 1 {
                minScreenCount = 1
            }
        }
        
        // must set width instead of minWidth, otherwise there will be an extra blank page after calling scrollView.setContentOffset
        // could be a bug?
        // and shrinking by 100vw has no effect on totalPages
        self.webView?.js(
            """
            if (writingMode == 'vertical-rl') {
                document.body.style.width     = "\(minScreenCount * 100 - (tryShrinking ? 200 : 0))vw"
            } else {
                document.body.style.minHeight = "\(minScreenCount * 100 - (tryShrinking ? 100 : 0))vh"
            }
            """
        ) { _ in
            delay(bySecond) {
                self.updatePageInfo {
                    folioLogger("updateStyleBackgroundPadding pageNumber=\(self.pageNumber!) minScreenCount=\(minScreenCount) totalPages=\(self.totalPages ?? 0) tryShrinking=\(tryShrinking)")
                    if self.byWritingMode(self.readerConfig.scrollDirection == .horitonzalWithPagedContent, true) {
                        if tryShrinking {
                            if self.totalPages < minScreenCount {   //shrinked one page, try again
                                self.updateStyleBackgroundPadding(delay: bySecond, tryShrinking: true, completion: completion)
                            } else {  //stop shrinking
                                self.updateStyleBackgroundPadding(delay: bySecond, tryShrinking: false, completion: completion)
                            }
                        } else {
                            if self.totalPages > minScreenCount {
                                self.updateStyleBackgroundPadding(delay: bySecond, tryShrinking: true, completion: completion)
                            } else if self.totalPages < minScreenCount {
                                self.updateStyleBackgroundPadding(delay: bySecond, tryShrinking: false, completion: completion)
                            } else {
                                completion?()
                            }
                        }
                    } else {
                        completion?()
                    }
                }
            }
        }
    }
    
    func updateViewerLayout(delay bySecond: Double) {
        guard let webView = webView else { return }
        
        self.layoutAdapting = "Updating Document Layout..."
        self.updatePageOffsetRate()
        
        webView.js(
        """
            document.body.style.minHeight = null;
            document.body.style.minWidth = null;
        """) { _ in
            self.setNeedsLayout()
            
            delay(self.delaySec() + bySecond) {
                self.updatePageInfo {
                    self.updateStyleBackgroundPadding(delay: self.delaySec()) {
                        self.scrollWebViewByPageOffsetRate()
                        delay(0.2) {
                            self.updatePageOffsetRate()
                            self.layoutAdapting = nil
                            self.updatePageInfo()
                        }
                    }
                }
            }
        }
    }
}
