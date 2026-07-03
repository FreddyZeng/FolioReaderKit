//
//  FolioReaderKit.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
import UIKit
import ReadiumGCDWebServer

// MARK: - Internal constants

internal let kApplicationDocumentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

internal let kHighlightRange = 30
internal let kReuseCellIdentifier = "com.folioreader.Cell.ReuseIdentifier"
internal let kReusePrologueCellIdentifier = "com.folioreader.Cell.Prologue.ReuseIdentifier"
internal let kReuseHeaderFooterIdentifier = "com.folioreader.HeaderFooter.ReuseIdentifier"

public enum FolioReaderError: Error, LocalizedError {
    case bookNotAvailable
    case errorInContainer
    case errorInOpf
    case authorNameNotAvailable
    case coverNotAvailable
    case invalidImage(path: String)
    case titleNotAvailable
    case fullPathEmpty

    public var errorDescription: String? {
        switch self {
        case .bookNotAvailable:
            return "Book not found"
        case .errorInContainer, .errorInOpf:
            return "Invalid book format"
        case .authorNameNotAvailable:
            return "Author name not available"
        case .coverNotAvailable:
            return "Cover image not available"
        case let .invalidImage(path):
            return "Invalid image at path: " + path
        case .titleNotAvailable:
            return "Book title not available"
        case .fullPathEmpty:
            return "Book corrupted"
        }
    }
}

/// Defines the media overlay and TTS selection
///
/// - `default`: The background is colored
/// - underline: The underlined is colored
/// - textColor: The text is colored
public enum MediaOverlayStyle: Int {
    case `default`
    case underline
    case textColor

    init() {
        self = .default
    }

    func className() -> String {
        return "mediaOverlayStyle\(self.rawValue)"
    }
}

struct FontFamilyInfo {
    let familyName: String
    let localizedName: String?
    let regularFont: UIFont
}

public enum StyleOverrideTypes: Int, CaseIterable {
    case None           //0
    case PNode          //1
    case PlusTD         //2
    case PlusSPAN       //3
    case AllText        //4
    
    var description: String {
        get {
            switch(self) {
            case .None:
                return "none"
            case .PNode:
                return "only <p>"
            case .PlusTD:
                return "+ <td>"
            case .PlusSPAN:
                return "+ <span>"
            case .AllText:
                return "all text"
            }
        }
    }
}

public enum NavigationMenuBookListStyle: Int, CaseIterable {
    case Grid = 0
    case List = 1
}

/// FolioReader actions delegate
@objc public protocol FolioReaderDelegate: AnyObject {
    
    /// Did finished loading book.
    ///
    /// - Parameters:
    ///   - folioReader: The FolioReader instance
    ///   - book: The Book instance
    @objc optional func folioReader(_ folioReader: FolioReader, didFinishedLoading book: FRBook)
    
    /// Called when reader did closed.
    ///
    /// - Parameter folioReader: The FolioReader instance
    @objc optional func folioReaderDidClose(_ folioReader: FolioReader)
    
    /// AD
    @objc optional func folioReaderAdView(_ folioReader: FolioReader) -> UIView?
    
    @objc optional func folioReaderAdPresent(_ folioReader: FolioReader)
    
    /// Providers
    @objc optional func folioReaderHighlightProvider(_ folioReader: FolioReader) -> FolioReaderHighlightProvider
    
    @objc optional func folioReaderBookmarkProvider(_ folioReader: FolioReader) -> FolioReaderBookmarkProvider
    
    @objc optional func folioReaderPreferenceProvider(_ folioReader: FolioReader) -> FolioReaderPreferenceProvider
    
    @objc optional func folioReaderReadPositionProvider(_ folioReader: FolioReader) -> FolioReaderReadPositionProvider
}

/// Main Library class with some useful constants and methods
public class FolioReader: NSObject {

    public override init() { }

    deinit {
        removeObservers()
    }

