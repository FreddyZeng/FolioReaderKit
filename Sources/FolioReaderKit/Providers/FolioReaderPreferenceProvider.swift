//
//  FolioReaderPreferenceProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderPreferenceProvider: AnyObject {
    
    @objc func preference(nightMode defaults: Bool) -> Bool
    
    @objc func preference(setNightMode value: Bool)
    
    @objc func preference(themeMode defaults: Int) -> Int
    
    @objc func preference(setThemeMode defaults: Int)

    @objc func preference(currentFont defaults: String) -> String
    
    @objc func preference(setCurrentFont value: String)

    @objc func preference(currentFontSize defaults: String) -> String

    @objc func preference(setCurrentFontSize value: String)

    @objc func preference(currentFontWeight defaults: String) -> String

    @objc func preference(setCurrentFontWeight value: String)

    @objc func preference(currentAudioRate defaults: Int) -> Int
    
    @objc func preference(setCurrentAudioRate value: Int)
    
    @objc func preference(currentHighlightStyle defaults: Int) -> Int
    
    @objc func preference(setCurrentHighlightStyle value: Int)
    
    @objc func preference(currentMediaOverlayStyle defaults: Int) -> Int
    
    @objc func preference(setCurrentMediaOverlayStyle value: Int)
    
    @objc func preference(currentScrollDirection defaults: Int) -> Int
    
    @objc func preference(setCurrentScrollDirection value: Int)
    
    @objc func preference(currentNavigationMenuIndex defaults: Int) -> Int
    
    @objc func preference(setCurrentNavigationMenuIndex value: Int)
    
    @objc func preference(currentAnnotationMenuIndex defaults: Int) -> Int
    
    @objc func preference(setCurrentAnnotationMenuIndex value: Int)
    
    @objc func preference(currentNavigationMenuBookListSyle defaults: Int) -> Int
    
    @objc func preference(setCurrentNavigationMenuBookListStyle value: Int)
    
    @objc func preference(currentVMarginLinked defaults: Bool) -> Bool
    
    @objc func preference(setCurrentVMarginLinked value: Bool)
    
    @objc func preference(currentMarginTop defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginTop value: Int)
    
    @objc func preference(currentMarginBottom defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginBottom value: Int)
    
    @objc func preference(currentHMarginLinked defaults: Bool) -> Bool
    
    @objc func preference(setCurrentHMarginLinked value: Bool)
    
    @objc func preference(currentMarginLeft defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginLeft value: Int)
    
    @objc func preference(currentMarginRight defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginRight value: Int)
    
    @objc func preference(currentLetterSpacing defaults: Int) -> Int
    
    @objc func preference(setCurrentLetterSpacing value: Int)
    
    @objc func preference(currentLineHeight defaults: Int) -> Int
    
    @objc func preference(setCurrentLineHeight value: Int)
    
    @objc func preference(currentTextIndent defaults: Int) -> Int
    
    @objc func preference(setCurrentTextIndent value: Int)
    
    @objc func preference(doWrapPara defaults: Bool) -> Bool
    
    @objc func preference(setDoWrapPara value: Bool)
    
    @objc func preference(doClearClass defaults: Bool) -> Bool

    @objc func preference(setDoClearClass value: Bool)

    @objc func preference(styleOverride defaults: Int) -> Int
    
    @objc func preference(setStyleOverride value: Int)
    
    @objc func preference(structuralStyle defaults: Int) -> Int
    
    @objc func preference(setStructuralStyle value: Int)
    
    @objc func preference(structuralTocLevel defaults: Int) -> Int
    
    @objc func preference(setStructuralTocLevel value: Int)
    
    
    //MARK: - Profile
    @objc func preference(listProfile filter: String?) -> [String]
    
    @objc func preference(saveProfile name: String)
    
    @objc func preference(loadProfile name: String)
    
    @objc func preference(removeProfile name: String)
}

open class FolioReaderDummyPreferenceProvider: FolioReaderPreferenceProvider {
    public let folioReader: FolioReader
    
