//
//  FolioReaderStructureMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation
import UIKit

class FolioReaderAdvancedMenu: FolioReaderMenu {
    let safeAreaHeight = CGFloat(90)    //including padding between elements

    let labelFontSize = CGFloat(16)
    
    let noticeLabel = UILabel()
    let noticeLabelHeight = CGFloat(24)
    
    let structuralStyleLabel = UILabel()
    let structuralStyleLabelHeight: CGFloat = 32
    let structuralStyleSegment = UISegmentedControl()
    let structuralStyleSegmentHeight: CGFloat = 40
    let structuralTocLevelLabel = UILabel()
    let structuralTocLevelLabelHeight: CGFloat = 32
    let structuralTocLevelValue = UILabel()
    let structuralTocLevelStepper = UIStepper()
    
    let structuralTocLevelMinusButton = UIButton()
    let structuralTocLevelPlusButton = UIButton()
    
    let wrapParaLabel = UILabel()
    let wrapParaLabelHeight = CGFloat(32)
    let wrapParaSwitch = UISwitch()
    
    let clearClassLabel = UILabel()
    let clearClassLabelHeight = CGFloat(32)
    let clearClassSwitch = UISwitch()
    
    let styleOverrideLabel = UILabel()
    let styleOverrideLabelHeight = CGFloat(32)
    
    let styleOverrideSegment = UISegmentedControl()
    let styleOverrideSegmentHeight = CGFloat(40)

    var structuralStyleIndexMap = [Int:FolioReaderStructuralStyle]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderAdvancedMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        let menuHeight: CGFloat = noticeLabelHeight + wrapParaLabelHeight + clearClassLabelHeight + styleOverrideLabelHeight + styleOverrideSegmentHeight + structuralStyleLabelHeight + structuralStyleSegmentHeight + structuralTocLevelLabelHeight + 8 + 4 + 4 + 4 + 8 + 8 + 4 + 4
        let tabBarHeight: CGFloat = self.folioReader.readerCenter?.menuBarController.tabBar.frame.height ?? 0
        let safeAreaInsetBottom: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        let visibleHeight = menuHeight + tabBarHeight + safeAreaInsetBottom
        
