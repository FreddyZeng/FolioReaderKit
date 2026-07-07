//
//  FRSmil.swift
//  Pods
//
//  Created by Kevin Jantzer on 12/30/15.
//
//

import Foundation

// Media Overlay Documentation
// http://www.idpf.org/accessibility/guidelines/content/overlays/overview.php#mo005-samp


public class FRSmilElement: NSObject {
    public var name: String // the name of the tag: <seq>, <par>, <text>, <audio>
    public var attributes: [String: String]
    public var children: [FRSmilElement]

    public init(name: String, attributes: [String: String]?) {
        self.name = name
        self.attributes = attributes ?? [:]
        self.children = [FRSmilElement]()
    }

    // MARK: - Element attributes

    public func getId() -> String! {
        return getAttribute("id")
    }

    public func getSrc() -> String! {
        return getAttribute("src")
    }

    /**
     Returns array of Strings if `epub:type` attribute is set. An array is returned as there can be multiple types specified, seperated by a whitespace
     */
    public func getType() -> [String]! {
        let type = getAttribute("epub:type", defaultVal: "")
        return type!.components(separatedBy: " ")
    }

    /**
     Use to determine if this element matches a given type

     **Example**

     epub:type="bodymatter chapter"
     isType("bodymatter") -> true
     */
    public func isType(_ aType:String) -> Bool {
        return getType().contains(aType)
    }

    public func getAttribute(_ name: String, defaultVal: String!) -> String! {
        return attributes[name] != nil ? attributes[name] : defaultVal;
    }

    public func getAttribute(_ name: String ) -> String! {
        return getAttribute(name, defaultVal: nil)
    }

    // MARK: - Retrieving children elements

    // if <par> tag, a <text> is required (http://www.idpf.org/epub/301/spec/epub-mediaoverlays.html#sec-smil-par-elem)
    public func textElement() -> FRSmilElement! {
        return childWithName("text")
    }

    public func audioElement() -> FRSmilElement! {
        return childWithName("audio")
    }

    public func videoElement() -> FRSmilElement! {
        return childWithName("video")
    }

    public func childWithName(_ name:String) -> FRSmilElement! {
        for el in children {
            if( el.name == name ){
                return el
            }
        }
        return nil;
    }

    public func childrenWithNames(_ name:[String]) -> [FRSmilElement]! {
        var matched = [FRSmilElement]()
        for el in children {
            if( name.contains(el.name) ){
                matched.append(el)
            }
        }
        return matched;
    }

    public func childrenWithName(_ name:String) -> [FRSmilElement]! {
        return childrenWithNames([name])
    }

    // MARK: - Audio clip info

    public func clipBegin() -> Double {
        let val = audioElement()?.getAttribute("clipBegin", defaultVal: "")
        return val?.clockTimeToSeconds() ?? 0
    }

    public func clipEnd() -> Double {
        let val = audioElement()?.getAttribute("clipEnd", defaultVal: "")
        return val?.clockTimeToSeconds() ?? 0
    }
}
