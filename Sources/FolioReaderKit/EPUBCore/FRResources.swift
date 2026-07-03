//
//  FRResources.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 29/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

open class FRResources: NSObject {
    
    /**
     key: resource.href
     */
    var resources = [String: FRResource]()
    
    /**
     id to href
     */
    var idMap = [String: String]()

    /**
     Adds a resource to the resources.
     */
    func add(_ resource: FRResource) {
        self.resources[resource.href] = resource
        self.idMap[resource.id] = resource.href
    }

    // MARK: Find

    /**
     Gets the first resource (random order) with the give mediatype.

     Useful for looking up the table of contents as it's supposed to be the only resource with NCX mediatype.
     */
    func findByMediaType(_ mediaType: MediaType) -> FRResource? {
        return resources.values.first { $0.mediaType != nil && $0.mediaType == mediaType }
//        for resource in resources.values {
//            if resource.mediaType != nil && resource.mediaType == mediaType {
//                return resource
//            }
//        }
//        return nil
    }

    /**
     Gets the first resource (random order) with the give extension.

     Useful for looking up the table of contents as it's supposed to be the only resource with NCX extension.
     */
    func findByExtension(_ ext: String) -> FRResource? {
        return resources.values.first { $0.mediaType != nil && $0.mediaType.defaultExtension == ext }
//        for resource in resources.values {
//            if resource.mediaType != nil && resource.mediaType.defaultExtension == ext {
//                return resource
//            }
//        }
//        return nil
    }

    /**
     Gets the first resource (random order) with the give properties.

     - parameter properties: ePub 3 properties. e.g. `cover-image`, `nav`
     - returns: The Resource.
     */
    func findByProperty(_ properties: String) -> FRResource? {
        return resources.values.first { $0.properties == properties }
//        for resource in resources.values {
//            if resource.properties == properties {
//                return resource
//            }
//        }
//        return nil
    }

    /**
     Gets the resource with the given href.
     */
    func findByHref(_ href: String) -> FRResource? {
        guard !href.isEmpty else { return nil }

        // This clean is neede because may the toc.ncx is not located in the root directory
        let cleanHref = href.replacingOccurrences(of: "../", with: "")
        return resources[cleanHref]
    }

    /**
     Gets the resource with the given href.
     */
    func findById(_ id: String?) -> FRResource? {
        guard let id = id, let href = idMap[id] else { return nil }

        return resources[href]
        
//        for resource in resources.values {
//            if let resourceID = resource.id, resourceID == id {
//                return resource
//            }
//        }
//        return nil
    }

}
