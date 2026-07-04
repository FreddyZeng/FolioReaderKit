//
//  ReaderCSSGenerator.swift
//  FolioReaderKit
//
//  Created by DeepMind Antigravity on 7/4/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import UIKit

/// 封装 CSS 样式生成逻辑
class ReaderCSSGenerator {
    private weak var folioReader: FolioReader?
    
    init(folioReader: FolioReader) {
        self.folioReader = folioReader
    }
    
    func generateRuntimeStyle() -> String {
        guard let folioReader = folioReader else { return "" }
        let currentLetterSpacing = folioReader.preferences.currentLetterSpacing
        let currentFontSizeOnly = folioReader.preferences.currentFontSizeOnly
        let currentLineHeight = folioReader.preferences.currentLineHeight
        let currentTextIndent = folioReader.preferences.currentTextIndent
        let styleOverride = folioReader.preferences.styleOverride
        let currentFont = folioReader.preferences.currentFont
        let currentFontSize = folioReader.preferences.currentFontSize
        let currentFontWeight = folioReader.preferences.currentFontWeight
        let currentMarginLeft = folioReader.preferences.currentMarginLeft
        let currentMarginRight = folioReader.preferences.currentMarginRight
        
        let letterSpacing = Float(currentLetterSpacing * 2 * currentFontSizeOnly) / Float(100)
        let lineHeight = Decimal((currentLineHeight + 10) * 5) / 100 + 1    //1.5 ~ 2.05
        let textIndent = (letterSpacing + Float(currentFontSizeOnly)) * Float(currentTextIndent)
        let marginTopEm = Decimal(1)
        let marginBottonEm = lineHeight - 1
        
        var style = ""
        if styleOverride != .None {
            var tagSelector = "p"
            if styleOverride.rawValue >= StyleOverrideTypes.PlusTD.rawValue {
                tagSelector += ", td"
            }
            if styleOverride.rawValue >= StyleOverrideTypes.PlusSPAN.rawValue {
                tagSelector += ", td, span"
            }
            
            style += """
            \(tagSelector) {
                /*font-family: \(currentFont) !important;*/
                /*font-size: \(currentFontSize) !important;*/
                /*font-weight: \(currentFontWeight) !important;*/
                /*letter-spacing: \(letterSpacing)px !important;*/
                /*line-height: \(lineHeight) !important;*/
                /*text-indent: \(textIndent)px !important;*/
                /*text-align: justify !important;*/
                /*margin: \(marginTopEm)em 0 \(marginBottonEm)em 0 !important;*/
                /*-webkit-hyphens: auto !important;*/
            }
            
            span {
                /*letter-spacing: \(letterSpacing)px !important;*/
                /*line-height: \(lineHeight) !important;*/
            }
            
            """
        }
        if let pageWidth = folioReader.readerCenter?.pageWidth {
            let marginLeft = CGFloat(currentMarginLeft) / 200 * pageWidth
            let marginRight = CGFloat(currentMarginRight) / 200 * pageWidth
            
            style += """
            
            /*body {
                padding: 0px \(marginRight)px 0px \(marginLeft)px !important;
                overflow: hidden !important;
            }
            
            @page {
                margin: 0px \(marginRight)px 0px \(marginLeft)px !important;
            }*/
            
            """
        }
        
        return style
    }
    
    static let CssLevelTags : [StyleOverrideTypes: String] = [.PNode: "p", .PlusTD: "td", .PlusSPAN: "span", .AllText: ""]
    static func CssLevels(type: String, def: String) -> [String] {
        CssLevelTags.map {
            let separator = $1.isEmpty ? "" : " "
            return "html body.folioStyleL\($0.rawValue)\(type) \($1), body.folioStyleL\($0.rawValue)\(type)\(separator)\($1) { \(def) }"
        }.sorted()
    }
    
    static func CssImgLevels(type: String, def: String) -> [String] {
        CssLevelTags.map {
            let separator = $1.isEmpty ? "" : " "
            return "html body.folioStyleL\($0.rawValue)\(type) \($1) img.folioImg, body.folioStyleL\($0.rawValue)\(type)\(separator)\($1) img.folioImg { \(def) }"
        }.sorted()
    }
    
    func cssFontFamilies() -> String {
        UIFont.familyNames.map {
            ReaderCSSGenerator.CssLevels(type: "FontFamily\($0.replacingOccurrences(of: " ", with: "_"))", def: "font-family: \"\($0)\" !important;")
        }.flatMap { $0 }.joined(separator: "\n")
    }
    
    func cssUserFontFaces() -> String {
        guard let readerConfig = folioReader?.readerConfig else { return "" }
        
        return readerConfig.userFontDescriptors.compactMap { fontName, fontDescriptor -> String? in
            guard let ctFontURL = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute),
                  CFGetTypeID(ctFontURL) == CFURLGetTypeID(),
                  let fontURL = ctFontURL as? URL else {
                      return nil
                  }
            
            guard let ctFontFamilyName = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontFamilyNameAttribute),
                  CFGetTypeID(ctFontFamilyName) == CFStringGetTypeID(),
                  let fontFamilyName = ctFontFamilyName as? String else {
                      return nil
                  }
            
            var isItalic = false
            var isBold = false
            
            var cssFontWeight = "normal"
            
            if let ctFontTraits = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontTraitsAttribute), CFGetTypeID(ctFontTraits) == CFDictionaryGetTypeID() {
                if let ctFontSymbolicTrait = CFDictionaryGetValue(
                    (ctFontTraits as! CFDictionary),
                    unsafeBitCast(kCTFontSymbolicTrait, to: UnsafeRawPointer.self))  {
                    
                    var symTraitVal = UInt32()
                    CFNumberGetValue(unsafeBitCast(ctFontSymbolicTrait, to: CFNumber.self), CFNumberType.intType, &symTraitVal)
                    
                    isItalic = symTraitVal & CTFontSymbolicTraits.traitItalic.rawValue > 0
                    isBold = symTraitVal & CTFontSymbolicTraits.traitBold.rawValue > 0
                    
                    cssFontWeight = isBold ? "bold" : "normal"
                }
                
                if let weightRef = CFDictionaryGetValue(
                    (ctFontTraits as! CFDictionary),
                    unsafeBitCast(kCTFontWeightTrait, to: UnsafeRawPointer.self)) {
                    
                    var weightValue = Float()
                    CFNumberGetValue(unsafeBitCast(weightRef, to: CFNumber.self), CFNumberType.floatType, &weightValue)
                    if weightValue < -0.49 {
                        cssFontWeight = "100"   //thin
                    } else if weightValue < -0.29 {
                        cssFontWeight = "200"   //extralight
                    } else if weightValue < -0.19 {
                        cssFontWeight = "300"   //light
                    } else if weightValue < 0.01 {
                        cssFontWeight = "400"   //normal
                    } else if weightValue < 0.21 {
                        cssFontWeight = "500"   //medium
                    } else if weightValue < 0.31 {
                        cssFontWeight = "600"   //semibold
                    } else if weightValue < 0.41 {
                        cssFontWeight = "700"   //bold
                    } else if weightValue < 0.61 {
                        cssFontWeight = "800"   //extrabold
                    } else {
                        cssFontWeight = "900"   //heavy
                    }
                }
            }
            
            return "@font-face { font-family: \"\(fontFamilyName)\"; font-style: \(isItalic ? "italic" : "normal"); font-weight: \(cssFontWeight); src: url(\"/_fonts/\(fontURL.lastPathComponent)\");} "
            
        }.joined(separator: " ")
    }
}
