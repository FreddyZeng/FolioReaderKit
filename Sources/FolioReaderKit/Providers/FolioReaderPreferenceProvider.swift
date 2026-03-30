//
//  FolioReaderPreferenceProvider.swift
//  FolioReaderKit
//

import Foundation

@objc public protocol FolioReaderPreferenceProvider: AnyObject {
    @objc func preference(stringFor key: String, default: String) -> String
    @objc func preference(setString value: String, for key: String)
    
    @objc func preference(intFor key: String, default: Int) -> Int
    @objc func preference(setInt value: Int, for key: String)
    
    @objc func preference(boolFor key: String, default: Bool) -> Bool
    @objc func preference(setBool value: Bool, for key: String)
    
    //MARK: - Profile
    @objc func preference(listProfile filter: String?) -> [String]
    @objc func preference(saveProfile name: String)
    @objc func preference(loadProfile name: String)
    @objc func preference(removeProfile name: String)
}

open class FolioReaderDummyPreferenceProvider: FolioReaderPreferenceProvider {
    public let folioReader: FolioReader
    private var storage = [String: Any]()
    
    public init(_ folioReader: FolioReader) {
        self.folioReader = folioReader
    }

    open func preference(stringFor key: String, default defaultValue: String) -> String {
        return storage[key] as? String ?? defaultValue
    }
    
    open func preference(setString value: String, for key: String) {
        storage[key] = value
    }
    
    open func preference(intFor key: String, default defaultValue: Int) -> Int {
        return storage[key] as? Int ?? defaultValue
    }
    
    open func preference(setInt value: Int, for key: String) {
        storage[key] = value
    }
    
    open func preference(boolFor key: String, default defaultValue: Bool) -> Bool {
        return storage[key] as? Bool ?? defaultValue
    }
    
    open func preference(setBool value: Bool, for key: String) {
        storage[key] = value
    }
    
    open func preference(listProfile filter: String?) -> [String] {
        return ["Default"]
    }
    
    open func preference(saveProfile name: String) {}
    open func preference(loadProfile name: String) {}
    open func preference(removeProfile name: String) {}
}
