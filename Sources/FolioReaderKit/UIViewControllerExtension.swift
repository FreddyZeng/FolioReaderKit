//
//  UIViewControllerExtension.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import UIKit

internal extension UIViewController {
    
    func setCloseButton(withConfiguration readerConfig: FolioReaderConfig) {
        let closeImage = UIImage(readerImageNamed: "icon-navbar-close")?.ignoreSystemTint(withConfiguration: readerConfig)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(dismiss as () -> Void))
    }
    
    @objc func dismiss() {
        self.dismiss(nil)
    }
    
    func dismiss(_ completion: (() -> Void)?) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: {
                completion?()
            })
        }
    }
    
    // MARK: - NavigationBar
    
    func setTransparentNavigation() {
        let navBar = self.navigationController?.navigationBar
        navBar?.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar?.isHidden = true
        navBar?.isTranslucent = true
    }
    
    func setTranslucentNavigation(_ translucent: Bool = true, color: UIColor, tintColor: UIColor = UIColor.white, titleColor: UIColor = UIColor.black, andFont font: UIFont = UIFont.systemFont(ofSize: 17)) {
        let navBar = self.navigationController?.navigationBar

        let appearance = UINavigationBarAppearance()
        if translucent {
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = color.withAlphaComponent(0.5)
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
        }
        appearance.titleTextAttributes = [.foregroundColor: titleColor, .font: font]

        navBar?.standardAppearance = appearance
        navBar?.scrollEdgeAppearance = appearance
        navBar?.compactAppearance = appearance

        navBar?.isHidden = false
        navBar?.isTranslucent = translucent
        navBar?.tintColor = tintColor
    }
}

/**
 Fix for Swift 4 / iOS 12
 https://stackoverflow.com/questions/34452920/removing-the-hairline-under-navigation-bar
 */
func findHairlineImageViewUnderView(view: UIView?) -> UIImageView? {
    guard let view = view else { return nil }
    if view.isKind(of: UIImageView.classForCoder()) && view.bounds.height <= 1 {
        return view as? UIImageView
    }
    for subView in view.subviews {
        if let imageView = findHairlineImageViewUnderView(view: subView) {
            return imageView
        }
    }
    return nil
}
