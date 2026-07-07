//
//  FRSpine.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

public struct Spine {
    public var linear: Bool
    public var resource: FRResource
    public var sizeUpTo: Int

    public init(resource: FRResource, linear: Bool = true, sizeUpto: Int = 0) {
        self.resource = resource
        self.linear = linear
        self.sizeUpTo = sizeUpto
    }
}

public class FRSpine: NSObject {
    public var pageProgressionDirection: String?
    public var spineReferences = [Spine]()
    public var size = 0

    public override init() {
        super.init()
    }

    public var isRtl: Bool {
        if let pageProgressionDirection = pageProgressionDirection , pageProgressionDirection == "rtl" {
            return true
        }
        return false
    }

    public func nextChapter(_ href: String) -> FRResource? {
        var found = false;

        for item in spineReferences {
            if(found){
                return item.resource
            }

            if(item.resource.href == href) {
                found = true
            }
        }
        return nil
    }
}
