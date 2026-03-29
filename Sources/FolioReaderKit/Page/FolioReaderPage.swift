//
//  FolioReaderPage.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 10/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import SafariServices
import MenuItemKit
import OSLog
import WebKit

open class FolioReaderPage: UICollectionViewCell, WKNavigationDelegate, UIGestureRecognizerDelegate, EpubJSBridgeDelegate {
    weak var delegate: FolioReaderPageDelegate?
    weak var readerContainer: FolioReaderContainer?

    lazy var jsBridge: EpubJSBridge = {
        let bridge = EpubJSBridge()
        bridge.delegate = self
        return bridge
    }()

    /// The index of the current page. Note: The index start at 1!
    open var pageNumber: Int! {
        didSet {
            self.pageChapterTocReferences = self.folioReader.readerCenter?.getChapterNames(pageNumber: self.pageNumber)
        }
    }
    open var webView: FolioReaderWebView?
    open var panDeadZoneTop: UIView?
    open var panDeadZoneBot: UIView?
    open var panDeadZoneLeft: UIView?
    open var panDeadZoneRight: UIView?
    
    var activityView: FolioReaderPageActivity!
    
    open var writingMode = "horizontal-tb"
    
    open var pageOffsetRate: CGFloat = 0 {
        didSet {
            folioLogger("SET pageOffsetRate=\(pageOffsetRate) pageNumber=\(pageNumber!) currentPage=\(currentPage) totalPages=\(totalPages ?? -1)")
        }
    }

    var totalMinutes: Int?
    var totalPages: Int?
    var currentPage: Int = -1 {
        didSet {
            guard currentPage != oldValue, currentPage >= 0 else { return }
            
            updateCurrentChapterName()
            
            guard layoutAdapting == nil else { return }       //FIXME: prevent overriding last known good position
            
            getAndRecordScrollPosition()
        }
    }
    var currentChapterName: String?
    var pageChapterTocReferences: [FRTocReference]?
    var idOffsets: [String: Int]?
    
    var colorView: UIView!
    var shouldShowBar = true
    var menuIsVisible = false
    var firstLoadReloaded = false
    
    var statusbarHeight: CGFloat {
        return self.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }
    
     var layoutAdapting: String? = nil {
        didSet {
            if let layoutAdapting = layoutAdapting {
                if pageNumber != 1 {
                    if activityView.adView == nil {
                        activityView.adView = self.folioReader.delegate?.folioReaderAdView?(self.folioReader)
                    }
                    
                    activityView.activate(layoutAdapting, activityView.adView != nil)
                    
                } else {
                    activityView.activate(layoutAdapting, false)
                }
            } else {
                activityView.deactivate()
            }
            
        }
    }
    var readerConfig: FolioReaderConfig {
        guard let readerContainer = readerContainer else { return FolioReaderConfig() }
        return readerContainer.readerConfig
    }

    var book: FRBook {
        guard let readerContainer = readerContainer else { return FRBook() }
        return readerContainer.book
    }

    var folioReader: FolioReader {
        guard let readerContainer = readerContainer else { return FolioReader() }
        return readerContainer.folioReader
    }

    // MARK: - View life cicle

