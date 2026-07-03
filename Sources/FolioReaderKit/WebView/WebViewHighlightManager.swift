//
//  WebViewHighlightManager.swift
//  FolioReaderKit
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import UIKit
import WebKit

class WebViewHighlightManager {
    private weak var webView: FolioReaderWebView?

    init(webView: FolioReaderWebView) {
        self.webView = webView
    }

    func highlight(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        webView.js("highlightStringCFI('\(FolioReaderHighlightStyle.classForStyle(webView.folioReader.currentHighlightStyle))', false)") { [weak self] highlightAndReturn in
            guard let self = self, let highlightAndReturn = highlightAndReturn else { return }
            
            print(highlightAndReturn)
            guard let jsonData = highlightAndReturn.data(using: .utf8) else {
                return
            }
            self.handleHighlightReturn(jsonData)
        }
    }
    
    func highlightWithNote(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        webView.js("highlightStringCFI('\(FolioReaderHighlightStyle.classForStyle(webView.folioReader.currentHighlightStyle))', true)") { [weak self] highlightAndReturn in
            guard let self = self, let highlightAndReturn = highlightAndReturn else { return }

            print(highlightAndReturn)
            guard let jsonData = highlightAndReturn.data(using: .utf8) else {
                return
            }

            self.handleHighlightReturn(jsonData, withNote: true)
        }
    }
    
