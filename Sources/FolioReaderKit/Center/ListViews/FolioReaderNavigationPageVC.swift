//
//  PageViewController.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 14/07/16.
//  Copyright © 2016 FolioReader. All rights reserved.
//

import UIKit

class FolioReaderNavigationPageVC: UIPageViewController {

    var segmentedControl: UISegmentedControl?
    var viewList = [UIViewController]()
    var segmentedControlItems = [String]()
    
    var viewControllerZero: UIViewController?
    var viewControllerOne: UIViewController?
    var viewControllerTwo: UIViewController?
    var viewControllerThree: UIViewController?

    var index: Int
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

    // MARK: Init

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.folioReader = folioReader
        self.readerConfig = readerConfig
        self.index = self.folioReader.currentNavigationMenuIndex
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
        control.addTarget(self, action: #selector(FolioReaderNavigationPageVC.didSwitchMenu(_:)), for: UIControl.Event.valueChanged)
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
        if let vc3 = viewControllerThree {
            tempViewList.append(vc3)
            vc3.didMove(toParent: self)
        }
        
        if (self.folioReader.structuralStyle == .bundle || self.folioReader.structuralStyle == .topic), let vc0 = viewControllerZero {
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
        
        if let vc0 = viewControllerZero, self.index == viewList.firstIndex(of: vc0) {
            switch self.folioReader.structuralStyle {
            case .bundle:
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                     title: self.folioReader.currentNavigationMenuBookListStyle == .Grid ? "List" : "Grid",
                     style: .plain,
                     target: self,
                     action: #selector(switchBookListStyle(_:))
                )
            case .topic:
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                     title: "Random",
                     style: .plain,
                     target: self,
                     action: #selector(randomTopic(_:))
                )
            case .atom:
                break
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    // MARK: - Segmented control changes

    @objc func didSwitchMenu(_ sender: UISegmentedControl) {
        let direction: UIPageViewController.NavigationDirection = (index > sender.selectedSegmentIndex ? .reverse : .forward)
        self.index = sender.selectedSegmentIndex
        setViewControllers([viewList[index]], direction: direction, animated: true, completion: nil)
        self.folioReader.currentNavigationMenuIndex = index
        configureNavBar()
    }

    // MARK: - Status Bar

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.folioReader.isNight(.lightContent, .default)
    }
    
    // MARK: - NavBar Button
    
    @objc func switchBookListStyle(_ sender: UIBarButtonItem) {
        if self.folioReader.currentNavigationMenuBookListStyle == .Grid {
            self.folioReader.currentNavigationMenuBookListStyle = .List
        } else {
            self.folioReader.currentNavigationMenuBookListStyle = .Grid
        }
        configureNavBar()
        guard let bookList = self.viewControllerZero as? FolioReaderBookList else { return }
        //bookList.collectionViewLayout.invalidateLayout()
        bookList.collectionView.reloadData()
    }
    
    @objc func randomTopic(_ sender: UIBarButtonItem) {
        guard let bookList = self.viewControllerZero as? FolioReaderBookList else { return }
        bookList.pickRandomTopic()
    }
    
}

// MARK: UIPageViewControllerDelegate

extension FolioReaderNavigationPageVC: UIPageViewControllerDelegate {

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

extension FolioReaderNavigationPageVC: UIPageViewControllerDataSource {

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

