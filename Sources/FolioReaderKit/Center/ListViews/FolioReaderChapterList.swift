//
//  FolioReaderChapterList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

/// Table Of Contents delegate
@objc protocol FolioReaderChapterListDelegate: AnyObject {
    /**
     Notifies when the user selected some item on menu.
     */
    func chapterList(_ chapterList: FolioReaderChapterList, didSelectRowAtIndexPath indexPath: IndexPath, withTocReference reference: FRTocReference)

    /**
     Notifies when chapter list did totally dismissed.
     */
    func chapterList(didDismissedChapterList chapterList: FolioReaderChapterList)
}

class FolioReaderChapterList: UITableViewController {

    weak var delegate: FolioReaderChapterListDelegate?
    fileprivate var tocItems = [FRTocReference]()
    fileprivate var book: FRBook
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader
    fileprivate var highlightResourceIds = Set<String>()

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig, book: FRBook, delegate: FolioReaderChapterListDelegate?) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader
        self.delegate = delegate
        self.book = book

        super.init(style: UITableView.Style.plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init with coder not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.tableView.register(FolioReaderChapterListCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
        self.tableView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        self.tableView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 50

        // Create TOC list
        if self.folioReader.structuralStyle == .bundle {
            guard let tocList = self.folioReader.readerCenter?.currentPage?.getChapterTocReferences(for: .zero, by: .zero).compactMap({ $0.resource?.id }) else { return }
            let tocSet = Set<String>(tocList)
            let tocLevel = self.folioReader.structuralTrackingTocLevel.rawValue
            self.tocItems = self.book.flatTableOfContents.filter {
                var toc: FRTocReference? = $0
                if (toc?.level ?? 0) < tocLevel {
                    return false
                }
                while( toc != nil && (toc?.level ?? 0) >= (tocLevel-1) ) {
                    if let id = toc?.resource?.id, tocSet.contains(id) {
                        return true
                    }
                    toc = toc?.parent
                }
                return false
            }
        } else {
            self.tocItems = self.book.flatTableOfContents
        }
        
      
        // Jump to the current chapter
        DispatchQueue.main.async {
            guard let index = self.tocItems.firstIndex(where: { self.highlightResourceIds.contains($0.resource?.id ?? "___NIL___") }) else { return }
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        highlightResourceIds.removeAll()
        
        guard var pageNumber = self.folioReader.readerCenter?.currentPageNumber else { return }
        
        while( pageNumber > 0 ) {
            guard let reference = self.book.spine.spineReferences[safe: pageNumber - 1] else { return }
            if let tocReferences = self.book.resourceTocMap[reference.resource] {
                tocReferences.forEach {
                    guard let id = $0.resource?.id else { return }
                    highlightResourceIds.insert(id)
                }
                break
            } else {
                pageNumber -= 1
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Jump to the current chapter
        DispatchQueue.main.async {
            guard let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber,
                  let reference = self.book.spine.spineReferences[safe: currentPageNumber - 1],
                  let index = self.tocItems.firstIndex(where: { $0.resource == reference.resource })
            else { return }
            
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tocItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath) as! FolioReaderChapterListCell

        cell.setup(withConfiguration: self.readerConfig)
        let tocReference = tocItems[indexPath.row]
        let isSection = tocReference.children.count > 0

        let indentCount = max(0, (tocReference.level ?? 0) - self.folioReader.structuralTrackingTocLevel.rawValue)
        cell.indexLabel?.text = Array.init(repeating: " ", count: indentCount * 2).joined() + tocReference.title.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add audio duration for Media Ovelay
        if let resource = tocReference.resource {
            if let mediaOverlay = resource.mediaOverlay {
                let duration = self.book.duration(for: "#"+mediaOverlay)

                if let durationFormatted = (duration != nil ? duration : "")?.clockTimeToMinutesString() {
                    cell.indexLabel?.text = (cell.indexLabel?.text ?? "") + (duration != nil ? (" - " + durationFormatted) : "")
                }
            }
        }

        // Mark current reading chapter
        cell.indexLabel?.textColor = highlightResourceIds.contains(tocReference.resource?.id ?? "___NIL___") ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor
        cell.indexLabel?.font = UIFont(name: "Avenir-Light", size: 17.0 - CGFloat(indentCount) * 1.5)

        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.backgroundColor = isSection ? UIColor(white: 0.7, alpha: 0.1) : UIColor.clear
        cell.backgroundColor = UIColor.clear
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tocReference = tocItems[(indexPath as NSIndexPath).row]
        delegate?.chapterList(self, didSelectRowAtIndexPath: indexPath, withTocReference: tocReference)
        
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss { 
            self.delegate?.chapterList(didDismissedChapterList: self)
        }
    }
}
