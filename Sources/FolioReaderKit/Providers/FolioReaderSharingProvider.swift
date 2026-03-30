//
//  FolioReaderSharingProvider.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 02/09/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

@MainActor
class FolioReaderSharingProvider: UIActivityItemProvider, @unchecked Sendable {
    let subject: String
    let text: String
    let html: String?
    let image: UIImage?

    static var AttribStringActivityTypes: Set<UIActivity.ActivityType> = [
        .init("com.google.Gmail.ShareExtension")
    ]
    
    static var HtmlActivityTypes: Set<UIActivity.ActivityType> = [
        .mail,
        .init("com.evernote.iPhone.Evernote.EvernoteShare")
    ]
    
    init(subject: String, text: String, html: String? = nil, image: UIImage? = nil) {
        self.subject = subject
        self.text = text
        self.html = html
        self.image = image

        super.init(placeholderItem: "")
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return subject
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let activityType = activityType else { return text }
        print("activityViewController \(activityType)")
        if let html = html,
           FolioReaderSharingProvider.AttribStringActivityTypes.contains(activityType),
           let data = html.data(using: .utf8),
           let attribString = try? NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        {
            return attribString
        }
        if let html = html,
           FolioReaderSharingProvider.HtmlActivityTypes.contains(activityType) {
            return html
        }

        if let image = image , activityType == UIActivity.ActivityType.postToFacebook {
            return image
        }

        return text
    }
}
