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
}
