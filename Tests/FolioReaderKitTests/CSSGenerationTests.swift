//
//  CSSGenerationTests.swift
//  FolioReaderKitTests
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import XCTest
@testable import FolioReaderKit

class CSSGenerationTests: XCTestCase {
    
    func testGenerateRuntimeStyle() {
        let folioReader = FolioReader()
        let delegate = MockFolioReaderDelegate()
        folioReader.delegate = delegate
        
        // Setup initial preference settings
        folioReader.styleOverride = .PNode
        delegate.preferenceProvider.preference(setString: "20px", for: "currentFontSize")
        delegate.preferenceProvider.preference(setInt: 2, for: "currentLetterSpacing")
        delegate.preferenceProvider.preference(setInt: 3, for: "currentLineHeight")
        delegate.preferenceProvider.preference(setInt: 1, for: "currentTextIndent")
        
        var css = folioReader.generateRuntimeStyle()
        XCTAssertTrue(css.contains("p {"))
        XCTAssertFalse(css.contains("p, td {"))
        XCTAssertFalse(css.contains("p, td, span {"))
        
        // Test styleOverride changes
        folioReader.styleOverride = .PlusTD
        css = folioReader.generateRuntimeStyle()
        XCTAssertTrue(css.contains("p, td {"))
        
        folioReader.styleOverride = .PlusSPAN
        css = folioReader.generateRuntimeStyle()
        XCTAssertTrue(css.contains("p, td, td, span {"))
        
        folioReader.styleOverride = .None
        css = folioReader.generateRuntimeStyle()
        XCTAssertFalse(css.contains("p {"))
        XCTAssertFalse(css.contains("p, td, td, span {"))
    }
}