    public override init(frame: CGRect) {
        // Init explicit attributes with a default value. The `setup` function MUST be called to configure the current object with valid attributes.
        // self.readerContainer = FolioReaderContainer(withConfig: FolioReaderConfig(), folioReader: FolioReader(), epubPath: "")
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear

        NotificationCenter.default.addObserver(self, selector: #selector(refreshPageMode), name: NSNotification.Name(rawValue: "needRefreshPageMode"), object: nil)
    }

    public func setup(withReaderContainer readerContainer: FolioReaderContainer) {
        self.readerContainer = readerContainer
        guard let readerContainer = self.readerContainer else { return }

        self.pageNumber = -1     //guard against webView didFinish handler
        self.currentChapterName = nil
        
        let themeBackgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.folioReader.themeMode]
        self.backgroundColor = themeBackgroundColor
        self.contentView.backgroundColor = themeBackgroundColor
        
        if webView == nil {
            webView = FolioReaderWebView(frame: webViewFrame(), readerContainer: readerContainer)
            webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView?.scrollView.showsVerticalScrollIndicator = false
            webView?.scrollView.showsHorizontalScrollIndicator = false
            webView?.scrollView.scrollsToTop = false
            webView?.backgroundColor = .clear
            webView?.configuration.userContentController.add(self.jsBridge, name: "FolioReaderPage")
            self.contentView.addSubview(webView!)
            if readerConfig.debug.contains(.borderHighlight) {
                webView?.layer.borderWidth = 10
                webView?.layer.borderColor = UIColor.magenta.cgColor
            }
        }
        webView?.backgroundColor = .clear
        webView?.isHidden = true
        webView?.navigationDelegate = self

        if panDeadZoneTop == nil {
            panDeadZoneTop = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            panDeadZoneTop?.autoresizingMask = []
            panDeadZoneTop?.backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.folioReader.themeMode]
            panDeadZoneTop?.isOpaque = false
            
            let panGeature = UIPanGestureRecognizer(target: self, action: nil)
            panGeature.delegate = self
            panDeadZoneTop?.addGestureRecognizer(panGeature)
            
            self.contentView.addSubview(panDeadZoneTop!)
        }
        
        if panDeadZoneBot == nil {
            panDeadZoneBot = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            panDeadZoneBot?.autoresizingMask = []
            panDeadZoneBot?.backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.folioReader.themeMode]
            panDeadZoneBot?.isOpaque = false
            
            let panGeature = UIPanGestureRecognizer(target: self, action: nil)
            panGeature.delegate = self
            panDeadZoneBot?.addGestureRecognizer(panGeature)
            