    // will keep original's id and date if presented
    func handleHighlightReturn(_ jsonData: Data, withNote: Bool = false, original: FolioReaderHighlight? = nil, completion: ((FolioReaderHighlight?, FolioReaderHighlightError?) -> Void)? = nil) {
        guard let webView = webView else { return }
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray,
                  let dic = json.firstObject as? [String: String] else {
                      throw FolioReaderHighlightError.runtimeError("no json result, string=\(String(data: jsonData, encoding: .utf8) ?? "(invalid data)")")
            }
            guard let startOffset = dic["startOffset"], let startOffsetInt = Int(startOffset) else {
                throw FolioReaderHighlightError.runtimeError("no start offset")
            }
            guard let endOffset = dic["endOffset"], let endOffsetInt = Int(endOffset) else {
                throw FolioReaderHighlightError.runtimeError("no end offset")
            }
            guard let prevHighlightLengthStart = dic["prevHighlightLengthStart"], let prevHighlightLengthStartInt = Int(prevHighlightLengthStart) else {
                throw FolioReaderHighlightError.runtimeError("no prevHighlightLengthStart")
            }
            guard let prevHighlightLengthEnd = dic["prevHighlightLengthEnd"], let prevHighlightLengthEndInt = Int(prevHighlightLengthEnd) else {
                throw FolioReaderHighlightError.runtimeError("no prevHighlightLengthEnd")
            }
            
            let highlight = FolioReaderHighlight()
            highlight.bookId = webView.book.name?.deletingPathExtension
            highlight.startOffset = startOffsetInt
            highlight.endOffset = endOffsetInt
            highlight.content = dic["content"]
            highlight.cfiStart = dic["cfiStart"]
            highlight.cfiEnd = dic["cfiEnd"]
            highlight.contentPost = dic["contentPost"]
            highlight.contentPre = dic["contentPre"]
            if let date = original?.date {
                highlight.date = date + 0.001
            } else {
                highlight.date = Date()
            }
            highlight.highlightId = original?.highlightId ?? dic["id"]
            highlight.page = webView.folioReader.readerCenter?.currentPageNumber ?? 1
            highlight.type = webView.folioReader.currentHighlightStyle
            highlight.style = FolioReaderHighlightStyle.classForStyle(highlight.type)

            if prevHighlightLengthStartInt > 0,
               let cfiStart = highlight.cfiStart,
               let idx = cfiStart.firstIndex(of: ":") {
                let offsetIdx = cfiStart.index(after: idx)
                if let offset = Int(cfiStart[offsetIdx...]) {
                    highlight.cfiStart = String(cfiStart[..<offsetIdx]) + Int(offset + prevHighlightLengthStartInt).description
                }
            }
            if prevHighlightLengthEndInt > 0,
               let cfiEnd = highlight.cfiEnd,
               let idx = cfiEnd.firstIndex(of: ":") {
                let offsetIdx = cfiEnd.index(after: idx)
                if let offset = Int(cfiEnd[offsetIdx...]) {
                    highlight.cfiEnd = String(cfiEnd[..<offsetIdx]) + Int(offset + prevHighlightLengthEndInt).description
                }
            }
            
            highlight.encodeContents()
            
            let serializedData = try JSONEncoder().encode([highlight])
            let encodedData = serializedData.base64EncodedString()
            webView.js("injectHighlights('\(encodedData)')") { [weak self] result in
                guard let self = self, let webView = self.webView else { return }
                var errMsg: String = "Unknown Error"
                var deferred: (() -> Void)? = {
                    if original == nil {
                        webView.folioReader.readerCenter?.presentAddHighlightError(errMsg)
                    } else {
                        completion?(original, FolioReaderHighlightError.runtimeError(errMsg))
                    }
                    return
                }
                
                defer {
                    deferred?()
                }
                
                guard let result = result else {
                    return
                }
                
                let decoder = JSONDecoder()
                
                guard let encodedData = result.data(using: .utf8),
                      let encodedObjects = try? decoder.decode([String].self, from: encodedData)
                else {
                    return
                }
                
                var boundingRect: NodeBoundingClientRect? = nil
                
                if let objectData = encodedObjects.first?.data(using: .utf8) {
                    boundingRect = try? JSONDecoder().decode(NodeBoundingClientRect.self, from: objectData)
                }
                
                guard boundingRect != nil, boundingRect!.err.isEmpty else {
                    errMsg = boundingRect?.err ?? errMsg
                    return
                }
                
                let contentOffset = CGPoint(x: boundingRect!.left, y: boundingRect!.top)
            
                let highlightChapterNames = webView.folioReader.readerCenter?.currentPage?.getChapterTocReferences(for: contentOffset, by: webView.frame.size).compactMap { $0.title } ?? ["TODO"]
                highlight.tocFamilyTitles = highlightChapterNames.reversed()
                
                highlight.spineName = webView.book.spine.spineReferences[highlight.page - 1].resource.href
                if let resHref = highlight.spineName,
                   let opfUrl = URL(string: webView.book.opfResource.href),
                   let resUrl = URL(string: resHref, relativeTo: opfUrl) {
                    highlight.spineName = resUrl.absoluteString.replacingOccurrences(of: "//", with: "")
                    while highlight.spineName.hasPrefix("/") {
                        highlight.spineName.removeFirst()
                    }
                }

                if let cfiStart = highlight.cfiStart, cfiStart.hasPrefix("/2") == false {
                    highlight.cfiStart = "/2\(cfiStart)"
                }
                if let cfiEnd = highlight.cfiEnd, cfiEnd.hasPrefix("/2") == false {
                    highlight.cfiEnd = "/2\(cfiEnd)"
                }
                
                if withNote {
                    if original == nil {
                        webView.folioReader.readerCenter?.presentAddHighlightNote(highlight, edit: false)
                    } else {
                        completion?(highlight, nil)
                    }
                } else {
                    webView.folioReader.delegate?.folioReaderHighlightProvider?(webView.folioReader).folioReaderHighlight(webView.folioReader, added: highlight) { error in
                        guard error == nil else {
                            if original == nil {
                                webView.folioReader.readerCenter?.presentAddHighlightError(error!.localizedDescription)
                            } else {
                                completion?(highlight, FolioReaderHighlightError.runtimeError(error!.localizedDescription))
                            }
                            return
                        }
                        
                        webView.clearTextSelection()
                        webView.setMenuVisible(false)
                        
                        webView.folioReader.readerCenter?.highlightErrors.removeValue(forKey: highlight.highlightId)
                        
                        completion?(highlight, nil)
                    }
                }
                
                deferred = nil
            }
            
        } catch FolioReaderHighlightError.runtimeError(let hlError) {
            completion?(original, FolioReaderHighlightError.runtimeError(hlError))
        } catch {
            completion?(original, FolioReaderHighlightError.runtimeError("\(error.localizedDescription)"))
        }
    }
    
    func updateHighlightNote(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        webView.js("getHighlightId()") { [weak self] highlightId in
            guard let self = self, let webView = self.webView else { return }
            guard
                let highlightId = highlightId,
                let highlightNote = webView.folioReader.delegate?.folioReaderHighlightProvider?(webView.folioReader).folioReaderHighlight(webView.folioReader, getById: highlightId)
            else { return }
            
            webView.folioReader.readerCenter?.presentAddHighlightNote(highlightNote, edit: true)
            webView.createMenu(onHighlight: false)
        }
    }

    func setYellow(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .yellow)
    }

    func setGreen(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .green)
    }

    func setBlue(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .blue)
    }

    func setPink(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .pink)
    }

    func setUnderline(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .underline)
    }

    func changeHighlightStyle(_ sender: UIMenuController?, style: FolioReaderHighlightStyle) {
        guard let webView = webView else { return }
        webView.folioReader.currentHighlightStyle = style.rawValue

        webView.js("setHighlightStyle('\(FolioReaderHighlightStyle.classForStyle(style.rawValue))')") { updateId in
            guard let updateId = updateId else { return }
            webView.folioReader.delegate?.folioReaderHighlightProvider?(webView.folioReader).folioReaderHighlight(webView.folioReader, updateById: updateId, type: style)
        }
        
        webView.setMenuVisible(false)
    }
}
