//
//  FolioSegmentedControl.swift
//  FolioReaderKit
//
//  Created by Gemini (Pro Model) on 2026/03/22.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import UIKit

/// 排列模式，兼容原有 SegmentOrganiseMode
public enum FolioSegmentOrganizeMode {
    case horizontal
    case vertical
}

/// 单元格样式，兼容原有 ComponentStyle
public enum FolioSegmentStyle {
    case image
    case text
    case combined
}

/// 一个用于替代 SMSegmentView 的现代原生 Swift 实现
open class FolioSegmentedControl: UIControl {
    
    // MARK: - 配置属性
    
    public var organizeMode: FolioSegmentOrganizeMode = .horizontal {
        didSet { setupStackViewAxis() }
    }
    
    public var selectedBackgroundColor: UIColor = .darkGray {
        didSet { updateAppearance() }
    }
    
    public var normalBackgroundColor: UIColor = .white {
        didSet { updateAppearance() }
    }
    
    public var selectedTextColor: UIColor = .white {
        didSet { updateAppearance() }
    }
    
    public var normalTextColor: UIColor = .darkGray {
        didSet { updateAppearance() }
    }
    
    public var font: UIFont = .systemFont(ofSize: 17) {
        didSet { updateAppearance() }
    }
    
    public var segmentMargin: CGFloat = 5.0 {
        didSet { stackView.spacing = segmentMargin }
    }
    
    public private(set) var selectedIndex: Int = 0
    
    // MARK: - 私有组件
    
    private let stackView = UIStackView()
    private var segments = [FolioSegment]()
    
    // MARK: - 初始化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        layer.masksToBounds = true
        layer.cornerRadius = 5.0
        
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        setupStackViewAxis()
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupStackViewAxis() {
        stackView.axis = (organizeMode == .horizontal) ? .horizontal : .vertical
    }
    
    // MARK: - 公开接口
    
    public func addSegment(title: String?, selectedImage: UIImage? = nil, normalImage: UIImage? = nil) {
        let index = segments.count
        let segment = FolioSegment(title: title, selectedImage: selectedImage, normalImage: normalImage, index: index)
        
        segment.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        
        segments.append(segment)
        stackView.addArrangedSubview(segment)
        updateAppearance()
    }
    
    public func selectSegment(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < segments.count else { return }
        selectedIndex = index
        
        let animations = {
            for (i, segment) in self.segments.enumerated() {
                segment.isSelected = (i == index)
                segment.backgroundColor = segment.isSelected ? self.selectedBackgroundColor : self.normalBackgroundColor
                segment.updateStyle(
                    textColor: segment.isSelected ? self.selectedTextColor : self.normalTextColor,
                    font: self.font
                )
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: animations)
        } else {
            animations()
        }
    }
    
    // MARK: - 交互
    
    @objc private func segmentTapped(_ sender: FolioSegment) {
        let oldIndex = selectedIndex
        selectSegment(at: sender.index)
        
        if oldIndex != selectedIndex {
            sendActions(for: .valueChanged)
        }
    }
    
    private func updateAppearance() {
        selectSegment(at: selectedIndex, animated: false)
    }
    
    // MARK: - 兼容性辅助 (用于映射旧 Dictionary 配置)
    public func setProperties(_ props: [String: Any]) {
        if let color = props["OnSelectionBackgroundColour"] as? UIColor { selectedBackgroundColor = color }
        if let color = props["OffSelectionBackgroundColour"] as? UIColor { normalBackgroundColor = color }
        if let color = props["OnSelectionTextColour"] as? UIColor { selectedTextColor = color }
        if let color = props["OffSelectionTextColour"] as? UIColor { normalTextColor = color }
        if let font = props["TitleFont"] as? UIFont { self.font = font }
        if let margin = props["VerticalMargin"] as? CGFloat { segmentMargin = margin }
    }
}

// MARK: - 子组件 FolioSegment

private class FolioSegment: UIControl {
    let titleLabel = UILabel()
    let imageView = UIImageView()
    let containerStack = UIStackView()
    
    let selectedImage: UIImage?
    let normalImage: UIImage?
    let index: Int
    
    init(title: String?, selectedImage: UIImage?, normalImage: UIImage?, index: Int) {
        self.selectedImage = selectedImage
        self.normalImage = normalImage
        self.index = index
        super.init(frame: .zero)
        
        titleLabel.text = title
        titleLabel.textAlignment = .center
        
        imageView.contentMode = .scaleAspectFit
        
        containerStack.axis = .horizontal
        containerStack.spacing = 5
        containerStack.alignment = .center
        containerStack.isUserInteractionEnabled = false
        
        addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            containerStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4)
        ])
        
        if selectedImage != nil || normalImage != nil {
            containerStack.addArrangedSubview(imageView)
        }
        
        if title != nil {
            containerStack.addArrangedSubview(titleLabel)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func updateStyle(textColor: UIColor, font: UIFont) {
        titleLabel.textColor = textColor
        titleLabel.font = font
        imageView.image = isSelected ? selectedImage : normalImage
        // 如果是单色图标，可以应用 tintColor
        imageView.tintColor = textColor
    }
    
    override var isSelected: Bool {
        didSet {
            imageView.image = isSelected ? selectedImage : normalImage
        }
    }
}
