//
//  FolioReaderContainer.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FontBlaster
import ZIPFoundation
import GCDWebServer

/// Reader container
open class FolioReaderContainer: UIViewController {
    var shouldHideStatusBar = true
    
    // Mark those property as public so they can accessed from other classes/subclasses.
    public var epubPath: String
    public var book: FRBook
    
    public var centerNavigationController: UINavigationController!
    public var centerViewController: FolioReaderCenter!
    public var audioPlayer: FolioReaderAudioPlayer?
    
    public var readerConfig: FolioReaderConfig
    public var folioReader: FolioReader

    fileprivate var errorOnLoad = false
    
    let webServer = GCDWebServer()
    let dateFormatter = DateFormatter()
    var epubArchive: Archive?

    // MARK: - Init

    /// Init a Folio Reader Container
    ///
    /// - Parameters:
    ///   - config: Current Folio Reader configuration
    ///   - folioReader: Current instance of the FolioReader kit.
    ///   - path: The ePub path on system. Must not be nil nor empty string.
	///   - unzipPath: Path to unzip the compressed epub.
    ///   - removeEpub: Should delete the original file after unzip? Default to `true` so the ePub will be unziped only once.
    public init(withConfig config: FolioReaderConfig, folioReader: FolioReader, epubPath path: String) {
        self.readerConfig = config
        self.folioReader = folioReader
        self.epubPath = path
        self.book = FRBook()

        super.init(nibName: nil, bundle: Bundle.frameworkBundle())

        // Configure the folio reader.
        self.folioReader.readerContainer = self

        // Initialize the default reader options.
        if self.epubPath != "" {
            self.initialization()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        // When a FolioReaderContainer object is instantiated from the storyboard this function is called before.
        // At this moment, we need to initialize all non-optional objects with default values.
        // The function `setupConfig(config:epubPath:removeEpub:)` MUST be called afterward.
        // See the ExampleFolioReaderContainer.swift for more information?
        self.readerConfig = FolioReaderConfig()
        self.folioReader = FolioReader()
        self.epubPath = ""
        self.book = FRBook()

        super.init(coder: aDecoder)

        // Configure the folio reader.
        self.folioReader.readerContainer = self
    }

    /// Common Initialization
    open func initialization() {
        // Register custom fonts
        FontBlaster.blast(bundle: Bundle.frameworkBundle())
    }

    /// Set the `FolioReaderConfig` and epubPath.
    ///
    /// - Parameters:
    ///   - config: Current Folio Reader configuration
    ///   - path: The ePub path on system. Must not be nil nor empty string.
	///   - unzipPath: Path to unzip the compressed epub.
    ///   - removeEpub: Should delete the original file after unzip? Default to `true` so the ePub will be unziped only once.
    open func setupConfig(_ config: FolioReaderConfig, epubPath path: String) {
        self.readerConfig = config
        self.folioReader = FolioReader()
        self.folioReader.readerContainer = self
        self.epubPath = path
    }

    // MARK: - View life cicle

    override open func viewDidLoad() {
        super.viewDidLoad()

        //let canChangeScrollDirection = self.readerConfig.canChangeScrollDirection
        //self.readerConfig.canChangeScrollDirection = self.readerConfig.isDirection(canChangeScrollDirection, canChangeScrollDirection, false)

        // If user can change scroll direction use the last saved
        if self.readerConfig.canChangeScrollDirection == true {
            var scrollDirection = FolioReaderScrollDirection(rawValue: self.folioReader.currentScrollDirection) ?? .horizontalWithScrollContent
            if (scrollDirection == .defaultVertical && self.readerConfig.scrollDirection != .defaultVertical) {
                scrollDirection = self.readerConfig.scrollDirection
            }

            self.readerConfig.scrollDirection = scrollDirection
        }

        let hideBars = readerConfig.hideBars
        self.readerConfig.shouldHideNavigationOnTap = ((hideBars == true) ? true : self.readerConfig.shouldHideNavigationOnTap)

        let rootViewController = FolioReaderCenter(withContainer: self)
        let centerNavigationController = UINavigationController(rootViewController: rootViewController)
        
        if readerConfig.debug.contains(.borderHighlight) {
            rootViewController.view.layer.borderWidth = 6
            rootViewController.view.layer.borderColor = UIColor.green.cgColor
        }
        self.centerViewController = rootViewController

        centerNavigationController.setNavigationBarHidden(self.readerConfig.shouldHideNavigationOnTap, animated: false)
        self.view.addSubview(centerNavigationController.view)
        self.addChild(centerNavigationController)
        if readerConfig.debug.contains(.borderHighlight) {
            centerNavigationController.view.layer.borderWidth = 4
            centerNavigationController.view.layer.borderColor = UIColor.blue.cgColor
            centerNavigationController.navigationBar.layer.borderWidth = 6
            centerNavigationController.navigationBar.layer.borderColor = UIColor.yellow.cgColor
        }
        centerNavigationController.didMove(toParent: self)
        
        self.centerNavigationController = centerNavigationController

        if (self.readerConfig.hideBars == true) {
            self.readerConfig.shouldHideNavigationOnTap = false
            self.navigationController?.navigationBar.isHidden = true
            self.centerViewController?.pageIndicatorHeight = 0
        }

        // Read async book
        guard (self.epubPath.isEmpty == false) else {
            print("Epub path is nil.")
            self.errorOnLoad = true
            return
        }
        
        if readerConfig.debug.contains(.borderHighlight) {
            self.view.layer.borderWidth = 2
            self.view.layer.borderColor = UIColor.red.cgColor
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        defer {
            super.viewWillAppear(animated)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {

//                do {
//                    guard let archive = Archive(url: URL(fileURLWithPath: self.epubPath), accessMode: .read, preferredEncoding: .utf8) else { throw FolioReaderError.errorInContainer }
//                    folioLogger("BEFORE readEpub")
//                    let parsedBook = try FREpubParserArchive(book: FRBook(), archive: archive).readEpubLight(epubPath: self.epubPath)
//                    folioLogger("AFTER readEpub")
//
//                    self.book = parsedBook
//                } catch {
//                    self.errorOnLoad = true
//                }
            
            do {
                guard let archive = Archive(url: URL(fileURLWithPath: self.epubPath), accessMode: .read, preferredEncoding: .utf8) else { throw FolioReaderError.errorInContainer }
                
//                    guard let archive = self.book.epubArchive else { throw FolioReaderError.errorInContainer }
                
                folioLogger("BEFORE readEpub")
                let parsedBook = try FREpubParserArchive(book: self.book, archive: archive).readEpub(epubPath: self.epubPath)
                folioLogger("AFTER readEpub")

                self.book = parsedBook
                
                self.folioReader.isReaderOpen = true
                
                // Reload data
                DispatchQueue.main.async {
                    if let position = self.readerConfig.savedPositionForCurrentBook {
                        self.folioReader.structuralStyle = position.structuralStyle
                        self.folioReader.structuralTrackingTocLevel = position.positionTrackingStyle
                        self.folioReader.readerCenter?.currentWebViewScrollPositions[position.pageNumber - 1] = position
                        position.takePrecedence = true
                        self.folioReader.savedPositionForCurrentBook = position
                    }

                    let structuralTrackingTocLevel = self.folioReader.structuralTrackingTocLevel
                    self.book.updateBundleInfo(rootTocLevel: structuralTrackingTocLevel.rawValue)
                    
                    //FIXME: temp fix for highlights
                    self.tempFixForHighlights()
                    
                    // Add audio player if needed
                    if self.book.hasAudio || self.readerConfig.enableTTS {
                        self.addAudioPlayer()
                    }
                    
                    self.folioReader.delegate?.folioReader?(self.folioReader, didFinishedLoading: self.book)
                    
                    self.epubArchive = archive
                    self.initializeWebServer()
                    self.readerConfig.serverPort = Int(self.webServer.port)

                    self.centerViewController.reloadData()
                    self.folioReader.isReaderReady = true
                }
            } catch {
                self.errorOnLoad = true
                self.alert(message: error.localizedDescription)
            }
            
            if (self.errorOnLoad == true) {
                self.dismiss()
            }
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopWebServer()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.folioReader.isReaderOpen {
        }
        
//        if (self.errorOnLoad == true) {
//            self.dismiss()
//        }
    }

    func tempFixForHighlights() {
        guard let highlightProvider = self.folioReader.delegate?.folioReaderHighlightProvider?(self.folioReader),
           let bookId = (self.book.name as NSString?)?.deletingPathExtension
        else {
            return
        }
        
        highlightProvider.folioReaderHighlight(self.folioReader, allByBookId: bookId, andPage: nil)
            .filter {
                $0.spineName == nil || $0.spineName.isEmpty || $0.spineName == "TODO" || $0.cfiStart?.hasPrefix("/2") == false || $0.cfiEnd?.hasPrefix("/2") == false
            }.forEach { highlight in
                if highlight.spineName == "TODO", highlight.page > 1 {
                    highlight.page -= 1
                }
                if let resHref = self.book.spine.spineReferences[safe: highlight.page - 1]?.resource.href,
                   let opfUrl = URL(string: self.book.opfResource.href),
                   let resUrl = URL(string: resHref, relativeTo: opfUrl) {
                    highlight.spineName = resUrl.absoluteString.replacingOccurrences(of: "//", with: "")
                    while highlight.spineName.hasPrefix("/") {
                        highlight.spineName.removeFirst()
                    }
                    if let cfiStart = highlight.cfiStart, cfiStart.hasPrefix("/2") == false {
                        highlight.cfiStart = "/2\(cfiStart)"
                    }
                    if let cfiEnd = highlight.cfiEnd, cfiEnd.hasPrefix("/2") == false {
                        highlight.cfiEnd = "/2\(cfiEnd)"
                    }
                    highlight.date += 0.001
                }
                print("\(#function) fixHighlight \(highlight.page) \(highlight.spineName ?? "Nil") \(highlight.cfiStart ?? "Nil") \(highlight.cfiEnd ?? "Nil") \(highlight.style ?? "Nil") \(highlight.content.prefix(10))")
                highlightProvider.folioReaderHighlight(self.folioReader, added: highlight, completion: nil)
            }
    }
    
    /**
     Initialize the media player
     */
    func addAudioPlayer() {
        self.audioPlayer = FolioReaderAudioPlayer(withFolioReader: self.folioReader, book: self.book)
        self.folioReader.readerAudioPlayer = audioPlayer
    }

    // MARK: - Status Bar

    override open var prefersStatusBarHidden: Bool {
        return (self.readerConfig.shouldHideNavigationOnTap == false ? false : self.shouldHideStatusBar)
    }

    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return self.folioReader.isNight(.lightContent, .default)
    }

    // MARK: - Web Server

    open func initializeWebServer() {
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { [weak self] request in
            guard let self = self, let path = request.path.removingPercentEncoding else { return GCDWebServerErrorResponse() }

            var pathSegs = path.split(separator: "/")
            guard pathSegs.count > 1 else { return GCDWebServerErrorResponse() }
            pathSegs.removeFirst()
            let resourcePath = pathSegs.joined(separator: "/")

            guard let archiveURL = self.epubArchive?.url,
                  let archive = try? Archive(url: archiveURL, accessMode: .read),
                  let entry = archive[resourcePath] else { return GCDWebServerErrorResponse() }

            var contentType = GCDWebServerGetMimeTypeForExtension((resourcePath as NSString).pathExtension, nil) ?? "application/octet-stream"
            if contentType.contains("text/") {
                contentType += ";charset=utf-8"
            }

            var dataQueue = [Data]()
            var isError = false

            let streamResponse = GCDWebServerStreamedResponse(
                contentType: contentType,
                asyncStreamBlock: { block in
                    DispatchQueue.global(qos: .userInteractive).async {
                        while( dataQueue.isEmpty && isError == false ) {
                            Thread.sleep(forTimeInterval: 0.001)
                        }

                        DispatchQueue.main.async {
                            if isError {
                                block(nil, NSError(domain: "FolioReaderKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Uncompress Error"]))
                            } else {
                                block(dataQueue.removeFirst(), nil)
                            }
                        }
                    }
                }
            )

            if let modificationDate = entry.fileAttributes[.modificationDate] as? Date {
                streamResponse.setValue(self.dateFormatter.string(from: modificationDate), forAdditionalHeader: "Last-Modified")
                streamResponse.cacheControlMaxAge = 60
            }

            var totalCount = 0
            let entrySize = entry.uncompressedSize
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let _ = try archive.extract(entry) { data in
                        while( dataQueue.count > 4) {
                            Thread.sleep(forTimeInterval: 0.001)
                        }
                        let d = Data(data)
                        DispatchQueue.main.async {
                            dataQueue.append(d)
                            totalCount += data.count
                            if totalCount >= entrySize {
                                dataQueue.append(Data())
                            }
                        }
                    }
                } catch {
                    isError = true
                }
            }

            return streamResponse
        }

        webServer.addHandler(forMethod: "GET", pathRegex: "^/_fonts/.+?(otf|ttf)$", request: GCDWebServerRequest.self) { request in
            let fileName = (request.path as NSString).lastPathComponent

            guard let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            else { return nil }

            let fontFileURL = documentDirectory.appendingPathComponent("Fonts",  isDirectory: true).appendingPathComponent(fileName, isDirectory: false)
            guard FileManager.default.fileExists(atPath: fontFileURL.path) else { return GCDWebServerErrorResponse() }

            return GCDWebServerFileResponse(file: fontFileURL.path)
        }

        try? webServer.start(options: [
            GCDWebServerOption_BindToLocalhost: true
        ])
    }

    open func stopWebServer() {
        if webServer.isRunning {
            webServer.stop()
        }
    }
    }

extension FolioReaderContainer {
    func alert(message: String) {
        let alertController = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let action = UIAlertAction(title: "Close", style: UIAlertAction.Style.destructive) { [weak self]
            (result : UIAlertAction) -> Void in
            self?.dismiss()
        }
        alertController.addAction(action)
        
        let ignoreAction = UIAlertAction(title: "Ignore", style: .default) { action in
            alertController.dismiss()
        }
        alertController.addAction(ignoreAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
