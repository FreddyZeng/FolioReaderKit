//
//  FRBook.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 09/04/15.
//  Extended by Kevin Jantzer on 12/30/15
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
import ReadiumZIPFoundation

open class FRBook: NSObject {
    public var metadata = FRMetadata()
    public var spine = FRSpine()
    public var smils = FRSmils()
    public var version: Double?
    
    public var opfResource: FRResource?
    public var tocResource: FRResource?
    public var uniqueIdentifier: String?
    public var coverImage: FRResource?
    public var name: String?
    public var resources = FRResources()
    public var tableOfContents = [FRTocReference]()
    public var flatTableOfContents = [FRTocReference]()
    public var resourceTocMap = [FRResource: [FRTocReference]]()

    public var epubURL: URL?
    public var archiveEntriesCache = [String: Entry]()
    
    public override init() {
        super.init()
    }
    
    public func getThreadEpubArchive() async -> Archive? {
        guard let archiveURL = self.epubURL,
              let epubArchive = try? await Archive(url: archiveURL, accessMode: .read)
        else { return nil }
        return epubArchive
    }
    
    public var hasAudio: Bool {
        return smils.smils.count > 0
    }

    public var title: String? {
        return metadata.titles.first
    }

    public var authorName: String? {
        return metadata.creators.first?.name
    }

    /**
     Find a page by FRTocReference, i.e IndexPath.row or pageNumber-1
     */
    public func findPageByResource(_ reference: FRTocReference) -> Int {
        if let resHref = reference.resource?.href,
           let index = resources.findByHref(resHref)?.spineIndices.first {
            return index
        }
            
        return spine.spineReferences.count
    }

    // MARK: - Media Overlay Metadata
    // http://www.idpf.org/epub/301/spec/epub-mediaoverlays.html#sec-package-metadata

    public var duration: String? {
        return metadata.find(byProperty: "media:duration")?.value
    }

    public var activeClass: String {
        guard let className = metadata.find(byProperty: "media:active-class")?.value else {
            return "epub-media-overlay-active"
        }
        return className
    }

    public var playbackActiveClass: String {
        guard let className = metadata.find(byProperty: "media:playback-active-class")?.value else {
            return "epub-media-overlay-playing"
        }
        return className
    }

    // MARK: - Media Overlay (SMIL) retrieval

    /**
     Get Smil File from a resource (if it has a media-overlay)
     */
    public func smilFileForResource(_ resource: FRResource?) -> FRSmilFile? {
        guard let resource = resource, let mediaOverlay = resource.mediaOverlay else { return nil }

        // lookup the smile resource to get info about the file
        guard let smilResource = resources.findById(mediaOverlay) else { return nil }

        // use the resource to get the file
        return smils.findByHref(smilResource.href)
    }

    public func smilFile(forHref href: String) -> FRSmilFile? {
        return smilFileForResource(resources.findByHref(href))
    }

    public func smilFile(forId ID: String) -> FRSmilFile? {
        return smilFileForResource(resources.findById(ID))
    }
    
    // @NOTE: should "#" be automatically prefixed with the ID?
    public func duration(for ID: String) -> String? {
        return metadata.find(byProperty: "media:duration", refinedBy: ID)?.value
    }
    
    // MARK: - for Bundle Book
    public var bundleRootTableOfContents = [FRTocReference]()
    public var bundleBookSizes = [Int]()

    public func updateBundleInfo(rootTocLevel: Int) {
        self.bundleRootTableOfContents = self.flatTableOfContents.filter {
            $0.level == rootTocLevel - 1
        }
        
        self.bundleBookSizes = (bundleRootTableOfContents.startIndex..<bundleRootTableOfContents.endIndex).map { bookTocIndex in
            let bookTocAfterIndex = bundleRootTableOfContents.index(bookTocIndex, offsetBy: 1, limitedBy: bundleRootTableOfContents.endIndex - 1) ?? bookTocIndex
            
            let bookTocSpineIndex = self.findPageByResource(bundleRootTableOfContents[bookTocIndex])
            let bookTocAfterSpineIndex = self.findPageByResource(bundleRootTableOfContents[bookTocAfterIndex])
            
            let bookTocSizeUpto = spine.spineReferences[bookTocSpineIndex].sizeUpTo
            var bookTocAfterSizeUpto = spine.spineReferences[bookTocAfterSpineIndex].sizeUpTo
            
            var bookTocParent = bundleRootTableOfContents[bookTocIndex].parent
            var bookTocAfterParent = bundleRootTableOfContents[bookTocAfterIndex].parent
            while bookTocParent != bookTocAfterParent {
                if let parent = bookTocAfterParent {
                    let parentIndex = self.findPageByResource(parent)
                    bookTocAfterSizeUpto = spine.spineReferences[parentIndex].sizeUpTo
                }
                bookTocParent = bookTocParent?.parent
                bookTocAfterParent = bookTocAfterParent?.parent
            }
            
            return bookTocAfterSpineIndex == bookTocSpineIndex ? spine.size - bookTocSizeUpto : bookTocAfterSizeUpto - bookTocSizeUpto
        }
    }
}
