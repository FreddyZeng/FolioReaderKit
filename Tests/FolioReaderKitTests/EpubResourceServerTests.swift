//
//  EpubResourceServerTests.swift
//  FolioReaderKitTests
//
//  Created by DeepMind Antigravity on 7/7/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import XCTest
import ReadiumGCDWebServer
@testable import FolioReaderKit

@MainActor
class EpubResourceServerTests: XCTestCase {
    
    func testServerLifecycle() {
        let config = FolioReaderConfig()
        let folioReader = FolioReader()
        let webServer = ReadiumGCDWebServer()
        let container = FolioReaderContainer(
            withConfig: config,
            folioReader: folioReader,
            epubPath: "",
            webServer: webServer
        )
        
        let server = EpubResourceServer(webServer: webServer, container: container)
        
        XCTAssertFalse(webServer.isRunning)
        
        server.start()
        
        XCTAssertTrue(webServer.isRunning)
        
        server.stop()
        
        XCTAssertFalse(webServer.isRunning)
    }

    func testTwoResourceServersCanRunOnSeparatePorts() {
        let firstWebServer = ReadiumGCDWebServer()
        let secondWebServer = ReadiumGCDWebServer()
        let firstContainer = FolioReaderContainer(
            withConfig: FolioReaderConfig(withIdentifier: "reader-one"),
            folioReader: FolioReader(),
            epubPath: "",
            webServer: firstWebServer
        )
        let secondContainer = FolioReaderContainer(
            withConfig: FolioReaderConfig(withIdentifier: "reader-two"),
            folioReader: FolioReader(),
            epubPath: "",
            webServer: secondWebServer
        )
        let firstServer = EpubResourceServer(webServer: firstWebServer, container: firstContainer)
        let secondServer = EpubResourceServer(webServer: secondWebServer, container: secondContainer)

        firstServer.start()
        defer { firstServer.stop() }
        secondServer.start()
        defer { secondServer.stop() }

        XCTAssertTrue(firstWebServer.isRunning)
        XCTAssertTrue(secondWebServer.isRunning)
        XCTAssertNotEqual(firstWebServer.port, secondWebServer.port)

        let firstURL = FolioReaderCenter.resourceURL(
            fileName: "BookOne.epub",
            opfHref: "OPS/package.opf",
            resourceHref: "chapter1.xhtml",
            port: firstWebServer.port
        )
        let secondURL = FolioReaderCenter.resourceURL(
            fileName: "BookTwo.epub",
            opfHref: "OPS/package.opf",
            resourceHref: "chapter1.xhtml",
            port: secondWebServer.port
        )

        XCTAssertEqual(firstURL?.port, Int(firstWebServer.port))
        XCTAssertEqual(secondURL?.port, Int(secondWebServer.port))
        XCTAssertNotEqual(firstURL?.port, secondURL?.port)
    }
}
