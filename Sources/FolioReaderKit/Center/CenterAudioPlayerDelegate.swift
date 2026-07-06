//
//  CenterAudioPlayerDelegate.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import Foundation

extension FolioReaderCenter: FolioReaderAudioPlayerDelegate {
    public func audioPlayer(_ player: FolioReaderAudioPlayer, executeJavaScript script: String, completion: ((Any?) -> Void)?) {
        currentPage?.webView?.js(script, completion: completion)
    }

    public func audioPlayerDidNeedNextChapter(_ player: FolioReaderAudioPlayer, completion: (() -> Void)?) {
        changePageToNext(completion)
    }

    public func audioPlayerDidNeedPrevChapter(_ player: FolioReaderAudioPlayer, completion: (() -> Void)?) {
        changePageToPrevious(completion)
    }

    public func audioPlayer(_ player: FolioReaderAudioPlayer, didUpdateAudioMark href: String, fragmentID: String) {
        audioMark(href: href, fragmentID: fragmentID)
    }

    public func audioPlayerCurrentChapter(_ player: FolioReaderAudioPlayer) -> FRResource? {
        return currentPage?.getChapter()
    }

    public func audioPlayerIsLastPage(_ player: FolioReaderAudioPlayer) -> Bool {
        return isLastPage
    }
}
