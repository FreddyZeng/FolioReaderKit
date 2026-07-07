//
//  FolioReaderResourceList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

/// Table Of Contents delegate
@objc protocol FolioReaderResourceListDelegate: AnyObject {
    /**
     Notifies when the user selected some item on menu.
     */
    func resourceList(_ resourceList: FolioReaderResourceList, didSelectRowAtIndexPath indexPath: IndexPath)

    /**
     Notifies when resource list did totally dismissed.
     */
    func resourceList(didDismissedResourceList resourceList: FolioReaderResourceList)
}

class FolioReaderResourceList: UITableViewController {

    weak var delegate: FolioReaderResourceListDelegate?
    fileprivate var book: FRBook
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig, book: FRBook, delegate: FolioReaderResourceListDelegate?) {
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
        self.tableView.register(FolioReaderResourceListCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
        self.tableView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        self.tableView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 50

        // Jump to the current resource
        DispatchQueue.main.async {
            if let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber {
                  let indexPath = IndexPath(row: currentPageNumber - 1, section: 0)
                  self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Jump to the current resource
        DispatchQueue.main.async {
            if let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber {
                  let indexPath = IndexPath(row: currentPageNumber - 1, section: 0)
                  self.tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return book.spine.spineReferences.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath) as! FolioReaderResourceListCell

        cell.setup(withConfiguration: self.readerConfig)
        let spineReference = book.spine.spineReferences[indexPath.row]

        cell.indexLabel.text = spineReference.resource.href
        let resHref = spineReference.resource.href
        if !resHref.isEmpty,
           let opfResource = self.book.opfResource,
           let opfUrl = URL(string: opfResource.href),
           let resUrl = URL(string: resHref, relativeTo: opfUrl) {
            cell.indexLabel.text = resUrl.absoluteString.replacingOccurrences(of: "//", with: "")
            while cell.indexLabel.text?.hasPrefix("/") == true {
                cell.indexLabel.text?.removeFirst()
            }
        }
        // Add audio duration for Media Ovelay
        if let mediaOverlay = spineReference.resource.mediaOverlay {
            let duration = self.book.duration(for: "#"+mediaOverlay)
            
            if let durationFormatted = (duration != nil ? duration : "")?.clockTimeToMinutesString() {
                cell.indexLabel.text = (cell.indexLabel.text ?? "") + (duration != nil ? (" - " + durationFormatted) : "")
            }
        }

        // Mark current reading resource
        cell.indexLabel.textColor = (indexPath.row + 1 == self.folioReader.readerCenter?.currentPageNumber ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor)
        cell.indexLabel.font = UIFont(name: "Avenir-Light", size: 11.0)

        if let tocList = self.book.resourceTocMap[spineReference.resource] {
            var tocTitles = tocList.map { $0.title }.prefix(3)
            if tocList.count > 3 {
                tocTitles.append("...")
                tocTitles.append(tocList.last!.title)
            }
            cell.indexToc.text = tocTitles.joined(separator: ", ")
        } else {
            cell.indexToc.text = "No ToC Defined"
        }
        cell.indexToc.textColor = (indexPath.row + 1 == self.folioReader.readerCenter?.currentPageNumber ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor)
        cell.indexToc.font = UIFont(name: "Avenir-Light", size: 15.0)
        
        cell.indexSize.text = ByteCountFormatter.string(fromByteCount: Int64(spineReference.resource.size ?? 0), countStyle: .file)
        cell.indexSize.textColor = (indexPath.row + 1 == self.folioReader.readerCenter?.currentPageNumber ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor)
        cell.indexSize.font = UIFont(name: "Avenir-Light", size: 11.0)

        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 3
        
        cell.indexSpine.text = "Index " + (formatter.string(from: NSNumber(value: indexPath.row)) ?? "N/A")
        cell.indexSpine.textColor = (indexPath.row + 1 == self.folioReader.readerCenter?.currentPageNumber ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor)
        cell.indexSpine.font = UIFont(name: "Avenir-Light", size: 13.0)
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = UIColor.clear
        
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.resourceList(self, didSelectRowAtIndexPath: indexPath)
        
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss { 
            self.delegate?.resourceList(didDismissedResourceList: self)
        }
    }
}