            self.contentView.addSubview(panDeadZoneBot!)
        }
        
        if panDeadZoneLeft == nil {
            panDeadZoneLeft = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            panDeadZoneLeft?.autoresizingMask = []
            panDeadZoneLeft?.backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.folioReader.themeMode]
            panDeadZoneLeft?.isOpaque = false
            
            let panGeature = UIPanGestureRecognizer(target: self, action: nil)
            panGeature.delegate = self
            panDeadZoneLeft?.addGestureRecognizer(panGeature)
            
            self.contentView.addSubview(panDeadZoneLeft!)
        }
        
        if panDeadZoneRight == nil {
            panDeadZoneRight = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            panDeadZoneRight?.autoresizingMask = []
            panDeadZoneRight?.backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.folioReader.themeMode]
            panDeadZoneRight?.isOpaque = false
            
            let panGeature = UIPanGestureRecognizer(target: self, action: nil)
            panGeature.delegate = self
            panDeadZoneRight?.addGestureRecognizer(panGeature)
            
            self.contentView.addSubview(panDeadZoneRight!)
        }
        
        if colorView == nil {
            colorView = UIView()
            colorView.backgroundColor = self.readerConfig.nightModeBackground
            webView?.scrollView.addSubview(colorView)
        }
        
        // Remove all gestures before adding new one
        webView?.gestureRecognizers?.forEach({ gesture in
            webView?.removeGestureRecognizer(gesture)
        })
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        webView?.addGestureRecognizer(tapGestureRecognizer)
        
        if activityView == nil {
            activityView = FolioReaderPageActivity(folioReader: readerContainer.folioReader)
            activityView.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(activityView)
            NSLayoutConstraint.activate([
                activityView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
                activityView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
                activityView.widthAnchor.constraint(equalTo: self.contentView.widthAnchor),
                activityView.heightAnchor.constraint(equalTo: self.contentView.heightAnchor)
            ])
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    deinit {
        webView?.scrollView.delegate = nil
        webView?.navigationDelegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        webView?.setupScrollDirection()
        let webViewFrame = self.webViewFrame()
        webView?.frame = webViewFrame
        
        let panDeadZoneTopFrame = CGRect(x: 0, y: 0, width: webViewFrame.width, height: webViewFrame.minY)
        panDeadZoneTop?.frame = panDeadZoneTopFrame
        
        let panDeadZoneBotFrame = CGRect(x: 0, y: webViewFrame.maxY, width: webViewFrame.width, height: frame.height - webViewFrame.maxY)
        panDeadZoneBot?.frame = panDeadZoneBotFrame
        
        let panDeadZoneLeftFrame = CGRect(x: 0, y: 0, width: webViewFrame.minX, height: webViewFrame.height)
        panDeadZoneLeft?.frame = panDeadZoneLeftFrame
        
        let panDeadZoneRightFrame = CGRect(x: webViewFrame.maxX, y: 0, width: frame.width - webViewFrame.maxX, height: webViewFrame.height)
        panDeadZoneRight?.frame = panDeadZoneRightFrame
        
        print("\(#function) frame=\(frame) webViewFrame=\(webViewFrame)  panDeadZoneLeftFrame=\(panDeadZoneLeftFrame) panDeadZoneRightFrame=\(panDeadZoneRightFrame)")
//        loadingView.center = contentView.center
    }

    func webViewFrame() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }
        
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let topComponentTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : navBarHeight
        let bottomComponentTotal = self.readerConfig.hidePageIndicator ? 0 : self.folioReader.readerCenter?.pageIndicatorHeight ?? CGFloat(0)
        let paddingTop: CGFloat = floor(CGFloat(self.folioReader.currentMarginTop) / 200 * (self.folioReader.readerCenter?.pageHeight ?? CGFloat(0)))
        let paddingBottom: CGFloat = floor(CGFloat(self.folioReader.currentMarginBottom) / 200 * (self.folioReader.readerCenter?.pageHeight ?? CGFloat(0)))
        let paddingLeft: CGFloat = floor(CGFloat(self.folioReader.currentMarginLeft) / 200 * (self.folioReader.readerCenter?.pageWidth ?? CGFloat(0)))
        let paddingRight: CGFloat = floor(CGFloat(self.folioReader.currentMarginRight) / 200 * (self.folioReader.readerCenter?.pageWidth ?? CGFloat(0)))
        
        return byWritingMode(
            CGRect(
                x: bounds.origin.x,
                y: self.readerConfig.isDirection(
                    bounds.origin.y + topComponentTotal,
                    bounds.origin.y + topComponentTotal + paddingTop,
                    bounds.origin.y + topComponentTotal),
                width: bounds.width,
                height: max(self.readerConfig.isDirection(
                    bounds.height - topComponentTotal - bottomComponentTotal,
                    bounds.height - topComponentTotal - bottomComponentTotal - paddingTop - paddingBottom,
                    bounds.height - topComponentTotal - bottomComponentTotal), 0)
            ),
            CGRect(
                x: self.readerConfig.isDirection(
                    bounds.origin.x,
                    bounds.origin.x + paddingLeft,
                    bounds.origin.x),
                y: bounds.origin.y + topComponentTotal,
                width: self.readerConfig.isDirection(
                    bounds.width,
                    bounds.width - paddingLeft - paddingRight,
                    bounds.width),
                height: bounds.height - topComponentTotal - bottomComponentTotal
            )
        )
    }
    
    func anchorBoundsFrame() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }
        
        // bounds.height does not include statusbarHeight
        let statusbarHeight = self.statusbarHeight
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let topComponentTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : navBarHeight
        let bottomComponentTotal = self.readerConfig.hidePageIndicator ? 0 : self.folioReader.readerCenter?.pageIndicatorHeight ?? CGFloat(0)
        let paddingTop: CGFloat = floor(CGFloat(self.folioReader.currentMarginTop) / 200 * (self.folioReader.readerCenter?.pageHeight ?? CGFloat(0)))
        let paddingBottom: CGFloat = floor(CGFloat(self.folioReader.currentMarginBottom) / 200 * (self.folioReader.readerCenter?.pageHeight ?? CGFloat(0)))
        let paddingLeft: CGFloat = floor(CGFloat(self.folioReader.currentMarginLeft) / 200 * (self.folioReader.readerCenter?.pageWidth ?? CGFloat(0)))
        let paddingRight: CGFloat = floor(CGFloat(self.folioReader.currentMarginRight) / 200 * (self.folioReader.readerCenter?.pageWidth ?? CGFloat(0)))
        
        return byWritingMode(
            CGRect(
                x: bounds.origin.x + paddingLeft,
                y: self.readerConfig.isDirection(
                    bounds.origin.y + topComponentTotal,
                    bounds.origin.y + topComponentTotal + paddingTop,
                    bounds.origin.y + topComponentTotal)
                + statusbarHeight,
                width: bounds.width - paddingLeft - paddingRight,
                height: max(self.readerConfig.isDirection(
                    bounds.height - topComponentTotal - bottomComponentTotal,
                    bounds.height - topComponentTotal - bottomComponentTotal - paddingTop - paddingBottom,
                    bounds.height - topComponentTotal - bottomComponentTotal), 0)
            ),
            CGRect(
                x: bounds.origin.x + paddingLeft,
                y: bounds.origin.y + topComponentTotal + paddingTop,
                width: bounds.width - paddingLeft - paddingRight,
                height: max(bounds.height - topComponentTotal - bottomComponentTotal - paddingTop - paddingBottom, 0)
            )
        )
    }
    
    func webViewFrameVanilla() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }
        
        let statusbarHeight = self.statusbarHeight
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let navTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : statusbarHeight + navBarHeight
        let paddingTop: CGFloat = 20
        let paddingBottom: CGFloat = 30
        
        return CGRect(
            x: bounds.origin.x,
            y: self.readerConfig.isDirection(bounds.origin.y + navTotal, bounds.origin.y + navTotal + paddingTop, bounds.origin.y + navTotal),
            width: bounds.width,
            height: self.readerConfig.isDirection(bounds.height - navTotal, bounds.height - navTotal - paddingTop - paddingBottom, bounds.height - navTotal)
        )
    }
    
    func webViewFramePeter() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }

        let statusbarHeight = self.statusbarHeight
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let navTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : statusbarHeight + navBarHeight
        let paddingTop: CGFloat = -40
        let paddingBottom: CGFloat = 50

        print("boundsFrame \(bounds)")
        let statusBarFrame = self.window?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
        print("statusBarFrame \(statusBarFrame)")
        print("navigationBarFrame \(String(describing: self.folioReader.readerCenter?.navigationController?.navigationBar.frame))")
        
        let x = bounds.origin.x
        var y = self.readerConfig.isDirection(bounds.origin.y + navTotal, bounds.origin.y + navTotal + paddingTop, bounds.origin.y + navTotal)
        y = navBarHeight
        let width = bounds.width
        var height = self.readerConfig.isDirection(bounds.height - navTotal, bounds.height - navTotal - paddingTop - paddingBottom, bounds.height - navTotal)
        height = bounds.height - navBarHeight - statusbarHeight
        
        var frame = CGRect(x:x, y:y, width: width, height: height)
        frame = frame.insetBy(
            dx: CGFloat((self.folioReader.currentMarginLeft + self.folioReader.currentMarginRight) / 2),
            dy: CGFloat((self.folioReader.currentMarginTop + self.folioReader.currentMarginBottom) / 2))
        frame = frame.offsetBy(
            dx: CGFloat((self.folioReader.currentMarginLeft - self.folioReader.currentMarginRight) / 2),
            dy: CGFloat((self.folioReader.currentMarginTop - self.folioReader.currentMarginBottom) / 2))
        
        print("Frame \(frame)")
        
        return frame
    }

    func loadHTMLString(_ htmlContent: String!, baseURL: URL!) {
        // Load the html into the webview
        webView?.alpha = 0
        webView?.loadHTMLString(htmlContent, baseURL: baseURL)
    }

    // MARK: UIMenu visibility

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let webView = webView else { return false }

        if UIMenuController.shared.menuItems?.count == 0 {
            webView.isColors = false
            webView.createMenu(onHighlight: false)
        }

        return super.canPerformAction(action, withSender: sender)
    }

    // MARK: ColorView fix for horizontal layout
    @objc func refreshPageMode() {
        guard webView != nil else { return }

        if (self.folioReader.nightMode == true) {
            // omit create webView and colorView
            // let script = "document.documentElement.offsetHeight"
            // let contentHeight = webView.stringByEvaluatingJavaScript(from: script)
            // let frameHeight = webView.frame.height
            // let lastPageHeight = frameHeight * CGFloat(webView.pageCount) - CGFloat(Double(contentHeight!)!)
            // colorView.frame = CGRect(x: webView.frame.width * CGFloat(webView.pageCount-1), y: webView.frame.height - lastPageHeight, width: webView.frame.width, height: lastPageHeight)
            colorView.frame = CGRect.zero
        } else {
            colorView.frame = CGRect.zero
        }
    }
}
