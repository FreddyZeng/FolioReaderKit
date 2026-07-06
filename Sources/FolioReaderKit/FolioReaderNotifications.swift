//
//  FolioReaderNotifications.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import Foundation

extension Notification.Name {
    /// Notification posted when the page mode (such as scroll direction) needs to be refreshed.
    public static let folioReaderNeedRefreshPageMode = Notification.Name("needRefreshPageMode")
}
