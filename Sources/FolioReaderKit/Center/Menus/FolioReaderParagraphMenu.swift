//
//  File.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation
import UIKit

class FolioReaderParagraphMenu: FolioReaderMenu {
    let safeAreaHeight = CGFloat(90)    //including padding between elements

    let letterSpacingSlider = FolioDiscreteSlider()
    let letterSpacingSliderHeight = CGFloat(40)
    let letterSpacingTopPadding = CGFloat(10)

    let lineHeightSlider = FolioDiscreteSlider()
    let lineHeightSliderHeight = CGFloat(40)
    let lineHeightSliderTopPadding = CGFloat(10)
    
    let textIndentValue = UILabel()
    let textIndentHeight = CGFloat(32)
    let textIndentTopPadding = CGFloat(24)
    let textIndentStepper = UIStepper()
    
    let textIndentMinusButton = UIButton()
    let textIndentPlusButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderParagraphMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        let charNarrow = UIImage(readerImageNamed: "icon-char-spacing-narrow")
        let charWide = UIImage(readerImageNamed: "icon-char-spacing-wide")
        let charNarrowNormal = charNarrow?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let charWideNormal = charWide?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        let lineNarrow = UIImage(readerImageNamed: "icon-line-height-narrow")
        let lineWide = UIImage(readerImageNamed: "icon-line-height-wide")
        let lineNarrowNormal = lineNarrow?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let lineWideNormal = lineWide?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        let firstIndent = UIImage(readerImageNamed: "icon-first-line-indent")
        let firstIndentNormal = firstIndent?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        // Menu view
        let menuHeight = letterSpacingSliderHeight + lineHeightSliderHeight + textIndentHeight + letterSpacingTopPadding + lineHeightSliderTopPadding + textIndentTopPadding + 8
        let tabBarHeight: CGFloat = self.folioReader.readerCenter?.menuBarController.tabBar.frame.height ?? 0
        let safeAreaInsetBottom: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        let visibleHeight = menuHeight + tabBarHeight + safeAreaInsetBottom
        
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
        
        // Letter Spacing Slider
        letterSpacingSlider.tickStyle = .rounded
        letterSpacingSlider.tickCount = 11
        letterSpacingSlider.tickSize = CGSize(width: 8, height: 8)

        letterSpacingSlider.thumbStyle = .rounded
        letterSpacingSlider.thumbSize = CGSize(width: 28, height: 28)
        letterSpacingSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        letterSpacingSlider.thumbShadowRadius = 3
        letterSpacingSlider.thumbColor = selectedColor

