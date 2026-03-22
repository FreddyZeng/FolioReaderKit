//
//  FolioReaderAnchorPreview.swift
//  FolioReaderKit
//
//  Created by Peter on 2022/8/26.
//

import Foundation
import SwiftSoup
import UIKit

class FolioReaderAnchorPreview: UIViewController {
    let folioReader: FolioReader
    let anchorURL: URL
    let anchorOffset: CGFloat
    let anchorBounds: CGRect
    
    let navBar = UIView()
    
    let gotoButton = UIButton()
    let expandButton = UIButton()
    let closeButton = UIButton()
    
    let anchorLabel = UITextView()
    
    let anchorBackgroundView = UIView()
    
    let tapGeatureRecognizer = UITapGestureRecognizer()
    
    var normalConstraints = [NSLayoutConstraint]()
    var expandConstraints = [NSLayoutConstraint]()
    
    let snippetTestRegex = try? NSRegularExpression(pattern: "^\\[\\d+\\]$")
    
    public init(_ folioReader: FolioReader, _ anchorURL: URL, _ anchorOffset: CGFloat, _ anchorBounds: CGRect) {
        self.folioReader = folioReader
        self.anchorURL = anchorURL
        self.anchorOffset = anchorOffset
        self.anchorBounds = anchorBounds
        
        super.init(nibName: nil, bundle: Bundle.frameworkBundle())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.view.insetsLayoutMarginsFromSafeArea = false
        
        self.view.backgroundColor = .init(white: 0.2, alpha: 0.2)
        
        anchorBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        anchorBackgroundView.backgroundColor = folioReader.readerConfig?.themeModeNavBackground[folioReader.themeMode]
        anchorBackgroundView.layer.borderColor = folioReader.readerConfig?.themeModeTextColor[folioReader.themeMode].cgColor
        anchorBackgroundView.layer.borderWidth = 1.5
        anchorBackgroundView.layer.cornerRadius = 12
        
        self.view.addSubview(anchorBackgroundView)
        
        let frameHeight = anchorBounds.height / 3
        let frameOffset = anchorBounds.minY + min(anchorBounds.height - frameHeight - 16, anchorOffset + 32)
        normalConstraints.append(contentsOf: [
            anchorBackgroundView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: frameOffset),
            anchorBackgroundView.heightAnchor.constraint(equalToConstant: frameHeight)
        ])
        var headMargin = CGFloat(16)
        var sideMargin = CGFloat(8)
        if anchorBounds.height > anchorBounds.width * 1.5 {
            headMargin *= 2
        }
        if anchorBounds.width > anchorBounds.height {
            sideMargin *= 2
        }
        expandConstraints.append(contentsOf: [
            anchorBackgroundView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: anchorBounds.minY + headMargin),
            anchorBackgroundView.heightAnchor.constraint(equalToConstant: anchorBounds.height - headMargin * 2)
        ])
        
        NSLayoutConstraint.activate([
            anchorBackgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: anchorBounds.minX + sideMargin),
            anchorBackgroundView.widthAnchor.constraint(equalToConstant: anchorBounds.width - sideMargin * 2)
        ])
        NSLayoutConstraint.activate(normalConstraints)
        
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.layer.cornerRadius = 4
        navBar.layer.borderColor = UIColor(white: 0.5, alpha: 0.2).cgColor
        navBar.layer.borderWidth = 1
        
        self.view.addSubview(navBar)
        
        NSLayoutConstraint.activate([
            navBar.leadingAnchor.constraint(equalTo: self.anchorBackgroundView.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: self.anchorBackgroundView.trailingAnchor),
            navBar.topAnchor.constraint(equalTo: self.anchorBackgroundView.topAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        anchorLabel.translatesAutoresizingMaskIntoConstraints = false
        anchorLabel.isEditable = false
        anchorLabel.backgroundColor = .clear
        
        self.view.addSubview(anchorLabel)
        
        NSLayoutConstraint.activate([
            anchorLabel.leadingAnchor.constraint(equalTo: self.anchorBackgroundView.leadingAnchor, constant: 8),
            anchorLabel.trailingAnchor.constraint(equalTo: self.anchorBackgroundView.trailingAnchor, constant: -8),
            anchorLabel.topAnchor.constraint(equalTo: self.navBar.bottomAnchor),
            anchorLabel.bottomAnchor.constraint(equalTo: self.anchorBackgroundView.bottomAnchor, constant: -10)
        ])
        
        gotoButton.translatesAutoresizingMaskIntoConstraints = false
        gotoButton.setTitle("Jump", for: .normal)
        gotoButton.setTitleColor(folioReader.readerConfig?.tintColor, for: .normal)
        gotoButton.addTarget(self, action: #selector(gotoButtonAction(_:)), for: .primaryActionTriggered)
        
        navBar.addSubview(gotoButton)
        
        NSLayoutConstraint.activate([
            gotoButton.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -8),
            gotoButton.widthAnchor.constraint(equalToConstant: 60),
            gotoButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            gotoButton.heightAnchor.constraint(equalTo: navBar.heightAnchor)
        ])
        
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.setTitle("Expand", for: .normal)
        expandButton.setTitleColor(folioReader.readerConfig?.tintColor, for: .normal)
        expandButton.addTarget(self, action: #selector(expandButtonAction(_:)), for: .primaryActionTriggered)
        
        navBar.addSubview(expandButton)
        
        NSLayoutConstraint.activate([
            expandButton.trailingAnchor.constraint(equalTo: gotoButton.leadingAnchor, constant: -8),
            expandButton.widthAnchor.constraint(equalToConstant: 60),
            expandButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            expandButton.heightAnchor.constraint(equalTo: navBar.heightAnchor)
        ])
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(folioReader.readerConfig?.tintColor, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonAction(_:)), for: .primaryActionTriggered)
        
        navBar.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            closeButton.heightAnchor.constraint(equalTo: navBar.heightAnchor)
        ])
        
        tapGeatureRecognizer.addTarget(self, action: #selector(tapGesture(_:)))
        
        self.view.addGestureRecognizer(tapGeatureRecognizer)
        
        anchorLabel.text = "Before Locating"
        
        let entryPath = anchorURL.pathComponents.dropFirst(2).joined(separator: "/")
        var entryData = Data()
        
        guard let fragment = anchorURL.fragment,
              let archive = folioReader.readerContainer?.book.epubArchive,
              let entry = archive[entryPath],
              let _ = try? archive.extract(entry, consumer: { entryData.append($0) }),
              let xmlString = String(data: entryData, encoding: .utf8),
              let soupDoc = try? SwiftSoup.parse(xmlString),
              let soupElement = try? soupDoc.getElementById(fragment),
              var snippet = try? soupElement.text(trimAndNormaliseWhitespace: true)
        else { return }
        
        if snippet.isEmpty
            || (snippetTestRegex?.matches(in: snippet, options: [], range: NSMakeRange(0, snippet.count)).isEmpty == false) {
            var elements = [soupElement as Node]
            while let sibling = elements.last?.nextSibling() {
                guard sibling.hasAttr("id") == false else { break }
                if let element = sibling as? Element,
                   let elementsWithID = try? element.getElementsByAttribute("id"),
                   elementsWithID.count > 0 {
                    break
                }
                elements.append(sibling)
            }
            
            snippet = elements.compactMap({ node -> String? in
                if let element = node as? Element {
                    return try? element.text(trimAndNormaliseWhitespace: true)
                }
                if let textNode = node as? TextNode {
                    return textNode.text()
                }
                return nil
            }).joined(separator: " ")
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        
        var attributes: [NSAttributedString.Key : Any] = [.paragraphStyle: paragraphStyle]
        if let font = UIFont(name: folioReader.currentFont, size: CGFloat(folioReader.currentFontSizeOnly - 2)) {
            attributes[.font] = font
        }
        if let color = folioReader.readerConfig?.themeModeTextColor[folioReader.themeMode] {
            attributes[.foregroundColor] = color
        }
        
        let attribText = NSAttributedString(
            string: snippet.trimmingCharacters(in: .whitespacesAndNewlines),
            attributes: attributes
        )
        anchorLabel.attributedText = attribText
        //anchorLabel.sizeToFit()
    }
    
    @objc func gotoButtonAction(_ sender: UIButton) {
        let entryPath = anchorURL.pathComponents.dropFirst(2).joined(separator: "/")
        guard let readerCenter = folioReader.readerCenter,
              let spineIndex = readerCenter.book.spine.spineReferences.firstIndex(where: { entryPath.contains($0.resource.href) }),
              let fragment = anchorURL.fragment
        else { return }
        readerCenter.currentPage?.pushNavigateWebViewScrollPositions()
        readerCenter.changePageWith(page: spineIndex + 1, andFragment: fragment, animated: true) {
            self.dismiss()
        }
        
    }
    
    @objc func expandButtonAction(_ sender: UIButton) {
        if sender.title(for: .normal) == "Expand" {
            NSLayoutConstraint.deactivate(normalConstraints)
            NSLayoutConstraint.activate(expandConstraints)
            sender.setTitle("Shrink", for: .normal)
        } else if sender.title(for: .normal) == "Shrink" {
            NSLayoutConstraint.deactivate(expandConstraints)
            NSLayoutConstraint.activate(normalConstraints)
            sender.setTitle("Expand", for: .normal)
        }
    }
    
    @objc func closeButtonAction(_ sender: UIButton) {
        self.dismiss()
    }
    
    @objc func tapGesture(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        
        guard self.anchorBackgroundView.frame.contains(sender.location(in: self.view)) == false else { return }
        
        self.dismiss()
    }
}
