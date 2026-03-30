//
//  Epub.swift
//  Example
//
//  Created by Kevin Delord on 18/05/2017.
//  Copyright © 2017 FolioReader. All rights reserved.
//

import Foundation
import FolioReaderKit

enum Epub: Int {
    case bookOne = 0
    case bookTwo

    var name: String {
        switch self {
        case .bookOne:      return "Population" // standard eBook
        case .bookTwo:      return "The Silver Chair" // audio-eBook
        }
    }

    var shouldHideNavigationOnTap: Bool {
        switch self {
        case .bookOne:      return false
        case .bookTwo:      return true
        }
    }

    var scrollDirection: FolioReaderScrollDirection {
        switch self {
        case .bookOne:      return .horitonzalWithPagedContent
        case .bookTwo:      return .horitonzalWithPagedContent
        }
    }

    var bookPath: String? {
        return Bundle.main.path(forResource: self.name, ofType: "epub")
    }

    var readerIdentifier: String {
        switch self {
        case .bookOne:      return "READER_ONE"
        case .bookTwo:      return "READER_TWO"
        }
    }
}