    /// FolioReaderDelegate
    open weak var delegate: FolioReaderDelegate?
    
    var readerContainer: FolioReaderContainer?
    open weak var readerAudioPlayer: FolioReaderAudioPlayer?
    open weak var readerCenter: FolioReaderCenter? {
        return self.readerContainer?.centerViewController
    }
    open weak var readerConfig: FolioReaderConfig? {
        return self.readerContainer?.readerConfig
    }
    
    /// Check if reader is open
    var isReaderOpen = false

    /// Check if reader is open and ready
    var isReaderReady = false

    /// Check if layout needs to change to fit Right To Left
    var needsRTLChange: Bool {
        return (self.readerContainer?.book.spine.isRtl == true && (true || self.readerContainer?.readerConfig.scrollDirection == .horitonzalWithPagedContent))
    }

    open func isNight<T>(_ f: T, _ l: T) -> T {
        return (self.nightMode == true ? f : l)
    }

    // Add necessary observers
    fileprivate func addObservers() {
        removeObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(saveReaderState), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveReaderState), name: UIApplication.willTerminateNotification, object: nil)
    }

    /// Remove necessary observers
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }
}

// MARK: - Present FolioReader

extension FolioReader {

    /// Present a Folio Reader Container modally on a Parent View Controller.
    ///
    /// - Parameters:
    ///   - parentViewController: View Controller that will present the reader container.
    ///   - epubPath: String representing the path on the disk of the ePub file. Must not be nil nor empty string.
	///   - unzipPath: Path to unzip the compressed epub.
    ///   - config: FolioReader configuration.
    ///   - shouldRemoveEpub: Boolean to remove the epub or not. Default true.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    public func presentReader(parentViewController: UIViewController, withEpubPath epubPath: String, andConfig config: FolioReaderConfig, animated: Bool = true, folioReaderCenterDelegate: FolioReaderCenterDelegate?, webServer: ReadiumGCDWebServer) {
        let readerContainer = FolioReaderContainer(withConfig: config, folioReader: self, epubPath: epubPath, webServer: webServer)
        readerContainer.modalPresentationStyle = .fullScreen
        self.readerContainer = readerContainer
        
        parentViewController.present(readerContainer, animated: animated, completion: nil)
        addObservers()
    }
    
    public func prepareReader(parentViewController: UIViewController, withEpubPath epubPath: String, andConfig config: FolioReaderConfig, animated: Bool = true, folioReaderCenterDelegate: FolioReaderCenterDelegate?, webServer: ReadiumGCDWebServer) {
        let readerContainer = FolioReaderContainer(withConfig: config, folioReader: self, epubPath: epubPath, webServer: webServer)
        self.readerContainer = readerContainer
        
        addObservers()
    }
}

// MARK: -  Getters and setters for stored values

extension FolioReader {

    var preferenceProvider: FolioReaderPreferenceProvider? {
        return delegate?.folioReaderPreferenceProvider?(self)
    }
    
    func pref(boolFor key: ReaderPreferenceKey, default defaultValue: Bool) -> Bool {
        return preferenceProvider?.preference(boolFor: key.rawKey, default: defaultValue) ?? defaultValue
    }
    
    func pref(intFor key: ReaderPreferenceKey, default defaultValue: Int) -> Int {
        return preferenceProvider?.preference(intFor: key.rawKey, default: defaultValue) ?? defaultValue
    }
    
    func pref(stringFor key: ReaderPreferenceKey, default defaultValue: String) -> String {
        return preferenceProvider?.preference(stringFor: key.rawKey, default: defaultValue) ?? defaultValue
    }
    
    func pref(setBool value: Bool, for key: ReaderPreferenceKey) {
        preferenceProvider?.preference(setBool: value, for: key.rawKey)
    }
    
    func pref(setInt value: Int, for key: ReaderPreferenceKey) {
        preferenceProvider?.preference(setInt: value, for: key.rawKey)
    }
    
