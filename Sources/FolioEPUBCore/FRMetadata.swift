//
//  FRMetadata.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 04/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

/**
 Represents one of the authors of the book.
 */
public struct Author {
    public var name: String
    public var role: String
    public var fileAs: String

    public init(name: String, role: String, fileAs: String) {
        self.name = name
        self.role = role
        self.fileAs = fileAs
    }
}

/**
 A Book's identifier.
 */
public struct Identifier {
    public var id: String?
    public var scheme: String?
    public var value: String?

    public init(id: String?, scheme: String?, value: String?) {
        self.id = id
        self.scheme = scheme
        self.value = value
    }
}

/**
 A date and his event.
 */
public struct EventDate {
    public var date: String
    public var event: String?

    public init(date: String, event: String?) {
        self.date = date
        self.event = event
    }
}

/**
 A metadata tag data.
 */
public struct Meta {
    public var name: String?
    public var content: String?
    public var id: String?
    public var property: String?
    public var value: String?
    public var refines: String?

    public init(name: String? = nil, content: String? = nil, id: String? = nil, property: String? = nil,
         value: String? = nil, refines: String? = nil) {
        self.name = name
        self.content = content
        self.id = id
        self.property = property
        self.value = value
        self.refines = refines
    }
}

/**
 Manages book metadata.
 */
public class FRMetadata {
    public var creators = [Author]()
    public var contributors = [Author]()
    public var dates = [EventDate]()
    public var language = "en-US"
    public var titles = [String]()
    public var identifiers = [Identifier]()
    public var subjects = [String]()
    public var descriptions = [String]()
    public var publishers = [String]()
    public var format = MediaType.epub.name
    public var rights = [String]()
    public var metaAttributes = [Meta]()

    public init() {}

    /**
     Find a book unique identifier by ID

     - parameter id: The ID
     - returns: The unique identifier of a book
     */
    public func find(identifierById id: String) -> Identifier? {
        return identifiers.filter({ $0.id == id }).first
    }

    public func find(byName name: String) -> Meta? {
        return metaAttributes.filter({ $0.name == name }).first
    }

    public func find(byProperty property: String, refinedBy: String? = nil) -> Meta? {
        return metaAttributes.filter {
            if let refinedBy = refinedBy {
                return $0.property == property && $0.refines == refinedBy
            }
            return $0.property == property
        }.first
    }
}
