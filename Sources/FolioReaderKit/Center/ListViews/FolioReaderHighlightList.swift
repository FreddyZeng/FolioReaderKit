//
//  FolioReaderHighlightList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 01/09/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderHighlightList: UITableViewController {

//    fileprivate var highlights = [Highlight]()
    fileprivate var sections = [Int]()
    fileprivate var sectionHighlights = [Int: [FolioReaderHighlight]]()
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

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

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
//        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: kReuseHeaderFooterIdentifier)
        
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)
        
        guard let readerCenter = self.folioReader.readerCenter,
              let book = self.folioReader.readerContainer?.book,
              let bookId = (book.name as NSString?)?.deletingPathExtension,
              let highlights = self.folioReader.delegate?.folioReaderHighlightProvider?(self.folioReader).folioReaderHighlight(self.folioReader, allByBookId: bookId, andPage: nil)
        else {
            return
        }

        let currentPageNumber = readerCenter.currentPageNumber
        let currentPagePosition = readerCenter.currentWebViewScrollPositions[currentPageNumber - 1]
        let bookRootIndex = readerCenter.book.bundleRootTableOfContents.firstIndex(where: {
            $0.resource?.spineIndices.contains((currentPagePosition?.structuralRootPageNumber ?? 0) - 1) == true
        })
        
        sectionHighlights = highlights.filter({
            guard self.folioReader.structuralStyle == .bundle,
                  let bookRootIndex = bookRootIndex,
                  let firstSpineIndex = book.bundleRootTableOfContents[bookRootIndex].resource?.spineIndices.first,
                  let lastSpineIndex = book.bundleRootTableOfContents[safe: bookRootIndex + 1]?.resource?.spineIndices.first
            else { return true }
            
            return $0.page > firstSpineIndex && ($0.page-1) < lastSpineIndex
        }).reduce(into: sectionHighlights) { partialResult, highlight in
            if partialResult[highlight.page] != nil {
                partialResult[highlight.page]?.append(highlight)
                partialResult[highlight.page]?.sort(by: { $0.cfiStart < $1.cfiStart })
            } else {
                partialResult[highlight.page] = [highlight]
            }
        }
        sections = sectionHighlights.keys.sorted()
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionHighlights[sections[section]]?.count ?? 0
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

        guard let highlight = sectionHighlights[sections[indexPath.section]]?[indexPath.row] else {
            return cell
        }

        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.readerConfig.localizedHighlightsDateFormat
        let dateString = dateFormatter.string(from: highlight.date)

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
        
        if let _ = self.folioReader.readerCenter?.highlightErrors[highlight.highlightId] {
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
        let cleanString = highlight.content.stripHtml().truncate(250, trailing: "...").stripLineBreaks()
        let text = NSMutableAttributedString(string: cleanString)
        let range = NSRange(location: 0, length: text.length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        let textColor = self.folioReader.isNight(self.readerConfig.menuTextColor, UIColor.black)

        text.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: range)
        text.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Avenir-Light", size: 16)!, range: range)
        text.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: range)

        if (highlight.type == FolioReaderHighlightStyle.underline.rawValue) {
            text.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.clear, range: range)
            text.addAttribute(NSAttributedString.Key.underlineColor, value: FolioReaderHighlightStyle.colorForStyle(highlight.type, nightMode: self.folioReader.nightMode), range: range)
            text.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber(value: NSUnderlineStyle.single.rawValue as Int), range: range)
        } else {
            text.addAttribute(NSAttributedString.Key.backgroundColor, value: FolioReaderHighlightStyle.colorForStyle(highlight.type, nightMode: self.folioReader.nightMode), range: range)
        }

        // Text
        var highlightLabel: UILabel!
        if cell.contentView.viewWithTag(123) == nil {
            highlightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 0))
            highlightLabel.tag = 123
            highlightLabel.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
            highlightLabel.numberOfLines = 0
            highlightLabel.textColor = UIColor.black
            cell.contentView.addSubview(highlightLabel)
        } else {
            highlightLabel = cell.contentView.viewWithTag(123) as? UILabel
        }

        highlightLabel.attributedText = text
        highlightLabel.sizeToFit()
        highlightLabel.frame = CGRect(x: 20, y: 46, width: view.frame.width-40, height: highlightLabel.frame.height)
        
        // Note text if it exists
        if let note = highlight.noteForHighlight {
            var noteLabel: UILabel!
            if cell.contentView.viewWithTag(789) == nil {
                noteLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 0))
                noteLabel.tag = 789
                noteLabel.font = UIFont.systemFont(ofSize: 14)
                noteLabel.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
                noteLabel.numberOfLines = 3
                noteLabel.textColor = UIColor.gray
                cell.contentView.addSubview(noteLabel)
            } else {
                noteLabel = cell.contentView.viewWithTag(789) as? UILabel
            }
            
            noteLabel.text = note
            noteLabel.sizeToFit()
            noteLabel.frame = CGRect(x: 20, y: 46 + highlightLabel.frame.height + 10, width: view.frame.width-40, height: noteLabel.frame.height)
        } else {
            cell.contentView.viewWithTag(789)?.removeFromSuperview()
        }

        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let highlight = sectionHighlights[sections[indexPath.section]]?[indexPath.row] else {
            return 0.0
        }

        let cleanString = highlight.content.stripHtml().truncate(250, trailing: "...").stripLineBreaks()
        let text = NSMutableAttributedString(string: cleanString)
        let range = NSRange(location: 0, length: text.length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        text.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: range)
        text.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Avenir-Light", size: 16)!, range: range)

        let s = text.boundingRect(with: CGSize(width: view.frame.width-40, height: CGFloat.greatestFiniteMagnitude),
                                  options: [NSStringDrawingOptions.usesLineFragmentOrigin, NSStringDrawingOptions.usesFontLeading],
                                  context: nil)

        var totalHeight = s.size.height + 66
        
        if let note = highlight.noteForHighlight {
            let noteLabel = UILabel()
            noteLabel.frame = CGRect(x: 20, y: 46 , width: view.frame.width-40, height: CGFloat.greatestFiniteMagnitude)
            noteLabel.text = note
            noteLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            noteLabel.numberOfLines = 0
            noteLabel.font = UIFont.systemFont(ofSize: 14)
            
            noteLabel.sizeToFit()
            totalHeight += noteLabel.frame.height
        }

        return totalHeight
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let highlight = sectionHighlights[sections[indexPath.section]]?[indexPath.row] else {
            return
        }
        guard let readerCenter = self.folioReader.readerCenter else { return }
        
        if let error = readerCenter.highlightErrors[highlight.highlightId] {
            presentLocatingHighlightError(error, highlight: highlight, at: indexPath)
        } else {
            readerCenter.currentPage?.pushNavigateWebViewScrollPositions()
            
            readerCenter.changePageWith(page: highlight.page, andFragment: highlight.highlightId)
            self.dismiss()
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let highlight = sectionHighlights[sections[indexPath.section]]?[indexPath.row] else {
                return
            }

            if (highlight.page == self.folioReader.readerCenter?.currentPageNumber),
                let page = self.folioReader.readerCenter?.currentPage {
                FolioReaderHighlight.removeFromHTMLById(withinPage: page, highlightId: highlight.highlightId) // Remove from HTML
            }

            folioReader.delegate?.folioReaderHighlightProvider?(self.folioReader).folioReaderHighlight(folioReader, removedId: highlight.highlightId)
            
            sectionHighlights[sections[indexPath.section]]?.remove(at: indexPath.row)
            if sectionHighlights[sections[indexPath.section]]?.isEmpty == true {
                sectionHighlights.removeValue(forKey: sections[indexPath.section])
                sections.remove(at: indexPath.section)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    // MARK: - Handle rotation transition
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    func presentLocatingHighlightError(_ message: String, highlight: FolioReaderHighlight, at: IndexPath) {
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
        alert.addAction(UIAlertAction(title: "Fix", style: .default, handler: { (action) in
            alert.dismiss()
            
            self.folioReader.readerCenter?.currentPage?.relocateHighlights(highlight: highlight, completion: { newHighlight, error in
                guard error == nil else {
                    self.presentLocatingHighlightFailure("\(error!)", highlight: newHighlight ?? highlight, at: at)
                    return
                }
                
                self.tableView.reloadRows(at: [at], with: .automatic)
                
                self.tableView(self.tableView, didSelectRowAt: at)
            })
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func presentLocatingHighlightFailure(_ message: String, highlight: FolioReaderHighlight, at: IndexPath) {
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
}