    func pref(setString value: String, for key: ReaderPreferenceKey) {
        preferenceProvider?.preference(setString: value, for: key.rawKey)
    }

    /// Check if current theme is Night mode
    public var nightMode: Bool {
        get {
            pref(boolFor: .nightMode, default: false)
        }
        set (value) {
            pref(setBool: value, for: .nightMode)

            if let readerCenter = self.readerCenter {
                UIView.animate(withDuration: 0.6, animations: {
                    // _ = readerCenter.currentPage?.webView?.js("nightMode(\(self.nightMode))")
                    readerCenter.pageIndicatorView?.reloadColors()
                    readerCenter.configureNavBar()
                    readerCenter.scrollScrubber?.reloadColors()
                    readerCenter.collectionView.backgroundColor = (self.nightMode == true ? self.readerContainer?.readerConfig.nightModeBackground : UIColor.white)
                }, completion: { (finished: Bool) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
                })
            }
        }
    }
    
    public var themeMode: Int {
        get {
            pref(intFor: .themeMode, default: 1)
        }
        set (value) {
            pref(setInt: value, for: .themeMode)
            
            guard let readerCenter = self.readerCenter,
                  let backgroundColor = self.readerConfig?.themeModeBackground[self.themeMode] else { return }
            
            UIView.transition(
                with: readerCenter.menuBarController.tabBar,
                duration: 0.6,
                options: .beginFromCurrentState.union(.transitionCrossDissolve),
                animations: { () -> Void in
                    readerCenter.menuBarController.tabBar.barTintColor = backgroundColor
                },
                completion: nil
            )
            
            readerCenter.menuTabs.forEach { menu in
                UIView.transition(
                    with: menu.view,
                    duration: 0.6,
                    options: .beginFromCurrentState.union(.transitionCrossDissolve),
                    animations: { () -> Void in
                        menu.reloadColors()
                    },
                    completion: nil
                )
            }
            
            UIView.animate(withDuration: 0.6, animations: {
                _ = readerCenter.currentPage?.webView?.js("themeMode(\(self.themeMode))")
                readerCenter.pageIndicatorView?.reloadColors()
                readerCenter.configureNavBar()
                readerCenter.scrollScrubber?.reloadColors()
                readerCenter.navigationItem.titleView?.subviews.forEach {
                    if let label = $0 as? UILabel {
                        label.textColor = self.readerConfig?.themeModeTextColor[self.themeMode]
                    }
                }
                
                readerCenter.collectionView.backgroundColor = backgroundColor
                
                if let page = readerCenter.currentPage {
                    page.panDeadZoneTop?.backgroundColor = backgroundColor
                    page.panDeadZoneBot?.backgroundColor = backgroundColor
                    page.panDeadZoneLeft?.backgroundColor = backgroundColor
                    page.panDeadZoneRight?.backgroundColor = backgroundColor
                }
            }, completion: { (finished: Bool) in
                NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
            })
        }
    }

