//
//  FolioReaderFontsMenu.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 27/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderFontsMenu: FolioReaderMenu, UIPickerViewDataSource, UIPickerViewDelegate {
    let safeAreaHeight = CGFloat(70)    //including padding between elements

    let stylePicker = UIPickerView()
    let stylePickerHeight = CGFloat(300)
    
    let fontPickerView = UITableView()
   
    let styleSlider = FolioDiscreteSlider()
    let styleSliderHeight = CGFloat(40)
    
    let weightSlider = FolioDiscreteSlider()
    let weightSliderHeight = CGFloat(40)

    var fontFamilies = [FontFamilyInfo]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderFontsMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        let fontSmall = UIImage(readerImageNamed: "icon-font-small")
        let fontBig = UIImage(readerImageNamed: "icon-font-big")
        let fontSmallNormal = fontSmall?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let fontBigNormal = fontBig?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        let fontNarrow = UIImage(readerImageNamed: "icon-font-weight-narrow")
        let fontBlack = UIImage(readerImageNamed: "icon-font-weight-black")
        let fontNarrowNormal = fontNarrow?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let fontBlackNormal = fontBlack?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        // Menu view
        let menuHeight: CGFloat = stylePickerHeight + styleSliderHeight + weightSliderHeight + 8
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
        
        if #available(iOS 14.0, *),
           #available(macCatalyst 14.0, *),
           self.traitCollection.userInterfaceIdiom == .mac {
            fontPickerView.dataSource = self
            fontPickerView.delegate = self
            fontPickerView.register(FolioReaderFontsMenuFontPickerCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
            
            fontPickerView.separatorStyle = .singleLine
            fontPickerView.separatorColor = folioReader.nightMode ? UIColor.lightText : UIColor.darkText
            fontPickerView.translatesAutoresizingMaskIntoConstraints = false
            menuView.addSubview(fontPickerView)
            NSLayoutConstraint.activate([
                fontPickerView.topAnchor.constraint(equalTo: menuView.topAnchor),
                fontPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                fontPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                fontPickerView.heightAnchor.constraint(equalToConstant: stylePickerHeight)
            ])
        } else {
            stylePicker.dataSource = self
            stylePicker.delegate = self
            
            stylePicker.translatesAutoresizingMaskIntoConstraints = false
            menuView.addSubview(stylePicker)
            NSLayoutConstraint.activate([
                stylePicker.topAnchor.constraint(equalTo: menuView.topAnchor),
                stylePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stylePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                stylePicker.heightAnchor.constraint(equalToConstant: stylePickerHeight)
            ])
        }
        
        
        // Font size slider
        styleSlider.tickStyle = .rounded
        styleSlider.tickCount = FolioReader.FontSizes.count
        styleSlider.tickSize = CGSize(width: 8, height: 8)

        styleSlider.thumbStyle = .rounded
        styleSlider.thumbSize = CGSize(width: 28, height: 28)
        styleSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        styleSlider.thumbShadowRadius = 3
        styleSlider.thumbColor = selectedColor

        styleSlider.backgroundColor = UIColor.clear
        styleSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        styleSlider.minimumValue = 0
        styleSlider.value = CGFloat(FolioReader.FontSizes.firstIndex(of: self.folioReader.currentFontSize) ?? 4)
        styleSlider.addTarget(self, action: #selector(FolioReaderFontsMenu.styleSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        styleSlider.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(styleSlider)
        if fontPickerView.superview == menuView {
            NSLayoutConstraint.activate([
                styleSlider.topAnchor.constraint(equalTo: fontPickerView.bottomAnchor),
                styleSlider.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 60),
                styleSlider.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -60),
                styleSlider.heightAnchor.constraint(equalToConstant: styleSliderHeight)
            ])
        }
        
        if stylePicker.superview == menuView {
            NSLayoutConstraint.activate([
                styleSlider.topAnchor.constraint(equalTo: stylePicker.bottomAnchor),
                styleSlider.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 60),
                styleSlider.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -60),
                styleSlider.heightAnchor.constraint(equalToConstant: styleSliderHeight)
            ])
        }

        // Font icons
        let fontSmallView = UIImageView()//frame: CGRect(x: 20, y: lineBeforeSizeSlider.frame.origin.y+14, width: 30, height: 30))
        fontSmallView.image = fontSmallNormal
        fontSmallView.contentMode = UIView.ContentMode.center
        fontSmallView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(fontSmallView)
        NSLayoutConstraint.activate([
            fontSmallView.centerYAnchor.constraint(equalTo: styleSlider.centerYAnchor),
            fontSmallView.leadingAnchor.constraint(equalTo: styleSlider.leadingAnchor, constant: -40),
            fontSmallView.widthAnchor.constraint(equalToConstant: 30),
            fontSmallView.heightAnchor.constraint(equalToConstant: 30)
        ])

        let fontBigView = UIImageView()//frame: CGRect(x: frame.width-50, y: lineBeforeSizeSlider.frame.origin.y+14, width: 30, height: 30))
        fontBigView.image = fontBigNormal
        fontBigView.contentMode = UIView.ContentMode.center
        fontBigView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(fontBigView)
        NSLayoutConstraint.activate([
            fontBigView.centerYAnchor.constraint(equalTo: styleSlider.centerYAnchor),
            fontBigView.leadingAnchor.constraint(equalTo: styleSlider.trailingAnchor, constant: 10),
            fontBigView.widthAnchor.constraint(equalToConstant: 30),
            fontBigView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        weightSlider.tickStyle = .rounded
        weightSlider.tickCount = 9
        weightSlider.tickSize = CGSize(width: 8, height: 8)

        weightSlider.thumbStyle = .rounded
        weightSlider.thumbSize = CGSize(width: 28, height: 28)
        weightSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        weightSlider.thumbShadowRadius = 3
        weightSlider.thumbColor = selectedColor

        weightSlider.backgroundColor = UIColor.clear
        weightSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        weightSlider.minimumValue = 0
        weightSlider.value = CGFloat(Int(self.folioReader.currentFontWeight)! / 100 - 1)
        weightSlider.addTarget(self, action: #selector(FolioReaderFontsMenu.weightSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        weightSlider.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(weightSlider)
        NSLayoutConstraint.activate([
            weightSlider.topAnchor.constraint(equalTo: styleSlider.bottomAnchor, constant: 4),
            weightSlider.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 60),
            weightSlider.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -60),
            weightSlider.heightAnchor.constraint(equalToConstant: weightSliderHeight)
        ])

        let fontNarrowView = UIImageView()//frame: CGRect(x: 20, y: lineBeforeWeightSlider.frame.origin.y+14, width: 30, height: 30))
        fontNarrowView.image = fontNarrowNormal
        fontNarrowView.contentMode = UIView.ContentMode.center
        fontNarrowView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(fontNarrowView)
        NSLayoutConstraint.activate([
            fontNarrowView.centerYAnchor.constraint(equalTo: weightSlider.centerYAnchor),
            fontNarrowView.leadingAnchor.constraint(equalTo: weightSlider.leadingAnchor, constant: -40),
            fontNarrowView.widthAnchor.constraint(equalToConstant: 30),
            fontNarrowView.heightAnchor.constraint(equalToConstant: 30)
        ])

        let fontBlackView = UIImageView()//frame: CGRect(x: frame.width-50, y: lineBeforeWeightSlider.frame.origin.y+14, width: 30, height: 30))
        fontBlackView.image = fontBlackNormal
        fontBlackView.contentMode = UIView.ContentMode.center
        fontBlackView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(fontBlackView)
        NSLayoutConstraint.activate([
            fontBlackView.centerYAnchor.constraint(equalTo: weightSlider.centerYAnchor),
            fontBlackView.leadingAnchor.constraint(equalTo: weightSlider.trailingAnchor, constant: 10),
            fontBlackView.widthAnchor.constraint(equalToConstant: 30),
            fontBlackView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        fontFamilies.append(
            contentsOf:
                UIFont.familyNames.compactMap { familyName -> FontFamilyInfo? in
                    guard let uiFont = UIFont(name: familyName, size: 20) else { return nil }
                    let ctFont = CTFontCreateWithName(uiFont.fontName as CFString, 0, nil)
                    let ctFontName = CTFontCopyLocalizedName(ctFont, kCTFontFamilyNameKey, nil) as String?
                    
                    return FontFamilyInfo(familyName: familyName, localizedName: ctFontName, regularFont: uiFont)
                }
                .sorted {
                    $0.localizedName < $1.localizedName
                }
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let fontRow = fontFamilies.firstIndex(where: { $0.familyName == self.folioReader.currentFont })
        else { return }
        
        if stylePicker.superview == menuView {
            stylePicker.selectRow(fontRow, inComponent: 0, animated: false)
        }
        if fontPickerView.superview == menuView {
            fontPickerView.selectRow(at: IndexPath(row: fontRow, section: 0), animated: true, scrollPosition: .middle)
        }
        
    }
    
    override func layoutSubviews(frame: CGRect) {
        //stylePicker.frame = CGRect(x: 0, y: 0, width: frame.width, height: stylePickerHeight)
        //lineBeforeSizeSlider.frame = CGRect(x: 0, y: stylePicker.frame.maxY, width: frame.width, height: 1)
        styleSlider.frame = CGRect(x: 60, y: stylePicker.frame.maxY, width: frame.width-120, height: styleSliderHeight)
        styleSlider.layoutTrack()
        styleSlider.layoutThumb()
        
        weightSlider.frame = CGRect(x: 60, y: styleSlider.frame.maxY + 4, width: frame.width-120, height: weightSliderHeight)
        weightSlider.layoutTrack()
        weightSlider.layoutThumb()
    }
    
    override func reloadColors() {
        super.reloadColors()

        if fontPickerView.superview == self.menuView {
            fontPickerView.reloadData()
        }
        if stylePicker.superview == self.stylePicker {
            stylePicker.reloadAllComponents()
        }
    }
    
    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fontFamilies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
//        if let label = view as? UILabel {
//            label.textColor = folioReader.nightMode ? UIColor.lightText : UIColor.darkText
//            return label
//        }
        let fontFamilyInfo = fontFamilies[row]
        
        let pickerLabel = UILabel()
        pickerLabel.textColor = folioReader.nightMode ? UIColor.lightText : UIColor.darkText
        pickerLabel.text = fontFamilyInfo.localizedName ?? fontFamilyInfo.familyName
        pickerLabel.font = fontFamilyInfo.regularFont
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.folioReader.currentFont = fontFamilies[row].familyName
    }
    
    // MARK: - Font slider changed
    
    @objc func styleSliderValueChanged(_ sender: FolioDiscreteSlider) {
        self.folioReader.currentFontSize = FolioReader.FontSizes[Int(sender.value)]
    }
    
    @objc func weightSliderValueChanged(_ sender: FolioDiscreteSlider) {
        self.folioReader.currentFontWeight = ((Int(sender.value) + 1) * 100).description
    }

    // MARK: - Gestures
    @objc func tapGesture() {
        dismiss() {
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 1
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

extension FolioReaderFontsMenu: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontFamilies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath) as! FolioReaderFontsMenuFontPickerCell
        
        let fontFamilyInfo = fontFamilies[indexPath.row]
        
        cell.textColor = folioReader.nightMode ? .lightText : .darkText
        cell.selectedTextColor = self.readerConfig.menuTextColorSelected
        
        cell.folioBackgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        cell.folioSelectedBackgroundColor = folioReader.nightMode ? .darkGray : .lightGray
        
        cell.nameLabel.text = fontFamilyInfo.localizedName ?? fontFamilyInfo.familyName
        cell.nameLabel.font = fontFamilyInfo.regularFont
        
        return cell
    }
    
    
}

extension FolioReaderFontsMenu: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.folioReader.currentFont = fontFamilies[indexPath.row].familyName
    }
}

class FolioReaderFontsMenuFontPickerCell: UITableViewCell {
    let nameLabel = UILabel()
    var textColor = UIColor.white
    var selectedTextColor = UIColor.white
    
    var folioBackgroundColor = UIColor.clear
    var folioSelectedBackgroundColor = UIColor.gray
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.backgroundColor = .clear
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        self.nameLabel.textColor = selected ? selectedTextColor : textColor
        self.contentView.backgroundColor = selected ? folioSelectedBackgroundColor : folioBackgroundColor
    }
}
