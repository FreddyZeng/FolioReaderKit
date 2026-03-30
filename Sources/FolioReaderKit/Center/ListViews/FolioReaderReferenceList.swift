//
//  FolioReaderBookmarkList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 01/09/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import SwiftSoup

class FolioReaderReferenceList: UITableViewController {

    fileprivate var sections = [Int]()
    fileprivate var sectionBookmarks = [Int: [FolioReaderBookmark]]()
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

    fileprivate var addingBookmarkPos: String?
    fileprivate var editingBookmarkPos: String?
    
    private let dateFormatter = DateFormatter()
    
    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader

        super.init(style: UITableView.Style.plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init with coder not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .medium
        self.dateFormatter.doesRelativeDateFormatting = true
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
//        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: kReuseHeaderFooterIdentifier)
        
        self.tableView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        self.tableView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)
        
        loadSections()
    }

    func loadSection(bookId: String, book: FRBook, pageNumber: Int, refText: String, deepest: FolioReaderBookmark) async -> [FolioReaderBookmark] {
        let accumulator = DataAccumulator()
        
        guard let epubArchive = await book.getThreadEpubArchive(),
              let spine = book.spine.spineReferences[safe: pageNumber - 1],
              let opfURL = URL(fileURLWithPath: book.opfResource.href, isDirectory: false) as URL?,
              let spineURL = URL(fileURLWithPath: spine.resource.href, isDirectory: false, relativeTo: opfURL) as URL?
        else { return [] }
        
        let entryPath = spineURL.path.trimmingCharacters(in: ["/"])
        guard let epubEntry = book.archiveEntriesCache[entryPath],
              let _ = try? await epubArchive.extract(epubEntry, consumer: { data in
                  accumulator.append(data)
              }),
              let epubEntryString = String(data: accumulator.result, encoding: .utf8),
              let document = try? SwiftSoup.parse(epubEntryString),
              let _ = try? document.attr("CFI", "/\(pageNumber * 2)")
        else { return [] }
        
        tagCFItoDoc(document)
        
        guard let bookmarks = try? document.getElementsMatchingOwnText(Pattern.compile(refText))
                .map({ element -> [FolioReaderBookmark] in
                    var bookmarks = [FolioReaderBookmark]()
                    
                    guard let pos = try? element.attr("CFI") else { return bookmarks }
                    let bookmark = FolioReaderBookmark()
                    bookmark.date = .init()
                    bookmark.bookId = bookId
                    bookmark.page = pageNumber
                    bookmark.pos_type = "epubcfi"
                    bookmark.pos = "epubcfi(" + pos + ")"
                    guard bookmark < deepest else { return bookmarks }
                    
                    let textNodes = element.textNodes()
                    let offsetByOne = textNodes.first?.previousSibling() != nil     //Possible bug: first text node (before first child element) is omitted
                    for i in 0..<textNodes.count {
                        var elementOwnText = textNodes[i].getWholeText()
                        guard elementOwnText.contains(refText) else { continue }
                        
                        var prevSibling = textNodes[i].previousSibling()
                        while let text = (prevSibling as? TextNode)?.text() ?? (try? (prevSibling as? Element)?.text()),
                              text.contains(refText) == false {
                            elementOwnText.insert(contentsOf: text.trimmingCharacters(in: .whitespacesAndNewlines), at: elementOwnText.startIndex)
                            prevSibling = prevSibling?.previousSibling()
                        }
                        
                        var nextSibling = textNodes[i].nextSibling()
                        while let text = (nextSibling as? TextNode)?.text() ?? (try? (nextSibling as? Element)?.text()),
                              text.contains(refText) == false {
                            elementOwnText.insert(contentsOf: text.trimmingCharacters(in: .whitespacesAndNewlines), at: elementOwnText.endIndex)
                            nextSibling = nextSibling?.nextSibling()
                        }
                        
                        if elementOwnText.count > 200 {
                            var findRangeStart = elementOwnText.startIndex
                            
                            while let refRange = elementOwnText.range(of: refText, options: [], range: findRangeStart..<elementOwnText.endIndex, locale: nil),
                                  let bookmark = bookmark.copy() as? FolioReaderBookmark {
                                var bmStart = refRange.lowerBound
                                var bmEnd = refRange.upperBound
                                let _ = elementOwnText.formIndex(&bmStart, offsetBy: -30, limitedBy: elementOwnText.startIndex)
                                let _ = elementOwnText.formIndex(&bmEnd, offsetBy: 70, limitedBy: elementOwnText.endIndex)
                                
                                bookmark.title = (bmStart > elementOwnText.startIndex ? "..." : "")
                                + String(elementOwnText[bmStart..<bmEnd])
                                + (bmEnd < elementOwnText.endIndex ? "..." : "")
                                bookmark.pos = "epubcfi(" + pos + "/\(i*2 + 1 + (offsetByOne ? 2 : 0)):\(bmStart.utf16Offset(in: elementOwnText))" + ")"
                                bookmarks.append(bookmark)
                                
                                findRangeStart = bmEnd
                            }
                        } else if let bookmark = bookmark.copy() as? FolioReaderBookmark,
                                  let bmStart = elementOwnText.range(of: refText)?.upperBound {
                            bookmark.title = elementOwnText.trimmingCharacters(in: .whitespacesAndNewlines)
                            bookmark.pos = "epubcfi(" + pos + "/\(i*2 + 1 + (offsetByOne ? 2 : 0)):\(bmStart.utf16Offset(in: elementOwnText))" + ")"
                            bookmarks.append(bookmark)
                        }
                    }
                    
                    return bookmarks
                }).flatMap({ $0 })
        else { return [] }

        return bookmarks
    }
    
    func loadSections() {
        guard let bookId = self.folioReader.readerConfig?.identifier,
              let readerCenter = self.folioReader.readerCenter,
              let refText = readerCenter.tempRefText
        else { return }
        
        let currentPageNumber = readerCenter.currentPageNumber
        guard currentPageNumber > 0 else { return }
        
        var startPageNumber = 1
        if self.folioReader.structuralStyle == .bundle,
           let currentPage = readerCenter.currentPage,
           let webView = currentPage.webView {
            let tocRefs = currentPage.getChapterTocReferences(for: webView.scrollView.contentOffset, by: webView.frame.size)
            if let rootTocRef = tocRefs.filter({ $0.level == self.folioReader.structuralTrackingTocLevel.rawValue - 1 }).first {
                startPageNumber = readerCenter.book.findPageByResource(rootTocRef) + 1
            }
        }
        let deepestBookmark = FolioReaderBookmark()
        deepestBookmark.page = currentPageNumber
        deepestBookmark.pos = readerCenter.currentWebViewScrollPositions[currentPageNumber - 1]?.cfi
        if let tempRefCFI = readerCenter.tempRefCFI {
            deepestBookmark.pos = "epubcfi(\(currentPageNumber*2)/2\(tempRefCFI))"
        }
        for pageNumber in (startPageNumber...currentPageNumber).reversed() {
            Task {
                let bookmarks = await self.loadSection(bookId: bookId, book: readerCenter.book, pageNumber: pageNumber, refText: refText, deepest: deepestBookmark)
                guard bookmarks.isEmpty == false else { return }
                await MainActor.run {
                    self.sectionBookmarks[pageNumber] = bookmarks
                    self.sections = self.sectionBookmarks.keys.sorted()
                    self.tableView.reloadData()
                    
                    delay(0.2) {
                        self.scrollToVisible()
                    }
                }
            }
        }
    }
    
    func tagCFItoDoc(_ element: Element) {
        guard let cfi = try? element.attr("CFI") else { return }
        let children = element.children()
        for i in children.startIndex..<children.endIndex {
            guard let _ = try? children[i].attr("CFI", cfi + "/" + ((i+1)*2).description)
            else { continue }
            tagCFItoDoc(children[i])
        }
    }
    
    func scrollToVisible() {
        guard let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber,
              let sectionPageNumber = self.sections.filter({ $0 <= currentPageNumber }).last,
              let section = self.sections.firstIndex(of: sectionPageNumber)
        else { return }
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Jump to the current chapter
        DispatchQueue.main.async {
            self.scrollToVisible()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let addingBookmarkPos = addingBookmarkPos,
           let provider = self.folioReader.delegate?.folioReaderBookmarkProvider?(self.folioReader) {
            provider.folioReaderBookmark(self.folioReader, removed: addingBookmarkPos)
        }
        
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionBookmarks[sections[section]]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let pageNumber = sections[safe: section] else { return nil }
        guard let tocItem = self.folioReader.readerCenter?.getChapterName(pageNumber: pageNumber) else {
            return "  Book Item \(pageNumber)"
        }
        var title = [tocItem.title!]
        var parent = tocItem.parent
        while (parent != nil) {
            if parent?.title != nil {
                title.append(parent!.title!)
            }
            parent = parent?.parent
        }
        return "  " + title.reversed().joined(separator: ", ")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath)
        cell.backgroundColor = UIColor.clear

        guard let bookmark = sectionBookmarks[sections[indexPath.section]]?[indexPath.row] else {
            return cell
        }

        // Format date
        
        let dateString = dateFormatter.string(from: bookmark.date)

        // Date
        var dateLabel: UILabel!
        if cell.contentView.viewWithTag(456) == nil {
            dateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 16))
            dateLabel.tag = 456
            dateLabel.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
            dateLabel.font = UIFont(name: "Avenir-Medium", size: 12)
            cell.contentView.addSubview(dateLabel)
        } else {
            dateLabel = cell.contentView.viewWithTag(456) as? UILabel
        }

        dateLabel.text = dateString.uppercased()
        dateLabel.textColor = self.folioReader.isNight(UIColor(white: 5, alpha: 0.3), UIColor.lightGray)
        dateLabel.frame = CGRect(x: 20, y: 20, width: view.frame.width-40, height: dateLabel.frame.height)
        
        if let pos = bookmark.pos, let _ = self.folioReader.readerCenter?.bookmarkErrors[pos] {
            var errorLabel: UILabel!
            if cell.contentView.viewWithTag(4567) == nil {
                errorLabel = UILabel(frame: CGRect(x: view.frame.width-40, y: 0, width: 40, height: 16))
                errorLabel.tag = 4567
                errorLabel.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
                errorLabel.font = UIFont(name: "Avenir-Medium", size: 12)
                cell.contentView.addSubview(errorLabel)
            } else {
                errorLabel = cell.contentView.viewWithTag(4567) as? UILabel
            }
            errorLabel.text = "Cannot Locate, Touch to Fix"
            errorLabel.textColor = UIColor.systemRed
            errorLabel.sizeToFit()
            errorLabel.frame = CGRect(x: view.frame.width-180, y: 20, width: 160, height: errorLabel.frame.height)
        } else {
            cell.contentView.viewWithTag(4567)?.removeFromSuperview()
        }

        // Text
        var bookmarkLabel: UILabel!
        if cell.contentView.viewWithTag(123) == nil {
            bookmarkLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 0))
            bookmarkLabel.tag = 123
            bookmarkLabel.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
            bookmarkLabel.numberOfLines = 0
            bookmarkLabel.lineBreakMode = .byWordWrapping
            bookmarkLabel.textColor = UIColor.black
            cell.contentView.addSubview(bookmarkLabel)
        } else {
            bookmarkLabel = cell.contentView.viewWithTag(123) as? UILabel
        }

        let nsTitle = bookmark.title as NSString
        let titleAttributedString = NSMutableAttributedString(string: bookmark.title)
        
        let titleRange = NSRange(location: 0, length: nsTitle.length)
        titleAttributedString.addAttribute(.font, value: UIFont(name: "Avenir-Light", size: 16)!, range: titleRange)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        titleAttributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: titleRange)
        
        let textColor = self.folioReader.isNight(self.readerConfig.menuTextColor, UIColor.black)
        titleAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: titleRange)
        
        if let refText = self.folioReader.readerCenter?.tempRefText {
            let firstRange = nsTitle.range(of: refText)
            if firstRange.length > 0 {
                titleAttributedString.addAttribute(.kern, value: NSNumber(1.4), range: firstRange)
                titleAttributedString.addAttribute(.font, value: UIFont(name: "Avenir-Black", size: 17)!, range: firstRange)
            }
        }
        
        bookmarkLabel.attributedText = titleAttributedString
        bookmarkLabel.sizeToFit()
        bookmarkLabel.frame = CGRect(x: 20, y: 46, width: view.frame.width-40, height: bookmarkLabel.frame.height)
        
        var bookmarkTitleEdit: UITextField!
        if let view = cell.contentView.viewWithTag(1234){
            bookmarkTitleEdit = view as? UITextField
        } else {
            bookmarkTitleEdit = UITextField(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 0))
            bookmarkTitleEdit.tag = 1234
            bookmarkTitleEdit.autoresizingMask = .flexibleWidth
            bookmarkTitleEdit.textColor = .black
            cell.contentView.addSubview(bookmarkTitleEdit)
        }
        
        let isEditingItem = (bookmark.pos == self.editingBookmarkPos) || (bookmark.pos == self.addingBookmarkPos)
        bookmarkTitleEdit.isHidden = !isEditingItem
        bookmarkTitleEdit.backgroundColor = isEditingItem ? .white : .clear
        
        if isEditingItem {
            bookmarkTitleEdit.becomeFirstResponder()
        }
        
        bookmarkTitleEdit.text = bookmark.title
        bookmarkTitleEdit.sizeToFit()
        bookmarkTitleEdit.frame = CGRect(x: 20, y: 46, width: view.frame.width-40, height: bookmarkLabel.frame.height)
        
        var bookmarkTitleSaveButton: UIButton!
        if let view = cell.contentView.viewWithTag(987) {
            bookmarkTitleSaveButton = view as? UIButton
        } else {
            bookmarkTitleSaveButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 0))
            bookmarkTitleSaveButton.tag = 987
            bookmarkTitleSaveButton.setTitle("Save", for: .normal)
            bookmarkTitleSaveButton.setTitleColor(self.readerConfig.tintColor, for: .normal)
            bookmarkTitleSaveButton.addTarget(self, action: #selector(saveBookmarkTitleAction(_:)), for: .primaryActionTriggered)
            cell.contentView.addSubview(bookmarkTitleSaveButton)
        }
        bookmarkTitleSaveButton.sizeToFit()
        bookmarkTitleSaveButton.isHidden = !isEditingItem
        bookmarkTitleSaveButton.frame = CGRect(x: view.frame.width-60, y: 20, width: 40, height: dateLabel.frame.height)

        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let bookmark = sectionBookmarks[sections[indexPath.section]]?[indexPath.row] else {
            return 0.0
        }

        let cleanString = bookmark.title ?? "Untitled Bookmark"
        let text = NSMutableAttributedString(string: cleanString)
        let range = NSRange(location: 0, length: text.length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        text.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: range)
        text.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Avenir-Light", size: 16)!, range: range)

        let s = text.boundingRect(with: CGSize(width: view.frame.width-40, height: CGFloat.greatestFiniteMagnitude),
                                  options: [NSStringDrawingOptions.usesLineFragmentOrigin, NSStringDrawingOptions.usesFontLeading],
                                  context: nil)

        let totalHeight = s.size.height + 66
        
        return totalHeight
    }
    
    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookmark = sectionBookmarks[sections[indexPath.section]]?[indexPath.row],
              let pos = bookmark.pos else {
            return
        }
        guard let readerCenter = self.folioReader.readerCenter else { return }
        
        if let error = readerCenter.bookmarkErrors[pos] {
            presentLocatingBookmarkError(error, bookmark: bookmark, at: indexPath)
        } else {
            readerCenter.currentPage?.pushNavigateWebViewScrollPositions()
            
            readerCenter.changePageWith(page: bookmark.page, andFragment: pos)
            self.dismiss()
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let bookmark = sectionBookmarks[sections[indexPath.section]]?[indexPath.row], let pos = bookmark.pos else {
                return
            }

            folioReader.delegate?.folioReaderBookmarkProvider?(self.folioReader).folioReaderBookmark(folioReader, removed: pos)
            
            sectionBookmarks[sections[indexPath.section]]?.remove(at: indexPath.row)
            if sectionBookmarks[sections[indexPath.section]]?.isEmpty == true {
                sectionBookmarks.removeValue(forKey: sections[indexPath.section])
                sections.remove(at: indexPath.section)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    // MARK: - Handle rotation transition
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    func presentLocatingBookmarkError(_ message: String, bookmark: FolioReaderBookmark, at: IndexPath) {
        let textView = UITextView()
        textView.text = message
        
        let vc = UIViewController()
        vc.view = textView
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        let alert = UIAlertController(title: "Cannot Find", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alert.dismiss()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func presentLocatingBookmarkFailure(_ message: String, bookmark: FolioReaderBookmark, at: IndexPath) {
        let textView = UITextView()
        textView.text = message
        
        let vc = UIViewController()
        vc.view = textView
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        let alert = UIAlertController(title: "Cannot Fix", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alert.dismiss()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func presentAddingBookmarkFailure(_ message: String) {
        
        let alert = UIAlertController(title: "Cannot Add Bookmark", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alert.dismiss()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func addBookmark(completion: (() -> Void)? = nil) {
        guard let currentPage = self.folioReader.readerCenter?.currentPage,
              let provider = self.folioReader.delegate?.folioReaderBookmarkProvider?(self.folioReader)
        else {
            completion?()
            return
        }
        
        currentPage.getWebViewScrollPosition { position in
            let bookmark = FolioReaderBookmark()
            bookmark.pos_type = "epubcfi"
            bookmark.page = currentPage.pageNumber
            bookmark.pos = position.cfi
            bookmark.bookId = self.readerConfig.identifier
            bookmark.title = "[\(position.chapterName)] \(position.snippet.prefix(32))..."
            bookmark.date = Date()
            
            provider.folioReaderBookmark(self.folioReader, added: bookmark) { error in
                if let error = error {
                    var message = "Unknown Error"
                    switch error as! FolioReaderBookmarkError {
                    case .emptyError(_):
                        message = "Cannot generate location marker"
                    case .duplicateError(let msg):
                        message = "There exists a bookmark with the same location with title \(msg)"
                    case .runtimeError(let msg):
                        message = msg
                    }
                    self.presentAddingBookmarkFailure(message)
                } else {
                    self.loadSections()
                    self.addingBookmarkPos = bookmark.pos
                    
                    self.tableView.reloadData()
                }
                
                completion?()
            }
        }
    }
    
    @objc func saveBookmarkTitleAction(_ sender: UIButton) {
        guard let editingPos = addingBookmarkPos ?? editingBookmarkPos else { return }
        
        guard let cellContentView = sender.superview,
              let editView = cellContentView.viewWithTag(1234) as? UITextField,
              let title = editView.text else { return }
        
        guard let provider = self.folioReader.delegate?.folioReaderBookmarkProvider?(self.folioReader) else { return }
        
        provider.folioReaderBookmark(self.folioReader, updated: editingPos, title: title)
        
        addingBookmarkPos = nil
        editingBookmarkPos = nil
        
        
        (cellContentView.viewWithTag(123) as? UILabel)?.text = title
        (cellContentView.viewWithTag(123) as? UILabel)?.backgroundColor = .clear
        cellContentView.viewWithTag(1234)?.isHidden = true
        cellContentView.viewWithTag(1234)?.resignFirstResponder()
        cellContentView.viewWithTag(987)?.isHidden = true
    }
}