    public var currentFont: String {
        get {
            pref(stringFor: .currentFont, default: "Georgia")
        }
        set (fontFamilyName) {
            pref(setString: fontFamilyName, for: .currentFont)
            readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4)
        }
    }

    static let FontSizes = ["15.5px", "17px", "18.5px", "20px", "22px", "24px", "26px", "28px", "30.5px", "33px", "35.5px"]
    public static let DefaultFontSize = FolioReader.FontSizes[3]
    
    /// Check current font size. Default .m
    public var currentFontSize: String {
        get {
            pref(stringFor: .currentFontSize, default: FolioReader.DefaultFontSize)
        }
        set (fontSize) {
            pref(setString: fontSize, for: .currentFontSize)
            readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4)
        }
    }
    
    public var currentFontSizeOnly: Int {
        return Int(Double(currentFontSize.replacingOccurrences(of: "px", with: "")) ?? 20)
    }

    public static let DefaultFontWeight = "500"
    public var currentFontWeight: String {
        get {
            pref(stringFor: .currentFontWeight, default: "500")
        }
        set (fontWeight) {
            pref(setString: fontWeight, for: .currentFontWeight)
            readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4)
        }
    }
    
    /// Check current audio rate, the speed of speech voice. Default 0
    public var currentAudioRate: Int {
        get {
            pref(intFor: .currentAudioRate, default: 1)
        }
        set (value) {
            pref(setInt: value, for: .currentAudioRate)
        }
    }

    /// Check the current highlight style.Default 0
    public var currentHighlightStyle: Int {
        get {
            pref(intFor: .currentHighlightStyle, default: FolioReaderHighlightStyle.yellow.rawValue)
        }
        set (value) {
            pref(setInt: value, for: .currentHighlightStyle)
        }
    }

    /// Check the current Media Overlay or TTS style
    public var currentMediaOverlayStyle: MediaOverlayStyle {
        get {
            let rawValue = pref(intFor: .currentMediaOverlayStyle, default: MediaOverlayStyle.default.rawValue)
            return MediaOverlayStyle(rawValue: rawValue) ?? .default
        }
        set (value) {
            pref(setInt: value.rawValue, for: .currentMediaOverlayStyle)
        }
    }

    public var defaultScrollDirection: FolioReaderScrollDirection {
        self.readerContainer?.book.spine.isRtl == true ? .horitonzalWithPagedContent : .horizontalWithScrollContent
    }
    /// Check the current scroll direction. Default .defaultVertical
    public var currentScrollDirection: Int {
        get {
            pref(intFor: .currentScrollDirection, default: defaultScrollDirection.rawValue)
        }
        set (value) {
            pref(setInt: value, for: .currentScrollDirection)

            let direction = FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? defaultScrollDirection
            readerCenter?.currentPage?.setScrollDirection(direction)
        }
    }

    public var currentNavigationMenuIndex: Int {
        get {
            pref(intFor: .currentNavigationMenuIndex, default: 0)
        }
        set (value) {
            pref(setInt: value, for: .currentNavigationMenuIndex)
        }
    }
    
    public var currentAnnotationMenuIndex: Int {
        get {
            pref(intFor: .currentAnnotationMenuIndex, default: 0)
        }
        set (value) {
            pref(setInt: value, for: .currentAnnotationMenuIndex)
        }
    }
    
    /**
     0: Grid
     1: List
     */
    public var currentNavigationMenuBookListStyle: NavigationMenuBookListStyle {
        get {
            guard self.structuralStyle == .bundle else {
                return .List
            }
            let defaults: NavigationMenuBookListStyle = self.structuralTrackingTocLevel == .level1 ? .Grid : .List
            let rawValue = pref(intFor: .currentNavigationMenuBookListStyle, default: defaults.rawValue)
            return NavigationMenuBookListStyle(rawValue: rawValue) ?? defaults
        }
        set (value) {
            pref(setInt: value.rawValue, for: .currentNavigationMenuBookListStyle)
        }
    }
    
    public var currentVMarginLinked: Bool {
        get {
            pref(boolFor: .currentVMarginLinked, default: true)
        }
        set (value) {
            pref(setBool: value, for: .currentVMarginLinked)
        }
    }
    
    public var defaultMarginTop: Int {
        (self.readerCenter?.traitCollection ?? UIScreen.main.traitCollection).verticalSizeClass == .regular ? 10 : 5    //5% for regular size, otherwise 2.5%
    }
    public var currentMarginTop: Int {
        get {
            let defaults = self.defaultMarginTop
            return pref(intFor: .currentMarginTop, default: defaults)
        }
        set (value) {
            let newValue = max(0, min(50, value))
            pref(setInt: newValue, for: .currentMarginTop)
            guard currentVMarginLinked == false else { return }
            readerCenter?.currentPage?.byWritingMode(
                horizontal: { self.readerCenter?.currentPage?.updateViewerLayout(delay: 0.2) },
                vertical: { self.readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4) }
            )
        }
    }

    public var defaultMarginBottom: Int {
        (self.readerCenter?.traitCollection ?? UIScreen.main.traitCollection).verticalSizeClass == .regular ? 10 : 5    //5% for regular size, otherwise 2.5%
    }
    public var currentMarginBottom: Int {
        get {
            let defaults = defaultMarginBottom
            return pref(intFor: .currentMarginBottom, default: defaults)
        }
        set (value) {
            let newValue = max(0, min(50, value))
            pref(setInt: newValue, for: .currentMarginBottom)
            guard currentVMarginLinked == false else { return }
            readerCenter?.currentPage?.byWritingMode(
                horizontal: { self.readerCenter?.currentPage?.updateViewerLayout(delay: 0.2) },
                vertical: { self.readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4) }
            )
        }
    }

    public var currentHMarginLinked: Bool {
        get {
            pref(boolFor: .currentHMarginLinked, default: true)
        }
        set (value) {
            pref(setBool: value, for: .currentHMarginLinked)
        }
    }
    
    public var defaultMarginLeft: Int {
        (self.readerCenter?.traitCollection ?? UIScreen.main.traitCollection).horizontalSizeClass == .regular ? 30 : 5    //15% for regular size, otherwise 2.5%
    }
    public var currentMarginLeft: Int {
        get {
            let defaults = self.defaultMarginLeft
            return pref(intFor: .currentMarginLeft, default: defaults)
        }
        set (value) {
            let newValue = max(0, min(50, value))
            pref(setInt: newValue, for: .currentMarginLeft)
            guard currentHMarginLinked == false else { return }
            readerCenter?.currentPage?.byWritingMode(
                horizontal: { self.readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4) },
                vertical: { self.readerCenter?.currentPage?.updateViewerLayout(delay: 0.2) }
            )
        }
    }

    public var defaultMarginRight: Int {
        (self.readerCenter?.traitCollection ?? UIScreen.main.traitCollection).horizontalSizeClass == .regular ? 30 : 5     //15% for regular size, otherwise 2.5%
    }
    public var currentMarginRight: Int {
        get {
            let defaults = self.defaultMarginRight
            return pref(intFor: .currentMarginRight, default: defaults)
        }
        set (value) {
            let newValue = max(0, min(50, value))
            pref(setInt: newValue, for: .currentMarginRight)
            guard currentHMarginLinked == false else { return }
            readerCenter?.currentPage?.byWritingMode(
                horizontal: { self.readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4) },
                vertical: { self.readerCenter?.currentPage?.updateViewerLayout(delay: 0.2) }
            )
        }
    }
    
    public static let DefaultLetterSpacing = 2
    public var currentLetterSpacing: Int {
        get {
            pref(intFor: .currentLetterSpacing, default: 2)
        }
        set (value) {
            pref(setInt: value, for: .currentLetterSpacing)
            readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4)
        }
    }
    
    public static let DefaultLineHeight = 3
    public var currentLineHeight: Int {
        get {
            pref(intFor: .currentLineHeight, default: 3)
        }
        set (value) {
            pref(setInt: value, for: .currentLineHeight)
            readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4)
        }
    }

    //in em
    public static let DefaultTextIndent = 2
    public var currentTextIndent: Int {
        get {
            pref(intFor: .currentTextIndent, default: 2)
        }
        set (value) {
            pref(setInt: value, for: .currentTextIndent)
            readerCenter?.currentPage?.updateRuntimStyle(delay: 0.4)
        }
    }
    
    public var doWrapPara: Bool {
        get {
            pref(boolFor: .doWrapPara, default: false)
        }
        set (value) {
            pref(setBool: value, for: .doWrapPara)
        }
    }
    
    public var doClearClass: Bool {
        get {
            pref(boolFor: .doClearClass, default: true)
        }
        set (value) {
            pref(setBool: value, for: .doClearClass)
        }
    }
    
    public var styleOverride: StyleOverrideTypes {
        get {
            let rawValue = pref(intFor: .styleOverride, default: StyleOverrideTypes.PNode.rawValue)
            return StyleOverrideTypes(rawValue: rawValue) ?? .PNode
        }
        set (value) {
            pref(setInt: value.rawValue, for: .styleOverride)
            readerCenter?.currentPage?.updateRuntimStyle(delay: 0.2)
        }
    }
    
    @available(*, deprecated, message: "use delegate")
    @objc dynamic open var savedPositionForCurrentBook: FolioReaderReadPosition? {
        get {
            guard let bookId = self.readerCenter?.book.name?.deletingPathExtension else { return nil }
            folioLogger("savedPositionForCurrentBook get")
            return delegate?.folioReaderReadPositionProvider?(self).folioReaderReadPosition(self, bookId: bookId)
        }
        set {
            guard let position = newValue,
                  let bookId = self.readerCenter?.book.name?.deletingPathExtension else { return }
            
            guard self.isReaderReady || position.takePrecedence else { return }
            
            if let debug = readerConfig?.debug, debug.contains(.functionTrace) {
                Thread.callStackSymbols.forEach {
                    folioLogger($0)
                }
                if position.bookProgress < 5.0 {
                    folioLogger(position.bookProgress.description)
                }
            }
            
            self.save(readPosition: position, for: bookId)
        }
    }
    
    public var structuralStyle: FolioReaderStructuralStyle {
        get {
            let rawValue = pref(intFor: .structuralStyle, default: FolioReaderStructuralStyle.atom.rawValue)
            return FolioReaderStructuralStyle(rawValue: rawValue) ?? .atom
        }
        set {
            pref(setInt: newValue.rawValue, for: .structuralStyle)
        }
    }
    
    public var structuralTrackingTocLevel: FolioReaderPositionTrackingStyle {
        get {
            let rawValue = pref(intFor: .structuralTrackingTocLevel, default: FolioReaderPositionTrackingStyle.linear.rawValue)
            return FolioReaderPositionTrackingStyle(rawValue: rawValue) ?? .linear
        }
        set {
            pref(setInt: newValue.rawValue, for: .structuralTrackingTocLevel)
        }
    }
}

