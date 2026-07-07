//
//  PageViewController.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 14/07/16.
//  Copyright © 2016 FolioReader. All rights reserved.
//

import UIKit

class FolioReaderAnnotationPageVC: UIPageViewController {

    var segmentedControl: UISegmentedControl?
    var viewList = [UIViewController]()
    var segmentedControlItems = [String]()
    
    var viewControllerZero: UIViewController?
    var viewControllerOne: UIViewController?
    var viewControllerTwo: UIViewController?

    var index: Int
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

    // MARK: Init

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.folioReader = folioReader
        self.readerConfig = readerConfig
        self.index = self.folioReader.currentAnnotationMenuIndex
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = true
    }

    required init?(coder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let control = UISegmentedControl(items: segmentedControlItems)
        control.addTarget(self, action: #selector(FolioReaderAnnotationPageVC.didSwitchMenu(_:)), for: UIControl.Event.valueChanged)
        control.selectedSegmentIndex = index
        self.navigationItem.titleView = control
        segmentedControl = control

        var tempViewList = [UIViewController]()
        if let vc1 = viewControllerOne {
            tempViewList.append(vc1)
            vc1.didMove(toParent: self)
        }
        if let vc2 = viewControllerTwo {
            tempViewList.append(vc2)
            vc2.didMove(toParent: self)
        }
        
        if (self.folioReader.readerCenter?.tempRefText) != nil, let vc0 = viewControllerZero {
            tempViewList.insert(vc0, at: 0)
            vc0.didMove(toParent: self)
        }
        viewList = tempViewList

        self.delegate = self
        self.dataSource = self

        let backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.view.backgroundColor = backgroundColor

        for view in self.view.subviews {
            view.backgroundColor = backgroundColor
            if let scrollView = view as? UIScrollView {
                scrollView.backgroundColor = backgroundColor
                scrollView.bounces = false
            }
        }

        if index >= viewList.count {
            index = 0
        }
        self.setViewControllers([viewList[index]], direction: .forward, animated: false, completion: nil)

        self.setCloseButton(withConfiguration: self.readerConfig, folioReader: self.folioReader)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavBar()
        
        if let vc1 = viewControllerOne, self.index == viewList.firstIndex(of: vc1) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addBookmark(_:)))
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func configureNavBar() {
        //let navBackground = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.daysModeNavBackground)
        let navBackground = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        let tintColor = self.readerConfig.tintColor
        let navText = self.readerConfig.themeModeTextColor[self.folioReader.themeMode]
        let font = UIFont(name: "Avenir-Light", size: 17) ?? .systemFont(ofSize: 17)
        setTranslucentNavigation(false, color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
        
        segmentedControl?.selectedSegmentTintColor = tintColor
        segmentedControl?.setTitleTextAttributes([.foregroundColor: self.readerConfig.themeModeTextColor[self.folioReader.themeMode]], for: .selected)
        segmentedControl?.setTitleTextAttributes([.foregroundColor: navText.withAlphaComponent(0.7)], for: .normal)
    }

    // MARK: - Segmented control changes

    @objc func didSwitchMenu(_ sender: UISegmentedControl) {
        let direction: UIPageViewController.NavigationDirection = (index > sender.selectedSegmentIndex ? .reverse : .forward)
        self.index = sender.selectedSegmentIndex
        setViewControllers([viewList[index]], direction: direction, animated: true, completion: nil)
        self.folioReader.currentAnnotationMenuIndex = index
        
        if let vc1 = viewControllerOne, self.index == viewList.firstIndex(of: vc1) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addBookmark(_:)))
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    // MARK: - Status Bar

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.folioReader.isNight(.lightContent, .default)
    }
    
    // MARK: - NavBar Button
    
    @objc func addBookmark(_ sender: UIBarButtonItem) {
        FolioLogger.log("bookmark")
        
        guard let bookmarkList = self.viewControllerOne as? FolioReaderBookmarkList else { return }
        
        sender.isEnabled = false
        bookmarkList.addBookmark() {
            sender.isEnabled = true
        }
        
    }
}

// MARK: UIPageViewControllerDelegate

extension FolioReaderAnnotationPageVC: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        if finished && completed {
            if let viewController = pageViewController.viewControllers?.last,
               let idx = viewList.firstIndex(of: viewController) {
                segmentedControl?.selectedSegmentIndex = idx
            }
        }
    }
}

// MARK: UIPageViewControllerDataSource

extension FolioReaderAnnotationPageVC: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        let index = viewList.firstIndex(of: viewController)!
        if index == viewList.count - 1 {
            return nil
        }

        self.index = self.index + 1
        return viewList[self.index]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        let index = viewList.firstIndex(of: viewController)!
        if index == 0 {
            return nil
        }

        self.index = self.index - 1
        return viewList[self.index]
    }
}

