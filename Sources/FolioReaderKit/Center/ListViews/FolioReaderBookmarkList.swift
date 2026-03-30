//
//  FolioReaderBookmarkList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 01/09/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderBookmarkList: UITableViewController {

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

    func loadSections() {
        guard let readerCenter = self.folioReader.readerCenter,
              let book = self.folioReader.readerContainer?.book,
              let bookId = (book.name as NSString?)?.deletingPathExtension,
              let bookmarks = self.folioReader.delegate?.folioReaderBookmarkProvider?(self.folioReader).folioReaderBookmark(self.folioReader, allByBookId: bookId, andPage: nil)
        else {
            return
        }

        let currentPageNumber = readerCenter.currentPageNumber
        let currentPagePosition = readerCenter.currentWebViewScrollPositions[currentPageNumber - 1]
        let bookRootIndex = readerCenter.book.bundleRootTableOfContents.firstIndex(where: {
            $0.resource?.spineIndices.contains((currentPagePosition?.structuralRootPageNumber ?? 0) - 1) == true
        })
        
        sectionBookmarks = bookmarks.filter({
            guard self.folioReader.structuralStyle == .bundle,
                  let bookRootIndex = bookRootIndex,
                  let firstSpineIndex = book.bundleRootTableOfContents[bookRootIndex].resource?.spineIndices.first,
                  let lastSpineIndex = book.bundleRootTableOfContents[safe: bookRootIndex + 1]?.resource?.spineIndices.first
            else { return true }
            
            return $0.page > firstSpineIndex && ($0.page-1) < lastSpineIndex
        }).reduce(into: [:]) { partialResult, bookmark in
            if partialResult[bookmark.page] != nil {
                partialResult[bookmark.page]?.append(bookmark)
                partialResult[bookmark.page]?.sort()
            } else {
                partialResult[bookmark.page] = [bookmark]
            }
        }
        sections = sectionBookmarks.keys.sorted()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Jump to the current chapter
        DispatchQueue.main.async {
            guard let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber,
                  let sectionPageNumber = self.sections.filter({ $0 <= currentPageNumber }).last,
                  let section = self.sections.firstIndex(of: sectionPageNumber)
            else { return }
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true)
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
        var titleFrags = [String]()
        if let title = tocItem.title {
            titleFrags.append(title)
        }
        var parent = tocItem.parent
        while let item = parent {
            if self.folioReader.structuralStyle == .bundle,
               item.level < self.folioReader.structuralTrackingTocLevel.rawValue {
                break
            }
            if let title = item.title {
                titleFrags.append(title)
            }
            parent = item.parent
        }
        return "  " + titleFrags.reversed().joined(separator: ", ")
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
            bookmarkLabel.textColor = UIColor.black
            cell.contentView.addSubview(bookmarkLabel)
        } else {
            bookmarkLabel = cell.contentView.viewWithTag(123) as? UILabel
        }

        bookmarkLabel.text = bookmark.title
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
