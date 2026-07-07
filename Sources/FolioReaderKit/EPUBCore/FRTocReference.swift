//
//  FRTocReference.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

open class FRTocReference: NSObject {
    var children = [FRTocReference]()

    public var title: String = ""
    public var resource: FRResource?
    public var fragmentID: String?
    public var level: Int?
    public var parent: FRTocReference?
    
    convenience init(title: String, resource: FRResource?, fragmentID: String = "", level: Int = 0, parent: FRTocReference? = nil) {
        self.init(title: title, resource: resource, fragmentID: fragmentID, children: [FRTocReference](), level: level, parent: parent)
    }

    init(title: String, resource: FRResource?, fragmentID: String, children: [FRTocReference], level: Int, parent: FRTocReference?) {
        self.resource = resource
        self.title = title
        self.fragmentID = fragmentID
        self.children = children
        self.level = level
        self.parent = parent
    }
}

// MARK: Equatable

func ==(lhs: FRTocReference, rhs: FRTocReference) -> Bool {
    return lhs.title == rhs.title && lhs.fragmentID == rhs.fragmentID && lhs.level == rhs.level
}
