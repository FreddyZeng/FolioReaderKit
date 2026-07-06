//
//  Logger.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import Foundation

public enum FolioLogger {
    public static func log(_ logMessage: String, functionName: String = #function, lineNumber: Int = #line) {
        print("[\(Date())] \(functionName):\(lineNumber): \(logMessage)")
    }
}

@available(*, deprecated, renamed: "FolioLogger.log")
func folioLogger(_ logMessage: String, functionName: String = #function, lineNumber: Int = #line) {
    FolioLogger.log(logMessage, functionName: functionName, lineNumber: lineNumber)
}