// MARK: - Exit, save and close FolioReader

extension FolioReader {

    /// Centralizes the persistence logic of read positions safely.
    public func save(readPosition position: FolioReaderReadPosition, for bookId: String) {
        guard let provider = self.delegate?.folioReaderReadPositionProvider?(self) else { return }
        
        DispatchQueue.global().async { [weak self, provider, position] in
            guard let self = self else { return }
            let positions = provider.folioReaderReadPosition(self, allByBookId: bookId)
            for pos in positions where pos.takePrecedence {
                pos.takePrecedence = false
                provider.folioReaderReadPosition(self, bookId: bookId, set: pos, completion: nil)
            }
            provider.folioReaderReadPosition(self, bookId: bookId, set: position, completion: nil)
        }
    }

    /// Save Reader state, book, page and scroll offset.
    @objc open func saveReaderState(completion: (() -> Void)? = nil) {
        guard isReaderOpen,
              let readerCenter = self.readerCenter,
              let currentPage = readerCenter.currentPage,
              let webView = currentPage.webView,
              currentPage.layoutAdapting == nil,
              webView.isHidden == false
        else {
            //haven't finished loading, do not overwrite position
            completion?()
            return
        }

        print("saveReaderState before getVisibleCFI \(Date())")
        
        currentPage.getWebViewScrollPosition() { position in
            print("saveReaderState after getVisibleCFI \(Date())")

            print("saveReaderState position cfi=\(position.cfi)")
            
            if let bookId = self.readerCenter?.book.name?.deletingPathExtension {
                self.save(readPosition: position, for: bookId)
            }

            completion?()
        }
    }

