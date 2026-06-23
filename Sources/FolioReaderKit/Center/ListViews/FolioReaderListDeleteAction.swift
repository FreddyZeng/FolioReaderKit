//
//  FolioReaderListDeleteAction.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 01/09/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

internal enum FolioReaderListDeleteAction {
    case deleteRow(IndexPath)
    case deleteSection(Int)
}

internal func folioReaderListDeleteAction(
    isOnlyRowInSection: Bool,
    indexPath: IndexPath
) -> FolioReaderListDeleteAction {
    isOnlyRowInSection
        ? .deleteSection(indexPath.section)
        : .deleteRow(indexPath)
}