    public init(_ folioReader: FolioReader) {
        self.folioReader = folioReader
    }

    open func preference(nightMode defaults: Bool) -> Bool {
        return defaults
    }
    
    open func preference(setNightMode value: Bool) {
        
    }
    
    open func preference(themeMode defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setThemeMode defaults: Int) {
        
    }
    
    open func preference(currentFont defaults: String) -> String {
        return defaults

    }
    
    open func preference(setCurrentFont value: String) {
        
    }
    
    open func preference(currentFontSize defaults: String) -> String {
        return defaults

    }
    
    open func preference(setCurrentFontSize value: String) {
        
    }
    
    open func preference(currentFontWeight defaults: String) -> String {
        return defaults

    }
    
    open func preference(setCurrentFontWeight value: String) {
        
    }
    
    open func preference(currentAudioRate defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentAudioRate value: Int) {
        
    }
    
    open func preference(currentHighlightStyle defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentHighlightStyle value: Int) {
        
    }
    
    open func preference(currentMediaOverlayStyle defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentMediaOverlayStyle value: Int) {
        
    }
    
    open func preference(currentScrollDirection defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentScrollDirection value: Int) {
        
    }
    
    open func preference(currentNavigationMenuIndex defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentNavigationMenuIndex value: Int) {
        
    }

    open func preference(currentAnnotationMenuIndex defaults: Int) -> Int {
        return defaults
    }
    
    open func preference(setCurrentAnnotationMenuIndex value: Int) {
        
    }
    
    open func preference(currentNavigationMenuBookListSyle defaults: Int) -> Int {
        return defaults
    }
    
    open func preference(setCurrentNavigationMenuBookListStyle value: Int) {
        
    }
    
    open func preference(currentMarginTop defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(currentVMarginLinked defaults: Bool) -> Bool {
        return defaults
    }
    
    open func preference(setCurrentVMarginLinked value: Bool) {
        
    }
    
    open func preference(setCurrentMarginTop value: Int) {
        
    }
    
    open func preference(currentMarginBottom defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentMarginBottom value: Int) {
        
    }
    
    open func preference(currentMarginLeft defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentMarginLeft value: Int) {
        
    }
    
    open func preference(currentMarginRight defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentMarginRight value: Int) {
        
    }
    
    open func preference(currentHMarginLinked defaults: Bool) -> Bool {
        return defaults
    }
    
    open func preference(setCurrentHMarginLinked value: Bool) {
        
    }
    
    open func preference(currentLetterSpacing defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentLetterSpacing value: Int) {
        
    }
    
    open func preference(currentLineHeight defaults: Int) -> Int {
        return defaults

    }
    
    open func preference(setCurrentLineHeight value: Int) {
        
    }
    
    open func preference(currentTextIndent defaults: Int) -> Int {
        return defaults
    }
    
    open func preference(setCurrentTextIndent value: Int) {
        
    }
    open func preference(doWrapPara defaults: Bool) -> Bool {
        return defaults

    }
    
    open func preference(setDoWrapPara value: Bool) {
        
    }
    
    open func preference(doClearClass defaults: Bool) -> Bool {
        return defaults

    }
    
    open func preference(setDoClearClass value: Bool) {
        
    }
    
    open func preference(styleOverride defaults: Int) -> Int {
        return defaults
    }
    
    open func preference(setStyleOverride value: Int) {
        
    }
    
    open func preference(structuralStyle defaults: Int) -> Int {
        return defaults
    }
    
    open func preference(setStructuralTocLevel value: Int) {
        
    }
    
    open func preference(structuralTocLevel defaults: Int) -> Int {
        return defaults
    }
    
    open func preference(setStructuralStyle value: Int) {
        
    }
    
    open func preference(listProfile filter: String?) -> [String] {
        return ["Default"]
    }
    
    
    
    open func preference(saveProfile name: String) {
        
    }
    
    open func preference(loadProfile name: String) {
        
    }
    
    open func preference(removeProfile name: String) {
        
    }
}
