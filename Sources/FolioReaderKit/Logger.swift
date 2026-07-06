//
//  Logger.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import Foundation

func folioLogger(_ logMessage: String, functionName: String = #function, lineNumber: Int = #line) {
    print("[\(Date())] \(functionName):\(lineNumber): \(logMessage)")
}
