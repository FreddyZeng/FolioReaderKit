//
//  PreferenceProviderTests.swift
//  FolioReaderKitTests
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import XCTest
@testable import FolioReaderKit

class PreferenceProviderTests: XCTestCase {
    
    func testPreferenceProviderGetSet() {
        let provider = MockPreferenceProvider()
        
        // Test defaults
        XCTAssertEqual(provider.preference(stringFor: "nonexistent", default: "defaultVal"), "defaultVal")
        XCTAssertEqual(provider.preference(intFor: "nonexistent", default: 42), 42)
        XCTAssertEqual(provider.preference(boolFor: "nonexistent", default: true), true)
        
        // Test set and get
        provider.preference(setString: "hello", for: "myString")
        XCTAssertEqual(provider.preference(stringFor: "myString", default: ""), "hello")
        
        provider.preference(setInt: 99, for: "myInt")
        XCTAssertEqual(provider.preference(intFor: "myInt", default: 0), 99)
        
        provider.preference(setBool: false, for: "myBool")
        XCTAssertEqual(provider.preference(boolFor: "myBool", default: true), false)
    }
    
    func testPreferenceProfiles() {
        let provider = MockPreferenceProvider()
        
        // Check default profiles
        XCTAssertEqual(provider.preference(listProfile: nil), ["Default"])
        XCTAssertEqual(provider.currentProfile, "Default")
        
        // Save new profiles
        provider.preference(saveProfile: "NightMode")
        provider.preference(saveProfile: "SepiaMode")
        
        XCTAssertEqual(provider.preference(listProfile: nil), ["Default", "NightMode", "SepiaMode"])
        XCTAssertEqual(provider.currentProfile, "SepiaMode")
        
        // Load profile
        provider.preference(loadProfile: "NightMode")
        XCTAssertEqual(provider.currentProfile, "NightMode")
        
        // Filter profiles
        XCTAssertEqual(provider.preference(listProfile: "Sepia"), ["SepiaMode"])
        
        // Remove profile
        provider.preference(removeProfile: "SepiaMode")
        XCTAssertEqual(provider.preference(listProfile: nil), ["Default", "NightMode"])
        
        provider.preference(removeProfile: "NightMode")
        XCTAssertEqual(provider.currentProfile, "Default")
    }
}
