//
//  FRSmils.swift
//  Pods
//
//  Created by Kevin Jantzer on 12/30/15.
//
//


import Foundation

public struct FRSmilFile {
    public var resource: FRResource
    public var data = [FRSmilElement]()

    public init(resource: FRResource){
        self.resource = resource;
    }

    // MARK: - shortcuts

    public func ID() -> String {
        return self.resource.id;
    }

    public func href() -> String {
        return self.resource.href;
    }

    // MARK: - data methods

    /**
     Returns a smil <par> tag which contains info about parallel audio and text to be played
     */
    public func parallelAudioForFragment(_ fragment: String!) -> FRSmilElement! {
        return findParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findParElement(forTextSrc src:String!, inData _data:[FRSmilElement]) -> FRSmilElement! {
        for el in _data {

            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if( el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false ) ){
                return el

                // if its a <seq> (sequence) element, it should have children (<par>)
            }else if el.name == "seq" && el.children.count > 0 {
                let parEl = findParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }

    /**
     Returns a smil <par> element after the given fragment
     */
    public func nextParallelAudioForFragment(_ fragment: String) -> FRSmilElement! {
        return findNextParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findNextParElement(forTextSrc src:String!, inData _data:[FRSmilElement]) -> FRSmilElement! {
        var foundPrev = false
        for el in _data {

            if foundPrev { return el }

            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if( el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false) ){
                foundPrev = true

                // if its a <seq> (sequence) element, it should have children (<par>)
            }else if el.name == "seq" && el.children.count > 0 {
                let parEl = findNextParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }


    public func childWithName(_ name:String) -> FRSmilElement! {
        for el in data {
            if( el.name == name ){
                return el
            }
        }
        return nil;
    }

    public func childrenWithNames(_ name:[String]) -> [FRSmilElement]! {
        var matched = [FRSmilElement]()
        for el in data {
            if( name.contains(el.name) ){
                matched.append(el)
            }
        }
        return matched;
    }

    public func childrenWithName(_ name:String) -> [FRSmilElement]! {
        return childrenWithNames([name])
    }
}

/**
 Holds array of `FRSmilFile`
 */
public class FRSmils: NSObject {
    public var basePath            = ""
    public var smils               = [String: FRSmilFile]()

    public override init() {
        super.init()
    }

    /**
     Adds a smil to the smils.
     */
    public func add(_ smil: FRSmilFile) {
        self.smils[smil.resource.href] = smil
    }

    /**
     Gets the resource with the given href.
     */
    public func findByHref(_ href: String) -> FRSmilFile? {
        for smil in smils.values {
            if smil.resource.href == href {
                return smil
            }
        }
        return nil
    }

    /**
     Gets the resource with the given id.
     */
    public func findById(_ ID: String) -> FRSmilFile? {
        for smil in smils.values {
            if smil.resource.id == ID {
                return smil
            }
        }
        return nil
    }
}
