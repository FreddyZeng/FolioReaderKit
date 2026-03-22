//
//  PresentHighlight.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation
import UIKit

extension FolioReaderCenter {
    /**
     Present chapter list
     */
    @objc func presentChapterList(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()

        let bookList = FolioReaderBookList(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: self)
        let chapter = FolioReaderChapterList(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: self)
        let resoruce = FolioReaderResourceList(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: self)
        let history = FolioReaderHistoryList(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: self)
        let pageController = FolioReaderNavigationPageVC(folioReader: folioReader, readerConfig: readerConfig)
        
        pageController.viewControllerZero = bookList
        pageController.viewControllerOne = chapter
        pageController.viewControllerTwo = resoruce
        pageController.viewControllerThree = history
        
        pageController.segmentedControlItems = [readerConfig.localizedContentsTitle, readerConfig.localizedResourcesTitle, readerConfig.localizedHistoryTitle]
        if self.folioReader.structuralStyle == .bundle {
            pageController.segmentedControlItems.insert(readerConfig.localizedBooksTitle, at: 0)
        }
        if self.folioReader.structuralStyle == .topic {
            pageController.segmentedControlItems.insert(readerConfig.localizedTopicsTitle, at: 0)
        }
        
        let nav = UINavigationController(rootViewController: pageController)
        nav.navigationBar.backgroundColor = readerConfig.themeModeNavBackground[folioReader.themeMode]
        
        present(nav, animated: true, completion: nil)
    }

    @objc func presentBookmarkList(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()

        let reference = FolioReaderReferenceList(folioReader: folioReader, readerConfig: readerConfig)
        let bookmark = FolioReaderBookmarkList(folioReader: folioReader, readerConfig: readerConfig)
        let highlight = FolioReaderHighlightList(folioReader: folioReader, readerConfig: readerConfig)
        let pageController = FolioReaderAnnotationPageVC(folioReader: folioReader, readerConfig: readerConfig)

        pageController.viewControllerZero = reference
        pageController.viewControllerOne = bookmark
        pageController.viewControllerTwo = highlight
        
        pageController.segmentedControlItems = [readerConfig.localizedBookmarksTitle, readerConfig.localizedHighlightsTitle]

        if let refText = tempRefText {
            pageController.segmentedControlItems.insert("Reference", at: 0)
            pageController.tabBarItem = UITabBarItem(title: refText, image: nil, tag: 101)
        }
        
        let nav = UINavigationController(rootViewController: pageController)
        nav.navigationBar.backgroundColor = readerConfig.themeModeNavBackground[folioReader.themeMode]

        present(nav, animated: true, completion: nil)
    }
    
    /**
     Present fonts and settings menu
     */
    @objc func presentFontsMenu() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()
        hideBars()

        menuTabs.removeAll()
        // Menus
        let menuPageTab = FolioReaderPageMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuPageTab.tabBarItem = .init(title: "Page", image: UIImage(readerImageNamed: "icon-menu-page"), tag: 0)
        menuTabs.append(menuPageTab)
        
        let menuFontStyleTab = FolioReaderFontsMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuFontStyleTab.tabBarItem = .init(title: "Font", image: UIImage(readerImageNamed: "icon-menu-font"), tag: 1)
        menuTabs.append(menuFontStyleTab)

        let menuParagraphTab = FolioReaderParagraphMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuParagraphTab.tabBarItem = .init(title: "Paragraph", image: UIImage(readerImageNamed: "icon-menu-para"), tag: 2)
        menuTabs.append(menuParagraphTab)

        let menuAdvancedTab = FolioReaderAdvancedMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuAdvancedTab.tabBarItem = .init(title: "Advanced", image: UIImage(readerImageNamed: "icon-menu-adv"), tag: 3)
        menuTabs.append(menuAdvancedTab)
        
        let menuProfileTab = FolioReaderProfileMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuProfileTab.tabBarItem = .init(title: "Profile", image: UIImage(readerImageNamed: "icon-menu-adv"), tag: 4)
        menuTabs.append(menuProfileTab)
        
        menuBarController.setViewControllers(menuTabs, animated: true)
        menuBarController.view.backgroundColor = .clear
        menuBarController.modalPresentationStyle = .custom
        menuBarController.selectedIndex = lastMenuSelectedIndex
        
        animator = FolioModalTransitionAnimator(modalViewController: menuBarController)
        animator.isDragable = false
        animator.bounces = false
        animator.behindViewAlpha = 1.0
        animator.behindViewScale = 1.0
        animator.transitionDuration = 0.6
        animator.direction = .bottom

        menuBarController.transitioningDelegate = animator
        
        self.present(menuBarController, animated: true, completion: nil)
    }

    /**
     Present audio player menu
     */
    @objc func presentPlayerMenu(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()
        hideBars()

        let menu = FolioReaderPlayerMenu(folioReader: folioReader, readerConfig: readerConfig)
        menu.modalPresentationStyle = .custom

        animator = FolioModalTransitionAnimator(modalViewController: menu)
        animator.isDragable = true
        animator.bounces = false
        //animator.behindViewAlpha = 0.4
        animator.behindViewScale = 1
        animator.transitionDuration = 0.6
        animator.direction = .bottom

        menu.transitioningDelegate = animator
        present(menu, animated: true, completion: nil)
    }

    /**
     Present Quote Share
     */
    func presentQuoteShare(_ string: String) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let quoteShare = FolioReaderQuoteShare(initWithText: string, readerConfig: readerConfig, folioReader: folioReader, book: book)
        let nav = UINavigationController(rootViewController: quoteShare)

        if UIDevice.current.userInterfaceIdiom == .pad {
            nav.modalPresentationStyle = .formSheet
        }
        present(nav, animated: true, completion: nil)
    }
    
    /**
     Present add highlight note
     */
    func presentAddHighlightNote(_ highlight: FolioReaderHighlight, edit: Bool) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let addHighlightView = FolioReaderAddHighlightNote(withHighlight: highlight, folioReader: folioReader, readerConfig: readerConfig)
        addHighlightView.isEditHighlight = edit
        let nav = UINavigationController(rootViewController: addHighlightView)
        nav.modalPresentationStyle = .formSheet
        
        present(nav, animated: true, completion: nil)
    }
    
    func presentAddHighlightError(_ message: String) {
        let textView = UITextView()
        textView.text = message
        
        let vc = UIViewController()
        vc.view = textView
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alert.dismiss()
        }))
        present(alert, animated: true, completion: nil)
    }
}
