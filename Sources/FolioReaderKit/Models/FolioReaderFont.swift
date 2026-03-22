//
//  FolioReaderFont.swift
//  FolioReaderKit
//
//  Created by Gemini on 2026/03/21.
//

import Foundation

@objc public enum FolioReaderFont: Int {
    case andada = 0
    case lato
    case lora
    case palatino
    case timesNewRoman
    
    public static func folioReaderFont(fontName: String) -> FolioReaderFont? {
        switch fontName {
        case "andada": return .andada
        case "lato": return .lato
        case "lora": return .lora
        case "palatino": return .palatino
        case "times": return .timesNewRoman
        default: return nil
        }
    }
}