        letterSpacingSlider.backgroundColor = UIColor.clear
        letterSpacingSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        letterSpacingSlider.minimumValue = 0
        letterSpacingSlider.incrementValue = 1
        letterSpacingSlider.value = CGFloat(self.folioReader.currentLetterSpacing)
        letterSpacingSlider.addTarget(self, action: #selector(FolioReaderParagraphMenu.letterSpacingSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        letterSpacingSlider.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(letterSpacingSlider)
        NSLayoutConstraint.activate([
            letterSpacingSlider.topAnchor.constraint(equalTo: menuView.topAnchor, constant: letterSpacingTopPadding),
            letterSpacingSlider.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 60),
            letterSpacingSlider.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -60),
            letterSpacingSlider.heightAnchor.constraint(equalToConstant: letterSpacingSliderHeight)
        ])
        
        let charNarrowView = UIImageView()
        charNarrowView.image = charNarrowNormal
        charNarrowView.contentMode = UIView.ContentMode.center
        charNarrowView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(charNarrowView)
        NSLayoutConstraint.activate([
            charNarrowView.centerYAnchor.constraint(equalTo: letterSpacingSlider.centerYAnchor),
            charNarrowView.leadingAnchor.constraint(equalTo: letterSpacingSlider.leadingAnchor, constant: -40),
            charNarrowView.widthAnchor.constraint(equalToConstant: 30),
            charNarrowView.heightAnchor.constraint(equalToConstant: 30)
        ])

        let charWideView = UIImageView()
        charWideView.image = charWideNormal
        charWideView.contentMode = UIView.ContentMode.center
        charWideView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(charWideView)
        NSLayoutConstraint.activate([
            charWideView.centerYAnchor.constraint(equalTo: letterSpacingSlider.centerYAnchor),
            charWideView.leadingAnchor.constraint(equalTo: letterSpacingSlider.trailingAnchor, constant: 10),
            charWideView.widthAnchor.constraint(equalToConstant: 30),
            charWideView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Line Spacing Slider
        lineHeightSlider.tickStyle = .rounded
        lineHeightSlider.tickCount = 11
        lineHeightSlider.tickSize = CGSize(width: 8, height: 8)

        lineHeightSlider.thumbStyle = .rounded
        lineHeightSlider.thumbSize = CGSize(width: 28, height: 28)
        lineHeightSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        lineHeightSlider.thumbShadowRadius = 3
        lineHeightSlider.thumbColor = selectedColor

        lineHeightSlider.backgroundColor = UIColor.clear
        lineHeightSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        lineHeightSlider.minimumValue = 0
        lineHeightSlider.value = CGFloat(self.folioReader.currentLineHeight)
        lineHeightSlider.addTarget(self, action: #selector(FolioReaderParagraphMenu.lineHeightSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        lineHeightSlider.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(lineHeightSlider)
        NSLayoutConstraint.activate([
            lineHeightSlider.topAnchor.constraint(equalTo: letterSpacingSlider.bottomAnchor, constant: lineHeightSliderTopPadding),
            lineHeightSlider.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 60),
            lineHeightSlider.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -60),
            lineHeightSlider.heightAnchor.constraint(equalToConstant: lineHeightSliderHeight)
        ])
        
        
        let lineNarrowView = UIImageView()
        lineNarrowView.image = lineNarrowNormal
        lineNarrowView.contentMode = UIView.ContentMode.center
        lineNarrowView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(lineNarrowView)
        NSLayoutConstraint.activate([
            lineNarrowView.centerYAnchor.constraint(equalTo: lineHeightSlider.centerYAnchor),
            lineNarrowView.leadingAnchor.constraint(equalTo: lineHeightSlider.leadingAnchor, constant: -40),
            lineNarrowView.widthAnchor.constraint(equalToConstant: 30),
            lineNarrowView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let lineWideView = UIImageView()
        lineWideView.image = lineWideNormal
        lineWideView.contentMode = UIView.ContentMode.center
        lineWideView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(lineWideView)
        NSLayoutConstraint.activate([
            lineWideView.centerYAnchor.constraint(equalTo: lineHeightSlider.centerYAnchor),
            lineWideView.leadingAnchor.constraint(equalTo: lineHeightSlider.trailingAnchor, constant: 10),
            lineWideView.widthAnchor.constraint(equalToConstant: 30),
            lineWideView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let firstIndentView = UIImageView()//frame: CGRect(x: 20, y: textIndentLabel.frame.origin.y+2, width: 30, height: 30))
        firstIndentView.image = firstIndentNormal
        firstIndentView.contentMode = UIView.ContentMode.center
        firstIndentView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(firstIndentView)
        NSLayoutConstraint.activate([
            firstIndentView.topAnchor.constraint(equalTo: lineHeightSlider.bottomAnchor, constant: 20),
            firstIndentView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 20),
            firstIndentView.widthAnchor.constraint(equalToConstant: 30),
            firstIndentView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let textIndentLabel = UILabel()
//            frame: CGRect(
//                x: 64,
//                y: lineHeightSlider.frame.maxY + 16,
//                width: frame.width - 240, height: 32
//            )
//        )
        textIndentLabel.text = "First Line Indent"
        textIndentLabel.font = segmentFont
        textIndentLabel.adjustsFontForContentSizeCategory = true
        textIndentLabel.adjustsFontSizeToFitWidth = true
        textIndentLabel.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(textIndentLabel)
        NSLayoutConstraint.activate([
            textIndentLabel.centerYAnchor.constraint(equalTo: firstIndentView.centerYAnchor),
            textIndentLabel.leadingAnchor.constraint(equalTo: firstIndentView.trailingAnchor, constant: 20),
            textIndentLabel.widthAnchor.constraint(equalTo: menuView.widthAnchor, constant: -240),
            textIndentLabel.heightAnchor.constraint(equalToConstant: textIndentHeight)
        ])
        
        
//        textIndentValue.frame = CGRect(
//            x: textIndentLabel.frame.maxX + 4,
//            y: textIndentLabel.frame.minY,
//            width: 48,
//            height: 32
//        )
        textIndentValue.textAlignment = .center
        textIndentValue.text = "\(folioReader.currentTextIndent)"
        textIndentValue.font = segmentFont
        textIndentValue.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(textIndentValue)
        NSLayoutConstraint.activate([
            textIndentValue.centerYAnchor.constraint(equalTo: textIndentLabel.centerYAnchor),
            textIndentValue.leadingAnchor.constraint(equalTo: textIndentLabel.trailingAnchor, constant: 4),
            textIndentValue.widthAnchor.constraint(equalToConstant: 48),
            textIndentValue.heightAnchor.constraint(equalToConstant: textIndentHeight)
        ])
        
//            frame: CGRect(
//                x: textIndentValue.frame.maxX + 4,
//                y: textIndentLabel.frame.minY,
//                width: frame.width - textIndentValue.frame.maxX - 4 - 4,
//                height: textIndentLabel.frame.height
//            )
//        )
        textIndentStepper.isContinuous = false
        textIndentStepper.autorepeat = false
        textIndentStepper.wraps = false
        textIndentStepper.minimumValue = -4
        textIndentStepper.maximumValue = 4
        textIndentStepper.stepValue = 1
        textIndentStepper.value = Double(folioReader.currentTextIndent)
        textIndentStepper.addTarget(
            self,
            action: #selector(textIndentStepperValueChanged(_:)),
            for: .valueChanged)
        textIndentStepper.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 14.0, *),
           #available(macCatalyst 14.0, *),
           self.traitCollection.userInterfaceIdiom == .mac {
            textIndentMinusButton.translatesAutoresizingMaskIntoConstraints = false
            textIndentMinusButton.setImage(UIImage(systemName: "minus"), for: .normal)
            menuView.addSubview(textIndentMinusButton)
            NSLayoutConstraint.activate([
                textIndentMinusButton.centerYAnchor.constraint(equalTo: textIndentValue.centerYAnchor),
                textIndentMinusButton.leadingAnchor.constraint(equalTo: textIndentValue.trailingAnchor, constant: 4),
                textIndentMinusButton.widthAnchor.constraint(equalToConstant: 32),
                textIndentMinusButton.heightAnchor.constraint(equalTo: textIndentValue.heightAnchor)
            ])
            textIndentMinusButton.addTarget(self, action: #selector(textIndentButtonAction(_:)), for: .primaryActionTriggered)
            
            textIndentPlusButton.translatesAutoresizingMaskIntoConstraints = false
            textIndentPlusButton.setImage(UIImage(systemName: "plus"), for: .normal)
            menuView.addSubview(textIndentPlusButton)
            NSLayoutConstraint.activate([
                textIndentPlusButton.centerYAnchor.constraint(equalTo: textIndentValue.centerYAnchor),
                textIndentPlusButton.leadingAnchor.constraint(equalTo: textIndentMinusButton.trailingAnchor, constant: 8),
                textIndentPlusButton.widthAnchor.constraint(equalToConstant: 32),
                textIndentPlusButton.heightAnchor.constraint(equalTo: textIndentValue.heightAnchor)
            ])
            textIndentPlusButton.addTarget(self, action: #selector(textIndentButtonAction(_:)), for: .primaryActionTriggered)
        } else {
            menuView.addSubview(textIndentStepper)
            NSLayoutConstraint.activate([
                textIndentStepper.centerYAnchor.constraint(equalTo: textIndentValue.centerYAnchor),
                textIndentStepper.leadingAnchor.constraint(equalTo: textIndentValue.trailingAnchor, constant: 4),
                textIndentStepper.widthAnchor.constraint(equalToConstant: 96),
                textIndentStepper.heightAnchor.constraint(equalTo: textIndentValue.heightAnchor)
            ])
        }
        
        reloadColors()
    }
    
    override func layoutSubviews(frame: CGRect) {
//        letterSpacingSlider.frame = CGRect(x: 60, y: 10, width: frame.width - 120, height: 40)
        letterSpacingSlider.frame.size = CGSize(width: frame.width - 120, height: letterSpacingSliderHeight)
        letterSpacingSlider.layoutTrack()
        
//        lineHeightSlider.frame = CGRect(x: 60, y: letterSpacingSlider.frame.maxY + 8, width: frame.width - 120, height: 40)
        lineHeightSlider.frame.size = CGSize(width: frame.width - 120, height: 40)
        lineHeightSlider.layoutTrack()
    }
    
    
    // MARK: - Font slider changed
    
    @objc func letterSpacingSliderValueChanged(_ sender: FolioDiscreteSlider) {
        self.folioReader.currentLetterSpacing = Int(sender.value)
    }
    
    @objc func lineHeightSliderValueChanged(_ sender: FolioDiscreteSlider) {
        self.folioReader.currentLineHeight = Int(sender.value)
    }
    
    @objc func textIndentStepperValueChanged(_ sender: UIStepper) {
        self.folioReader.currentTextIndent = Int(sender.value)
        textIndentValue.text = "\(folioReader.currentTextIndent)"
    }
    
    // MARK: - Text Indent Buttons
    @objc func textIndentButtonAction(_ sender: UIButton) {
        var newValue = self.folioReader.currentTextIndent
        if sender == textIndentMinusButton {
            newValue = max(-4, newValue - 1)
        }
        if sender == textIndentPlusButton {
            newValue = min(4, newValue + 1)
        }
        self.folioReader.currentTextIndent = newValue
        textIndentValue.text = "\(folioReader.currentTextIndent)"
    }
    
    // MARK: - Gestures
    @objc func tapGesture() {
        dismiss() {
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 2
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