    /// Closes and save the reader current instance.
    public func close() {
        self.saveReaderState() {
            self.isReaderOpen = false
            self.isReaderReady = false
            self.readerAudioPlayer?.stop(immediate: true)
            self.delegate?.folioReaderDidClose?(self)
        }
    }
}

// MARK: - CSS Style


extension FolioReader {
    
    
    func generateRuntimeStyle() -> String {
        let letterSpacing = Float(currentLetterSpacing * 2 * currentFontSizeOnly) / Float(100)
        let lineHeight = Decimal((currentLineHeight + 10) * 5) / 100 + 1    //1.5 ~ 2.05
        let textIndent = (letterSpacing + Float(currentFontSizeOnly)) * Float(currentTextIndent)
        let marginTopEm = Decimal(1)
        let marginBottonEm = lineHeight - 1
        
        
        var style = ""
        if styleOverride != .None {
            var tagSelector = "p"
            if styleOverride.rawValue >= StyleOverrideTypes.PlusTD.rawValue {
                tagSelector += ", td"
            }
            if styleOverride.rawValue >= StyleOverrideTypes.PlusSPAN.rawValue {
                tagSelector += ", td, span"
            }
            
        style += """
            \(tagSelector) {
                /*font-family: \(currentFont) !important;*/
                /*font-size: \(currentFontSize) !important;*/
                /*font-weight: \(currentFontWeight) !important;*/
                /*letter-spacing: \(letterSpacing)px !important;*/
                /*line-height: \(lineHeight) !important;*/
                /*text-indent: \(textIndent)px !important;*/
                /*text-align: justify !important;*/
                /*margin: \(marginTopEm)em 0 \(marginBottonEm)em 0 !important;*/
                /*-webkit-hyphens: auto !important;*/
            }
            
            span {
                /*letter-spacing: \(letterSpacing)px !important;*/
                /*line-height: \(lineHeight) !important;*/
            }
            
            """
        }
        if let pageWidth = readerCenter?.pageWidth/*, let pageHeight = readerCenter?.pageHeight*/ {
            let marginTop = 0 //CGFloat(currentMarginTop) / 200 * pageHeight
            let marginBottom = 0 //CGFloat(currentMarginBottom) / 200 * pageHeight
            let marginLeft = CGFloat(currentMarginLeft) / 200 * pageWidth
            let marginRight = CGFloat(currentMarginRight) / 200 * pageWidth
            
            style += """
            
            /*body {
                padding: \(marginTop)px \(marginRight)px \(marginBottom)px \(marginLeft)px !important;
                overflow: hidden !important;
            }
            
            @page {
                margin: \(marginTop)px \(marginRight)px \(marginBottom)px \(marginLeft)px !important;
            }*/
            
            """
        }
        
        
        return style
    }
    
