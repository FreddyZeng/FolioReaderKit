//
//  FolioReaderHistoryList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FolioEPUBCore

/// Table Of Contents delegate
@objc protocol FolioReaderHistoryListDelegate: AnyObject {
    /**
     Notifies when the user selected some item on menu.
     */
    func historyList(_ HistoryList: FolioReaderHistoryList, didSelectRowAtIndexPath indexPath: IndexPath)

    /**
     Notifies when History list did totally dismissed.
     */
    func historyList(didDismissedHistoryList HistoryList: FolioReaderHistoryList)
}



class FolioReaderHistoryList: UITableViewController {

    weak var delegate: FolioReaderHistoryListDelegate?
    fileprivate var book: FRBook
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader
    var historyList = [FolioReaderReadPositionHistory]()
    
    init(folioReader: FolioReader, readerConfig: FolioReaderConfig, book: FRBook, delegate: FolioReaderHistoryListDelegate?) {
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
        self.tableView.register(FolioReaderHistoryListCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
        self.tableView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        self.tableView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 50

        if let bookId = readerConfig.identifier,
           let historyList = folioReader.delegate?.folioReaderReadPositionProvider?(folioReader).folioReaderPositionHistory(folioReader, bookId: bookId) {
            self.historyList = historyList.filter({ $0.endPosition != nil }).sorted(by: { $0.startDatetime > $1.startDatetime })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath) as! FolioReaderHistoryListCell

        cell.setup(withConfiguration: self.readerConfig)
        
        let history = historyList[indexPath.row]
        
        if let endPosition = history.endPosition {
            cell.indexToc.text = endPosition.chapterName
            cell.setSpineDate(history.startDatetime)
            cell.setLabelDate(endPosition.epoch)
            cell.setPercentValue(endPosition.chapterProgress / 100.0)
        }
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = UIColor.clear
        
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.historyList(self, didSelectRowAtIndexPath: indexPath)
        
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss { 
            self.delegate?.historyList(didDismissedHistoryList: self)
        }
    }
}
