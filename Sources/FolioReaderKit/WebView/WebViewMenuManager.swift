//
//  WebViewMenuManager.swift
//  FolioReaderKit
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import UIKit
import WebKit

class WebViewMenuManager {
    private weak var webView: FolioReaderWebView?

    init(webView: FolioReaderWebView) {
        self.webView = webView
    }

    func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let webView = webView else { return false }
        guard webView.readerConfig.useReaderMenuController else {
            return webView.superCanPerformAction(action, withSender: sender)
        }

        var result = false
        if webView.isSharingHighlight {
            result = false
            let canPerform = action == #selector(FolioReaderWebView.updateHighlightNote(_:))
            
            print("\(#function) canPerform=\(canPerform) action=\(action)")
            if canPerform {
                result = true
            }
        } else if webView.isColors {
            result = false
        } else {
            let canPerform = action == #selector(FolioReaderWebView.highlight(_:))
            || action == #selector(FolioReaderWebView.highlightWithNote(_:))
            || action == #selector(FolioReaderWebView.updateHighlightNote(_:))
            || (action == #selector(FolioReaderWebView.define(_:)))
            || (action == #selector(FolioReaderWebView.reference(_:)))
            || (action == #selector(FolioReaderWebView.lookup(_:)) && webView.mDictView != nil)
            || (action == #selector(FolioReaderWebView.play(_:)) && (webView.book.hasAudio || webView.readerConfig.enableTTS))
            || (action == #selector(FolioReaderWebView.share(_:)) && webView.readerConfig.allowSharing)
            || (action == #selector(FolioReaderWebView.copy(_:)) && webView.readerConfig.allowCopy)
            print("\(#function) canPerform=\(canPerform) action=\(action)")
            if canPerform {
                result = true
            }
        }
        
        if webView.folioReader.readerContainer?.readerConfig.debug.contains(.contentMenu) ?? false {
            let menuItems = UIMenuController.shared.menuItems ?? [UIMenuItem]()
            let menuItemTitle = menuItems.compactMap { $0.title }
            
            print("FRWV canPerformAction \(webView.readerConfig.useReaderMenuController) \(webView.isSharingHighlight) \(webView.isColors) \(result) \(action) \(menuItemTitle)")
        }
        
        return result
    }

    func share(_ sender: UIMenuController?) {
        guard let webView = webView, let sender = sender else { return }
        
        guard let currentPage = webView.folioReader.readerCenter?.currentPage,
              let currentPageWebView = currentPage.webView
        else {
            return
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let shareImage = UIAlertAction(title: webView.readerConfig.localizedShareImageQuote, style: .default, handler: { (action) -> Void in
            if currentPageWebView.isSharingHighlight {
                currentPageWebView.js("getHighlightContent()") { textToShare in
                    guard let textToShare = textToShare else { return }
                    webView.folioReader.readerCenter?.presentQuoteShare(textToShare)
                }
            } else {
                currentPageWebView.js("getSelectedText()") { textToShare in
                    guard let textToShare = textToShare else { return }
                    webView.folioReader.readerCenter?.presentQuoteShare(textToShare)

                    webView.clearTextSelection()
                }
            }
            webView.setMenuVisible(false)
        })

        let shareText = UIAlertAction(title: webView.readerConfig.localizedShareTextQuote, style: .default) { (action) -> Void in
            if currentPageWebView.isSharingHighlight {
                currentPageWebView.js("getHighlightContent()") { textToShare in
                    guard let textToShare = textToShare else { return }
                    webView.folioReader.readerCenter?.shareHighlight(textToShare, rect: sender.menuFrame)
                }
            } else {
                currentPageWebView.js("getSelectedText()") { textToShare in
                    guard let textToShare = textToShare else { return }
                    webView.folioReader.readerCenter?.shareHighlight(textToShare, rect: sender.menuFrame)
                }
            }
            webView.setMenuVisible(false)
        }

        let cancel = UIAlertAction(title: webView.readerConfig.localizedCancel, style: .cancel, handler: nil)

        alertController.addAction(shareImage)
        alertController.addAction(shareText)
        alertController.addAction(cancel)

        if let alert = alertController.popoverPresentationController {
            alert.sourceView = webView.folioReader.readerCenter?.currentPage
            alert.sourceRect = sender.menuFrame
        }

        webView.folioReader.readerCenter?.present(alertController, animated: true, completion: nil)
    }

    func colors(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        webView.isColors = true
        webView.createMenu(onHighlight: false)
        webView.setMenuVisible(true)
    }

    func remove(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        webView.js("removeThisHighlight()") { removedId in
            guard let removedId = removedId else { return }
            webView.folioReader.delegate?.folioReaderHighlightProvider?(webView.folioReader).folioReaderHighlight(webView.folioReader, removedId: removedId)
        }
        webView.createMenu(onHighlight: false)
        webView.setMenuVisible(false)
    }

    func define(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        guard let currentPage = webView.folioReader.readerCenter?.currentPage,
              let currentPageWebView = currentPage.webView
        else {
            return
        }
        currentPageWebView.js("getSelectedText()") { selectedText in
            guard let selectedText = selectedText else { return }

            webView.setMenuVisible(false)
            webView.clearTextSelection()

            let vc = UIReferenceLibraryViewController(term: selectedText)
            vc.view.backgroundColor = webView.readerConfig.menuBackgroundColor
            vc.view.tintColor = webView.readerConfig.tintColor
            guard let readerContainer = webView.readerContainer else { return }
            readerContainer.present(vc, animated: true, completion: nil)
        }
    }

    func lookup(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        guard let currentPage = webView.folioReader.readerCenter?.currentPage,
              let currentPageWebView = currentPage.webView
        else {
            return
        }
        currentPageWebView.js("getSelectedText()") { selectedText in
            guard let selectedText = selectedText else { return }
            guard let mDictView = webView.mDictView else { return }

            webView.setMenuVisible(false)
            webView.clearTextSelection()

            mDictView.title = selectedText
            webView.folioReader.readerCenter?.pageDelegate?.pageStyleChanged?(currentPage, webView.folioReader)
            
            guard let readerContainer = webView.readerContainer else { return }
            readerContainer.present(mDictView, animated: true)
        }
    }
    
    func reference(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        guard let currentPage = webView.folioReader.readerCenter?.currentPage,
              let currentPageWebView = currentPage.webView
        else {
            return
        }
        currentPageWebView.js("getSelectedTextCFI()") { selJsonStr in
            guard let selJsonData = selJsonStr?.data(using: .utf8),
                  let selJson = try? JSONSerialization.jsonObject(with: selJsonData) as? [String:String],
                  let selectedText = selJson["sel"],
                  let selectedCFI = selJson["cfi"]
            else { return }
            
            webView.clearTextSelection()
            webView.setMenuVisible(false)
            
            guard let readerCenter = webView.readerContainer?.centerViewController,
                  let bookmarkBarButtonItem = readerCenter.navigationItem.leftBarButtonItems?[safe: 2],
                  let selector = bookmarkBarButtonItem.action else { return }
            
            readerCenter.tempRefText = selectedText
            readerCenter.tempRefCFI = selectedCFI
            webView.folioReader.currentAnnotationMenuIndex = 0
            UIApplication.shared.sendAction(selector, to: readerCenter, from: bookmarkBarButtonItem, for: nil)
        }
    }
    
    func play(_ sender: UIMenuController?) {
        guard let webView = webView else { return }
        webView.folioReader.readerAudioPlayer?.play()
        webView.clearTextSelection()
    }

    func createMenu(onHighlight: Bool) {
        guard let webView = webView else { return }
        guard (webView.readerConfig.useReaderMenuController == true) else {
            return
        }

        webView.isSharingHighlight = onHighlight

        let colors = UIImage(readerImageNamed: "colors-marker")
        var share = UIImage(readerImageNamed: "share-marker")
        let remove = UIImage(readerImageNamed: "no-marker")
        let yellow = UIImage(readerImageNamed: "yellow-marker")
        let green = UIImage(readerImageNamed: "green-marker")
        let blue = UIImage(readerImageNamed: "blue-marker")
        let pink = UIImage(readerImageNamed: "pink-marker")
        let underline = UIImage(readerImageNamed: "underline-marker")
        var mdictImage = UIImage(readerImageNamed: "icon-dictionary")
        if UIDevice.current.userInterfaceIdiom == .pad {
            share = share?.withTintColor(UITraitCollection.current.userInterfaceStyle == .dark ? .white : .black)
            mdictImage = mdictImage?.withTintColor(UITraitCollection.current.userInterfaceStyle == .dark ? .white : .black)
        } else {
            share = share?.withTintColor(.white)
            mdictImage = mdictImage?.withTintColor(.white)
        }

        let menuController = UIMenuController.shared

        let highlightItem = UIMenuItem(title: webView.readerConfig.localizedHighlightMenu, action: #selector(FolioReaderWebView.highlight(_:)))
        let highlightNoteItem = UIMenuItem(title: webView.readerConfig.localizedHighlightNote, action: #selector(FolioReaderWebView.highlightWithNote(_:)))
        let editNoteItem = UIMenuItem(title: webView.readerConfig.localizedHighlightNote, action: #selector(FolioReaderWebView.updateHighlightNote(_:)))
        let playAudioItem = UIMenuItem(title: webView.readerConfig.localizedPlayMenu, action: #selector(FolioReaderWebView.play(_:)))
        let defineItem = UIMenuItem(title: webView.readerConfig.localizedDefineMenu, action: #selector(FolioReaderWebView.define(_:)))
        let referenceItem = UIMenuItem(title: "Ref.", action: #selector(FolioReaderWebView.reference(_:)))
        
        let mDictItem = UIMenuItem(title: webView.readerConfig.localizedMDictMenu, image: mdictImage) { [weak webView] _ in
            webView?.lookup(menuController)
        }
        
        let colorsItem = UIMenuItem(title: "C", image: colors) { [weak webView] _ in
            webView?.colors(menuController)
        }
        let shareItem = UIMenuItem(title: "S", image: share) { [weak webView] _ in
            webView?.share(menuController)
        }
        let removeItem = UIMenuItem(title: "R", image: remove) { [weak webView] _ in
            webView?.remove(menuController)
        }
        let yellowItem = UIMenuItem(title: "Y", image: yellow) { [weak webView] _ in
            webView?.setYellow(menuController)
        }
        let greenItem = UIMenuItem(title: "G", image: green) { [weak webView] _ in
            webView?.setGreen(menuController)
        }
        let blueItem = UIMenuItem(title: "B", image: blue) { [weak webView] _ in
            webView?.setBlue(menuController)
        }
        let pinkItem = UIMenuItem(title: "P", image: pink) { [weak webView] _ in
            webView?.setPink(menuController)
        }
        let underlineItem = UIMenuItem(title: "U", image: underline) { [weak webView] _ in
            webView?.setUnderline(menuController)
        }

        var menuItems: [UIMenuItem] = []

        // menu on existing highlight
        if onHighlight {
            menuItems = [colorsItem, editNoteItem, removeItem]
            
            if (webView.readerConfig.allowSharing == true) {
                menuItems.append(shareItem)
            }
            
        } else if webView.isColors {
            // menu for selecting highlight color
            menuItems = [yellowItem, greenItem, blueItem, pinkItem, underlineItem]
        } else {
            // default menu
            menuItems = [highlightItem, defineItem, referenceItem, highlightNoteItem]
            if webView.readerConfig.enableMDictViewer {
                menuItems.append(mDictItem)
            }

            if webView.book.hasAudio || webView.readerConfig.enableTTS {
                menuItems.insert(playAudioItem, at: 0)
            }

            if (webView.readerConfig.allowSharing == true) {
                menuItems.append(shareItem)
            }
        }
        
        menuController.menuItems = menuItems
        menuController.update()
        
        if let readerContainer = webView.folioReader.readerContainer {
            UIMenuController.installTo(responder: readerContainer)
        }
    }
    
    func setMenuVisible(_ menuVisible: Bool, animated: Bool = true, andRect rect: CGRect = CGRect.zero) {
        guard let webView = webView else { return }
        if let currentPage = webView.folioReader.readerCenter?.currentPage {
            currentPage.menuIsVisible = menuVisible
        }
        if menuVisible {
            webView.folioReader.readerCenter?.invalidatePendingBarReveal()
        }

        if menuVisible == false {
            UIMenuController.shared.hideMenu()
        }
        
        if !menuVisible && webView.isSharingHighlight || !menuVisible && webView.isColors {
            webView.isColors = false
            webView.isSharingHighlight = false
        }
        
        if menuVisible  {
            if !rect.equalTo(CGRect.zero) {
                UIMenuController.shared.showMenu(from: webView, rect: rect)
            }
        } else {
            webView.createMenu(onHighlight: false)
        }
        
        if menuVisible {
            UIMenuController.shared.showMenu(from: webView, rect: rect)
        } else {
            UIMenuController.shared.hideMenu()
        }
    }
}