    static let CssLevelTags : [StyleOverrideTypes: String] = [.PNode: "p", .PlusTD: "td", .PlusSPAN: "span", .AllText: ""]
    static func CssLevels(type: String, def: String) -> [String] {
        CssLevelTags.map {
            let separator = $1.isEmpty ? "" : " "
            return "html body.folioStyleL\($0.rawValue)\(type) \($1), body.folioStyleL\($0.rawValue)\(type)\(separator)\($1) { \(def) }"
        }.sorted()
    }
    
    static func CssImgLevels(type: String, def: String) -> [String] {
        CssLevelTags.map {
            let separator = $1.isEmpty ? "" : " "
            return "html body.folioStyleL\($0.rawValue)\(type) \($1) img.folioImg, body.folioStyleL\($0.rawValue)\(type)\(separator)\($1) img.folioImg { \(def) }"
        }.sorted()
    }
    
    func cssFontFamilies() -> String {
        UIFont.familyNames.map {
            FolioReader.CssLevels(type: "FontFamily\($0.replacingOccurrences(of: " ", with: "_"))", def: "font-family: \"\($0)\" !important;")
        }.flatMap { $0 }.joined(separator: "\n")
    }
    
    func cssUserFontFaces() -> String {
        guard let readerConfig = readerConfig else { return "" }
        
        return readerConfig.userFontDescriptors.compactMap { fontName, fontDescriptor -> String? in
//                let ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(currentFontSizeOnly), nil)
//                let ctFontSymbolicTrait = CTFontGetSymbolicTraits(ctFont)
//                let ctFontTraits = CTFontCopyTraits(ctFont)
//                let ctFontURL = unsafeBitCast(CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute), to: CFURL.self)
            guard let ctFontURL = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute),
                  CFGetTypeID(ctFontURL) == CFURLGetTypeID(),
                  let fontURL = ctFontURL as? URL else {
                      return nil
                  }
            
            guard let ctFontFamilyName = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontFamilyNameAttribute),
                  CFGetTypeID(ctFontFamilyName) == CFStringGetTypeID(),
                  let fontFamilyName = ctFontFamilyName as? String else {
                      return nil
                  }
            
