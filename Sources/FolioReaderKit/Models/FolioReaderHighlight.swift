//
//  Highlight.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 11/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

/// A Highlight object
@objc open class FolioReaderHighlight: NSObject, Codable {
    open var bookId: String!
    open var content: String!
    open var contentPost: String!
    open var contentPre: String!
    
    open var date: Date!
    open var highlightId: String!
    open var page: Int = 0
    open var type: Int = 0
    open var style: String!
    open var startOffset: Int = -1
    open var endOffset: Int = -1
    open var noteForHighlight: String?
    open var cfiStart: String?
    open var cfiEnd: String?
    
    open var contentEncoded: String!
    open var contentPreEncoded: String!
    open var contentPostEncoded: String!
    
    open var spineName: String!
    
    open var tocFamilyTitles = [String]()
    
    open func encodeContents() {
        contentEncoded = content.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        contentPreEncoded = contentPre.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        contentPostEncoded = contentPost.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    }
}

enum FolioReaderHighlightError: Error {
    case runtimeError(String)
}

// MARK: - HTML Methods

extension FolioReaderHighlight {

    public struct MatchingHighlight {
        var text: String
        var id: String
        var startOffset: String
        var endOffset: String
        var bookId: String
        var currentPage: Int
    }

    /**
     Match a highlight on string.
     */
    public static func matchHighlight(_ matchingHighlight: MatchingHighlight) -> FolioReaderHighlight? {
        let pattern = "<highlight id=\"\(matchingHighlight.id)\" onclick=\".*?\" class=\"(.*?)\">((.|\\s)*?)</highlight>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: matchingHighlight.text, options: [], range: NSRange(location: 0, length: matchingHighlight.text.utf16.count))
        let str = (matchingHighlight.text as NSString)

        let mapped = matches?.map { (match) -> FolioReaderHighlight in
            let preLocation = max(0, match.range.location - kHighlightRange)
            let preLength = match.range.location - preLocation
            var contentPre = str.substring(with: NSRange(location: preLocation, length: preLength))
            
            let postLocation = match.range.location + match.range.length
            let postLength = min(str.length - postLocation, kHighlightRange)
            var contentPost = str.substring(with: NSRange(location: postLocation, length: postLength))

            // Normalize string before save
            contentPre = FolioReaderHighlight.subString(ofContent: contentPre, fromRangeOfString: ">", withPattern: "((?=[^>]*$)(.|\\s)*$)")
            contentPost = FolioReaderHighlight.subString(ofContent: contentPost, fromRangeOfString: "<", withPattern: "^((.|\\s)*?)(?=<)")

            let highlight = FolioReaderHighlight()
            highlight.highlightId = matchingHighlight.id
            highlight.type = FolioReaderHighlightStyle.styleForClass(str.substring(with: match.range(at: 1))).rawValue
            highlight.date = Date()
            highlight.content = FolioReaderHighlight.removeSentenceSpam(str.substring(with: match.range(at: 2)))
            highlight.contentPre = FolioReaderHighlight.removeSentenceSpam(contentPre)
            highlight.contentPost = FolioReaderHighlight.removeSentenceSpam(contentPost)
            highlight.page = matchingHighlight.currentPage
            highlight.bookId = matchingHighlight.bookId
            highlight.startOffset = (Int(matchingHighlight.startOffset) ?? -1)
            highlight.endOffset = (Int(matchingHighlight.endOffset) ?? -1)

            return highlight
        }

        return mapped?.first
    }

    private static func subString(ofContent content: String, fromRangeOfString rangeString: String, withPattern pattern: String) -> String {
        var updatedContent = content
        if updatedContent.range(of: rangeString) != nil {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let searchString = regex?.firstMatch(in: updatedContent, options: .reportProgress, range: NSRange(location: 0, length: updatedContent.count))

            if let string = searchString, (string.range.location != NSNotFound) {
                updatedContent = (updatedContent as NSString).substring(with: string.range)
            }
        }

        return updatedContent
    }

    /// Remove a Highlight from HTML by ID
    ///
    /// - Parameters:
    ///   - page: The page containing the HTML.
    ///   - highlightId: The ID to be removed
    ///   - completion: JSCallback with removed id
    public static func removeFromHTMLById(withinPage page: FolioReaderPage?, highlightId: String, completion: JSCallback? = nil) {
        page?.webView?.js("removeHighlightById('\(highlightId)')", completion: completion)
    }
    
    /**
     Remove span tag before store the highlight, this span is added on JavaScript.
     <span class=\"sentence\"></span>
     
     - parameter text: Text to analise
     - returns: Striped text
     */
    public static func removeSentenceSpam(_ text: String) -> String {
        
        // Remove from text
        func removeFrom(_ text: String, withPattern pattern: String) -> String {
            var locator = text
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.matches(in: locator, options: [], range: NSRange(location: 0, length: locator.utf16.count))
            let str = (locator as NSString)
            
            var newLocator = ""
            matches?.forEach({ (match: NSTextCheckingResult) in
                newLocator += str.substring(with: match.range(at: 1))
            })
            
            if (matches?.count > 0 && newLocator.isEmpty == false) {
                locator = newLocator
            }
            
            return locator
        }
        
        let pattern = "<span class=\"sentence\">((.|\\s)*?)</span>"
        let cleanText = removeFrom(text, withPattern: pattern)
        return cleanText
    }
}

extension FolioReaderHighlight: Comparable {
    public static func < (lhs: FolioReaderHighlight, rhs: FolioReaderHighlight) -> Bool {
        if lhs.page != rhs.page {
            return lhs.page < rhs.page
        }
        if let lStart = lhs.cfiStart, let rStart = rhs.cfiStart {
            let lSplit = lStart.split { $0 == "/" || $0 == ":" }
            let rSplit = rStart.split { $0 == "/" || $0 == ":" }
            for i in 0..<min(lSplit.count, rSplit.count) {
                let l = Int(lSplit[i]) ?? 0
                let r = Int(rSplit[i]) ?? 0
                if l != r {
                    return l < r
                }
            }
        }
        return lhs.startOffset < rhs.startOffset    //fallback
    }
    
}
