//
//  BundleExtension.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import Foundation

internal extension Bundle {
    class func frameworkBundle() -> Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: FolioReader.self)
        #endif
    }
}
