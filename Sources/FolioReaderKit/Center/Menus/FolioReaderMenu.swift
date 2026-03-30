//
//  FolioReaderMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation
import UIKit

class FolioReaderMenu: UIViewController, UIGestureRecognizerDelegate {
    public var menuView = UIView()
    
    var readerConfig: FolioReaderConfig
    var folioReader: FolioReader
    
    let segmentFont = UIFont(name: "Avenir-Light", size: 17)!
    let separaterTag = -9999
    
    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadColors() {
        let backgroundColor = self.readerConfig.themeModeBackground[self.folioReader.themeMode]
        let separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)
        menuView.backgroundColor = backgroundColor
        menuView.subviews.forEach { subview in
            if subview.tag == separaterTag {
                subview.backgroundColor = separatorColor
            } else {
                subview.backgroundColor = backgroundColor
            }
            if let label = subview as? UILabel,
               label.textColor != .systemRed {
                label.textColor = folioReader.isNight(UIColor.lightText, UIColor.darkText)
            }
            if let button = subview as? UIButton {
                button.setTitleColor(folioReader.isNight(UIColor.lightText, self.folioReader.readerConfig?.tintColor), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear
    }

    override func viewWillAppear(_ animated: Bool) {
        layoutSubviews(frame: self.view.frame)
        
        reloadColors()
    }
    
    func layoutSubviews(frame: CGRect) {
        preconditionFailure("This method must be overriden")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [weak self] context in
            self?.layoutSubviews(frame: CGRect(origin: .zero, size: size))
        } completion: { context in
            
        }
    }
}
