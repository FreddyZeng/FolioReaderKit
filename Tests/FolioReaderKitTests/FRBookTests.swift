//
//  FRBookTests.swift
//  FolioReaderKitTests
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import XCTest
import FolioEPUBCore
@testable import FolioReaderKit

class FRBookTests: XCTestCase {
    
    func testFRBookMetadataAndProperties() {
        let book = FRBook()
        XCTAssertFalse(book.hasAudio)
        
        let metadata = FRMetadata()
        metadata.titles = ["My Book Title"]
        let creator = Author(name: "John Doe", role: "", fileAs: "")
        metadata.creators = [creator]
        
        book.metadata = metadata
        
        XCTAssertEqual(book.title, "My Book Title")
        XCTAssertEqual(book.authorName, "John Doe")
        XCTAssertFalse(book.hasAudio)
    }
    
    func testFindPageByResource() {
        let book = FRBook()
        let spine = FRSpine()
        let res1 = FRResource()
        res1.id = "id1"
        res1.href = "chapter1.xhtml"
        res1.spineIndices = [0]
        
        let res2 = FRResource()
        res2.id = "id2"
        res2.href = "chapter2.xhtml"
        res2.spineIndices = [1]
        
        let resources = FRResources()
        resources.add(res1)
        resources.add(res2)
        
        let spineRef1 = Spine(resource: res1)
        let spineRef2 = Spine(resource: res2)
        spine.spineReferences = [spineRef1, spineRef2]
        
        book.resources = resources
        book.spine = spine
        
        let ref1 = FRTocReference(title: "Chapter 1", resource: res1)
        let ref2 = FRTocReference(title: "Chapter 2", resource: res2)
        let refUnknown = FRTocReference(title: "Unknown", resource: nil)
        
        XCTAssertEqual(book.findPageByResource(ref1), 0)
        XCTAssertEqual(book.findPageByResource(ref2), 1)
        XCTAssertEqual(book.findPageByResource(refUnknown), 2)
    }
    
    func testMediaOverlayMetadata() {
        let book = FRBook()
        let meta1 = Meta(property: "media:duration", value: "10:30")
        let meta2 = Meta(property: "media:active-class", value: "custom-active")
        let meta3 = Meta(property: "media:playback-active-class", value: "custom-playing")
        
        book.metadata.metaAttributes = [meta1, meta2, meta3]
        
        XCTAssertEqual(book.duration, "10:30")
        XCTAssertEqual(book.activeClass, "custom-active")
        XCTAssertEqual(book.playbackActiveClass, "custom-playing")
        
        // Test defaults
        let emptyBook = FRBook()
        XCTAssertEqual(emptyBook.activeClass, "epub-media-overlay-active")
        XCTAssertEqual(emptyBook.playbackActiveClass, "epub-media-overlay-playing")
    }
    
    func testSmilFileRetrieval() {
        let book = FRBook()
        let res = FRResource()
        res.id = "resId"
        res.href = "chapter1.xhtml"
        res.mediaOverlay = "audio1"
        
        let smilRes = FRResource()
        smilRes.href = "chapter1.smil"
        smilRes.id = "audio1"
        
        let resources = FRResources()
        resources.add(res)
        resources.add(smilRes)
        
        let smils = FRSmils()
        let smilFile = FRSmilFile(resource: smilRes)
        smils.add(smilFile)
        
        book.resources = resources
        book.smils = smils
        
        XCTAssertTrue(book.hasAudio)
        
        let foundSmil = book.smilFileForResource(res)
        XCTAssertNotNil(foundSmil)
        XCTAssertEqual(foundSmil?.resource.href, "chapter1.smil")
        
        let foundByHref = book.smilFile(forHref: "chapter1.xhtml")
        XCTAssertNotNil(foundByHref)
        
        let foundById = book.smilFile(forId: "audio1")
        XCTAssertNil(foundById)
    }
}