            var isItalic = false
            var isBold = false
            
            var cssFontWeight = "normal"
            
            if let ctFontTraits = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontTraitsAttribute), CFGetTypeID(ctFontTraits) == CFDictionaryGetTypeID() {
                if let ctFontSymbolicTrait = CFDictionaryGetValue(
                    (ctFontTraits as! CFDictionary),
                    unsafeBitCast(kCTFontSymbolicTrait, to: UnsafeRawPointer.self))  {
                    
                    var symTraitVal = UInt32()
                    CFNumberGetValue(unsafeBitCast(ctFontSymbolicTrait, to: CFNumber.self), CFNumberType.intType, &symTraitVal)
                    
                    isItalic = symTraitVal & CTFontSymbolicTraits.traitItalic.rawValue > 0
                    isBold = symTraitVal & CTFontSymbolicTraits.traitBold.rawValue > 0
                    
                    cssFontWeight = isBold ? "bold" : "normal"
                }
//                let isItalic = ctFontSymbolicTrait.contains(.traitItalic)
//                let isBold = ctFontSymbolicTrait.contains(.traitBold)
                
                
                if let weightRef = CFDictionaryGetValue(
                    (ctFontTraits as! CFDictionary),
                    unsafeBitCast(kCTFontWeightTrait, to: UnsafeRawPointer.self)) {
                    
                    var weightValue = Float()
                    CFNumberGetValue(unsafeBitCast(weightRef, to: CFNumber.self), CFNumberType.floatType, &weightValue)
                    if weightValue < -0.49 {
                        cssFontWeight = "100"   //thin
                    } else if weightValue < -0.29 {
                        cssFontWeight = "200"   //extralight
                    } else if weightValue < -0.19 {
                        cssFontWeight = "300"   //light
                    } else if weightValue < 0.01 {
                        cssFontWeight = "400"   //normal
                    } else if weightValue < 0.21 {
                        cssFontWeight = "500"   //medium
                    } else if weightValue < 0.31 {
                        cssFontWeight = "600"   //semibold
                    } else if weightValue < 0.41 {
                        cssFontWeight = "700"   //bold
                    } else if weightValue < 0.61 {
                        cssFontWeight = "800"   //extrabold
                    } else {
                        cssFontWeight = "900"   //heavy
                    }
                }
            }
            
            return "@font-face { font-family: \"\(fontFamilyName)\"; font-style: \(isItalic ? "italic" : "normal"); font-weight: \(cssFontWeight); src: url(\"/_fonts/\(fontURL.lastPathComponent)\");} "
            
        }.joined(separator: " ")
    }
}