         // Menu view
        menuView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuView.layer.shadowOpacity = 0.3
        menuView.layer.shadowRadius = 6
        menuView.layer.shadowPath = UIBezierPath(rect: menuView.bounds).cgPath
        menuView.layer.rasterizationScale = UIScreen.main.scale
        menuView.layer.shouldRasterize = true
        menuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView)
        NSLayoutConstraint.activate([
            menuView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -visibleHeight),
            menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // notice label
//        noticeLabel = UILabel(
//            frame: CGRect(
//                x : 8, y: 8,
//                width: frame.width - 16,
//                height: 24
//            )
//        )
        noticeLabel.text = "Note: please reopen reader for these options to take effect"
        noticeLabel.adjustsFontSizeToFitWidth = true
        noticeLabel.baselineAdjustment = .alignCenters
        noticeLabel.textColor = .systemRed
        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(noticeLabel)
        NSLayoutConstraint.activate([
            noticeLabel.topAnchor.constraint(equalTo: menuView.topAnchor, constant: 8),
            noticeLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 8),
            noticeLabel.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: 8),
            noticeLabel.heightAnchor.constraint(equalToConstant: noticeLabelHeight)
        ])
        
        structuralStyleLabel.text = "Book structure"
        structuralStyleLabel.font = .systemFont(ofSize: labelFontSize)
        structuralStyleLabel.adjustsFontForContentSizeCategory = true
        structuralStyleLabel.adjustsFontSizeToFitWidth = true
        structuralStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        FolioReaderStructuralStyle.allCases.forEach {
            structuralStyleSegment.insertSegment(withTitle: $0.description, at: $0.segmentIndex, animated: false)
            structuralStyleIndexMap[$0.segmentIndex] = $0
        }
        structuralStyleSegment.translatesAutoresizingMaskIntoConstraints = false
        structuralStyleSegment.selectedSegmentIndex = self.folioReader.structuralStyle.segmentIndex
        structuralStyleSegment.addTarget(self, action: #selector(structuralStyleValueChanged(_:)), for: .valueChanged)
        
        structuralTocLevelLabel.text = "Track Reading Position By"
        structuralTocLevelLabel.font = .systemFont(ofSize: labelFontSize)
        structuralTocLevelLabel.adjustsFontForContentSizeCategory = true
        structuralTocLevelLabel.adjustsFontSizeToFitWidth = true
        structuralTocLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        structuralTocLevelValue.text = "Linear"
        structuralTocLevelValue.textAlignment = .center
        structuralTocLevelValue.font = .systemFont(ofSize: labelFontSize)
        structuralTocLevelValue.adjustsFontForContentSizeCategory = true
        structuralTocLevelValue.adjustsFontSizeToFitWidth = true
        structuralTocLevelValue.translatesAutoresizingMaskIntoConstraints = false
        
        structuralTocLevelStepper.isContinuous = false
        structuralTocLevelStepper.autorepeat = false
        structuralTocLevelStepper.wraps = false
        structuralTocLevelStepper.minimumValue = 1
        structuralTocLevelStepper.maximumValue = Double(FolioReaderPositionTrackingStyle.allCases.count-2)
        structuralTocLevelStepper.stepValue = 1
        structuralTocLevelStepper.translatesAutoresizingMaskIntoConstraints = false
        structuralTocLevelStepper.value = Double(folioReader.structuralTrackingTocLevel.rawValue)
        structuralTocLevelStepper.addTarget(self, action: #selector(structuralTocLevelValueChanged(_:)), for: .valueChanged)
        
        menuView.addSubview(structuralStyleLabel)
        menuView.addSubview(structuralStyleSegment)
        menuView.addSubview(structuralTocLevelLabel)
        menuView.addSubview(structuralTocLevelValue)
        
        structuralStyleValueChanged(structuralStyleSegment)
        
        NSLayoutConstraint.activate([
            structuralStyleLabel.topAnchor.constraint(equalTo: noticeLabel.bottomAnchor, constant: 4),
            structuralStyleLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            structuralStyleLabel.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            structuralStyleLabel.heightAnchor.constraint(equalToConstant: structuralStyleLabelHeight),
            
            structuralStyleSegment.topAnchor.constraint(equalTo: structuralStyleLabel.bottomAnchor, constant: 4),
            structuralStyleSegment.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            structuralStyleSegment.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            structuralStyleSegment.heightAnchor.constraint(equalToConstant: structuralStyleSegmentHeight),
            
            structuralTocLevelLabel.topAnchor.constraint(equalTo: structuralStyleSegment.bottomAnchor, constant: 8),
            structuralTocLevelLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            structuralTocLevelLabel.widthAnchor.constraint(equalTo: menuView.widthAnchor, constant: -160-16-16-4-8),
            structuralTocLevelLabel.heightAnchor.constraint(equalToConstant: structuralTocLevelLabelHeight),
            
            structuralTocLevelValue.centerYAnchor.constraint(equalTo: structuralTocLevelLabel.centerYAnchor),
            structuralTocLevelValue.leadingAnchor.constraint(equalTo: structuralTocLevelLabel.trailingAnchor, constant: 4),
            structuralTocLevelValue.widthAnchor.constraint(equalToConstant: 64),
            structuralTocLevelValue.heightAnchor.constraint(equalToConstant: structuralTocLevelLabelHeight)
        ])
        
        if #available(iOS 14.0, *),
           #available(macCatalyst 14.0, *),
           self.traitCollection.userInterfaceIdiom == .mac {
            //TODO
            structuralTocLevelMinusButton.translatesAutoresizingMaskIntoConstraints = false
            structuralTocLevelMinusButton.setImage(UIImage(systemName: "minus"), for: .normal)
            menuView.addSubview(structuralTocLevelMinusButton)
            NSLayoutConstraint.activate([
                structuralTocLevelMinusButton.centerYAnchor.constraint(equalTo: structuralTocLevelValue.centerYAnchor),
                structuralTocLevelMinusButton.leadingAnchor.constraint(equalTo: structuralTocLevelValue.trailingAnchor, constant: 4),
                structuralTocLevelMinusButton.widthAnchor.constraint(equalToConstant: 32),
                structuralTocLevelMinusButton.heightAnchor.constraint(equalTo: structuralTocLevelValue.heightAnchor)
            ])
            structuralTocLevelMinusButton.addTarget(self, action: #selector(structuralTocLevelButtonAction(_:)), for: .primaryActionTriggered)
            
            structuralTocLevelPlusButton.translatesAutoresizingMaskIntoConstraints = false
            structuralTocLevelPlusButton.setImage(UIImage(systemName: "plus"), for: .normal)
            menuView.addSubview(structuralTocLevelPlusButton)
            NSLayoutConstraint.activate([
                structuralTocLevelPlusButton.centerYAnchor.constraint(equalTo: structuralTocLevelValue.centerYAnchor),
                structuralTocLevelPlusButton.leadingAnchor.constraint(equalTo: structuralTocLevelMinusButton.trailingAnchor, constant: 8),
                structuralTocLevelPlusButton.widthAnchor.constraint(equalToConstant: 32),
                structuralTocLevelPlusButton.heightAnchor.constraint(equalTo: structuralTocLevelValue.heightAnchor)
            ])
            structuralTocLevelPlusButton.addTarget(self, action: #selector(structuralTocLevelButtonAction(_:)), for: .primaryActionTriggered)
        } else {
            menuView.addSubview(structuralTocLevelStepper)
            NSLayoutConstraint.activate([
                structuralTocLevelStepper.centerYAnchor.constraint(equalTo: structuralTocLevelValue.centerYAnchor),
                structuralTocLevelStepper.leadingAnchor.constraint(equalTo: structuralTocLevelValue.trailingAnchor, constant: 8),
                structuralTocLevelStepper.widthAnchor.constraint(equalToConstant: 96),
                structuralTocLevelStepper.heightAnchor.constraint(equalToConstant: structuralTocLevelLabelHeight)
            ])
        }

        styleOverrideLabel.text = "Style overriden intensity"
        styleOverrideLabel.font = .systemFont(ofSize: labelFontSize)
        styleOverrideLabel.adjustsFontForContentSizeCategory = true
        styleOverrideLabel.adjustsFontSizeToFitWidth = true
        styleOverrideLabel.translatesAutoresizingMaskIntoConstraints = false

        StyleOverrideTypes.allCases.forEach {
            styleOverrideSegment.insertSegment(withTitle: $0.description, at: $0.rawValue, animated: false)
        }
        styleOverrideSegment.selectedSegmentIndex = self.folioReader.styleOverride.rawValue
        styleOverrideSegment.addTarget(self, action: #selector(styleOverrideSegmentValueChanged), for: .valueChanged)
        styleOverrideSegment.translatesAutoresizingMaskIntoConstraints = false
        
        menuView.addSubview(styleOverrideLabel)
        menuView.addSubview(styleOverrideSegment)
        
        NSLayoutConstraint.activate([
            styleOverrideLabel.topAnchor.constraint(equalTo: structuralTocLevelLabel.bottomAnchor, constant: 4),
            styleOverrideLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            styleOverrideLabel.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            styleOverrideLabel.heightAnchor.constraint(equalToConstant: styleOverrideLabelHeight),
            styleOverrideSegment.topAnchor.constraint(equalTo: styleOverrideLabel.bottomAnchor, constant: 4),
            styleOverrideSegment.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            styleOverrideSegment.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            styleOverrideSegment.heightAnchor.constraint(equalToConstant: styleOverrideSegmentHeight)
        ])
        
        // reformat switches
        wrapParaLabel.text = "Wrap raw text inside <p>"
        wrapParaLabel.font = .systemFont(ofSize: labelFontSize)
        wrapParaLabel.adjustsFontForContentSizeCategory = true
        wrapParaLabel.adjustsFontSizeToFitWidth = true
        wrapParaLabel.translatesAutoresizingMaskIntoConstraints = false
        
        wrapParaSwitch.isOn = self.folioReader.doWrapPara
        wrapParaSwitch.addTarget(self, action: #selector(paragraphSwitchValueChanged), for: .valueChanged)
        wrapParaSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        menuView.addSubview(wrapParaLabel)
        menuView.addSubview(wrapParaSwitch)
        
        NSLayoutConstraint.activate([
            wrapParaLabel.topAnchor.constraint(equalTo: styleOverrideSegment.bottomAnchor, constant: 4),
            wrapParaLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            wrapParaLabel.trailingAnchor.constraint(equalTo: wrapParaSwitch.leadingAnchor, constant: 4),
            wrapParaLabel.heightAnchor.constraint(equalToConstant: wrapParaLabelHeight),
            wrapParaSwitch.centerYAnchor.constraint(equalTo: wrapParaLabel.centerYAnchor),
            wrapParaSwitch.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            wrapParaSwitch.widthAnchor.constraint(equalToConstant: 48),
            wrapParaSwitch.heightAnchor.constraint(equalTo: wrapParaLabel.heightAnchor)
        ])
        
        // clear body&table styles
        clearClassLabel.text = "Deactive unsuitable html styles"
        clearClassLabel.font = .systemFont(ofSize: labelFontSize)
        clearClassLabel.adjustsFontForContentSizeCategory = true
        clearClassLabel.adjustsFontSizeToFitWidth = true
        clearClassLabel.translatesAutoresizingMaskIntoConstraints = false

        clearClassSwitch.isOn = self.folioReader.doClearClass
        clearClassSwitch.addTarget(self, action: #selector(clearClassSwitchValueChanged), for: .valueChanged)
        clearClassSwitch.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(clearClassLabel)
        menuView.addSubview(clearClassSwitch)
        
        NSLayoutConstraint.activate([
            clearClassLabel.topAnchor.constraint(equalTo: wrapParaLabel.bottomAnchor, constant: 4),
            clearClassLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            clearClassLabel.trailingAnchor.constraint(equalTo: clearClassSwitch.leadingAnchor, constant: 4),
            clearClassLabel.heightAnchor.constraint(equalToConstant: clearClassLabelHeight),
            clearClassSwitch.centerYAnchor.constraint(equalTo: clearClassLabel.centerYAnchor),
            clearClassSwitch.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            clearClassSwitch.widthAnchor.constraint(equalToConstant: 48),
            clearClassSwitch.heightAnchor.constraint(equalTo: clearClassLabel.heightAnchor)
        ])
        
        reloadColors()
    }
    
    override func layoutSubviews(frame: CGRect) {
        
    }
    
    @objc func paragraphSwitchValueChanged(_ sender: UISwitch) {
        self.folioReader.doWrapPara = sender.isOn
    }
    
    @objc func clearClassSwitchValueChanged(_ sender: UISwitch) {
        self.folioReader.doClearClass = sender.isOn
    }
    
    @objc func styleOverrideSegmentValueChanged(_ sender: UISegmentedControl) {
        guard let styleOverride = StyleOverrideTypes(rawValue: sender.selectedSegmentIndex) else { return }
        self.folioReader.styleOverride = styleOverride
    }
    
    @objc func structuralStyleValueChanged(_ sender: UISegmentedControl) {
        guard let structuralStyle = self.structuralStyleIndexMap[sender.selectedSegmentIndex] else { return }
        self.folioReader.structuralStyle = structuralStyle
        
        self.structuralTocLevelValue.isEnabled = structuralStyle == .bundle
        self.structuralTocLevelStepper.isEnabled = structuralStyle == .bundle
        self.structuralTocLevelMinusButton.isEnabled = structuralStyle == .bundle
        self.structuralTocLevelPlusButton.isEnabled = structuralStyle == .bundle
        
        structuralTocLevelValueChanged(self.structuralTocLevelStepper)
    }
    
    @objc func structuralTocLevelValueChanged(_ sender: UIStepper) {
        switch self.folioReader.structuralStyle {
        case .atom:
            self.folioReader.structuralTrackingTocLevel = .linear
        case .topic:
            self.folioReader.structuralTrackingTocLevel = .levelMax
        case .bundle:
            var structuralTrackingTocLevel = FolioReaderPositionTrackingStyle.levelMax
            if Int(sender.value) < structuralTrackingTocLevel.rawValue {
                structuralTrackingTocLevel = .init(rawValue: Int(sender.value)) ?? .level1
            }
            self.folioReader.structuralTrackingTocLevel = structuralTrackingTocLevel
            self.structuralTocLevelValue.text = structuralTrackingTocLevel.description
            
            self.folioReader.readerContainer?.book.updateBundleInfo(rootTocLevel: structuralTrackingTocLevel.rawValue)
        }
        self.structuralTocLevelValue.text = self.folioReader.structuralTrackingTocLevel.description
    }
    
    @objc func structuralTocLevelButtonAction(_ sender: UIButton) {
        var newValue = self.structuralTocLevelStepper.value
        if sender == structuralTocLevelMinusButton {
            newValue = max(Double(FolioReaderPositionTrackingStyle.level1.rawValue), newValue - 1)
        }
        if sender == structuralTocLevelPlusButton {
            newValue = min(Double(FolioReaderPositionTrackingStyle.level3.rawValue), newValue + 1)
        }
        self.structuralTocLevelStepper.value = newValue
        self.structuralTocLevelStepper.sendActions(for: .valueChanged)
    }
    
    // MARK: - Gestures
    @objc func tapGesture() {
        dismiss() {
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 3
        }
        
        if (self.readerConfig.shouldHideNavigationOnTap == false) {
            self.folioReader.readerCenter?.showBars()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer && touch.view == view {
            return true
        }
        return false
    }
    
    // MARK: - Status Bar
    
    override var prefersStatusBarHidden : Bool {
        return (self.readerConfig.shouldHideNavigationOnTap == true)
    }
}
