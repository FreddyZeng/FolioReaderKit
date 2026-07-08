//
//  FolioReaderNavigationController.swift
//  FolioReaderKit
//
//  Created by DeepMind Antigravity on 7/3/26.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import UIKit

open class FolioReaderNavigationController: UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return visibleViewController?.preferredStatusBarStyle ?? .default
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return visibleViewController?.supportedInterfaceOrientations ?? .all
    }
    
    open override var shouldAutorotate: Bool {
        return visibleViewController?.shouldAutorotate ?? false
    }
}
