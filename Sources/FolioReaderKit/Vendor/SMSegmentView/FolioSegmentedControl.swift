//
//  FolioSegmentedControl.swift
//  FolioReaderKit
//
//  Created by Gemini (Pro Model) on 2026/03/22.
//  Copyright © 2026 FolioReader. All rights reserved.
//

import UIKit

// MARK: - Legacy Keys for compatibility
public let keyContentVerticalMargin = "VerticalMargin"
public let keySegmentOnSelectionColour = "OnSelectionBackgroundColour"
public let keySegmentOffSelectionColour = "OffSelectionBackgroundColour"
public let keySegmentOnSelectionTextColour = "OnSelectionTextColour"
public let keySegmentOffSelectionTextColour = "OffSelectionTextColour"
public let keySegmentTitleFont = "TitleFont"

/// 兼容原有的排列模式枚举
public enum FolioSegmentOrganizeMode: Int {
    case horizontal = 0
    case vertical
}

/// 兼容旧代码的类型别名
public typealias SegmentOrganiseMode = FolioSegmentOrganizeMode

/// 兼容原有的代理协议
public protocol FolioSegmentedControlDelegate: AnyObject {
    func segmentedControl(_ segmentedControl: FolioSegmentedControl, didSelectSegmentAtIndex index: Int)
}

/// 为了最小化改动，保留旧协议别名
public protocol SMSegmentViewDelegate: AnyObject {
    func segmentView(_ segmentView: FolioSegmentedControl, didSelectSegmentAtIndex index: Int)
}

/// 一个用于替代 SMSegmentView 的现代原生 Swift 实现
open class FolioSegmentedControl: UIControl {
    
    // MARK: - 兼容性属性
    public weak var delegate: SMSegmentViewDelegate?
    
    public var segmentTitleFont: UIFont = .systemFont(ofSize: 17) { didSet { font = segmentTitleFont } }
    public var separatorColour: UIColor = .lightGray { didSet { updateSeparators() } }
    public var separatorWidth: CGFloat = 1.0 { didSet { updateSeparators() } }
    public var segmentOnSelectionColour: UIColor = .clear { didSet { selectedBackgroundColor = segmentOnSelectionColour } }
    public var segmentOffSelectionColour: UIColor = .clear { didSet { normalBackgroundColor = segmentOffSelectionColour } }
    public var segmentOnSelectionTextColour: UIColor = .white { didSet { selectedTextColor = segmentOnSelectionTextColour } }
    public var segmentOffSelectionTextColour: UIColor = .darkGray { didSet { normalTextColor = segmentOffSelectionTextColour } }
    public var segmentVerticalMargin: CGFloat = 0 { didSet { segmentMargin = segmentVerticalMargin } }
    
    // MARK: - 现代属性
    public var organizeMode: FolioSegmentOrganizeMode = .horizontal {
        didSet { setupStackViewAxis() }
    }
    
    public var selectedBackgroundColor: UIColor = .darkGray { didSet { updateAppearance() } }
    public var normalBackgroundColor: UIColor = .white { didSet { updateAppearance() } }
    public var selectedTextColor: UIColor = .white { didSet { updateAppearance() } }
    public var normalTextColor: UIColor = .darkGray { didSet { updateAppearance() } }
    public var font: UIFont = .systemFont(ofSize: 17) { didSet { updateAppearance() } }
    public var segmentMargin: CGFloat = 0.0 { didSet { stackView.spacing = segmentMargin } }
    
    public private(set) var selectedIndex: Int = -1
    
    // MARK: - 私有组件
    private let stackView = UIStackView()
    private let separatorsContainer = UIStackView()
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
    
    public init(frame: CGRect, separatorColour: UIColor, separatorWidth: CGFloat, segmentProperties: [String: Any]?) {
        super.init(frame: frame)
        setup()
        self.separatorColour = separatorColour
        self.separatorWidth = separatorWidth
        if let props = segmentProperties {
            setProperties(props)
        }
    }
    
    private func setup() {
        backgroundColor = .clear
        layer.masksToBounds = true
        layer.cornerRadius = 5.0
        
        // 分割线容器必须在选项层之上
        separatorsContainer.distribution = .fillEqually
        separatorsContainer.alignment = .fill
        separatorsContainer.isUserInteractionEnabled = false
        
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        setupStackViewAxis()
        
        addSubview(stackView)
        addSubview(separatorsContainer)
        
        [separatorsContainer, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: topAnchor),
                $0.leadingAnchor.constraint(equalTo: leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    private func setupStackViewAxis() {
        stackView.axis = (organizeMode == .horizontal) ? .horizontal : .vertical
        separatorsContainer.axis = stackView.axis
        updateSeparators()
    }
    
    public func addSegment(title: String?, selectedImage: UIImage? = nil, normalImage: UIImage? = nil) {
        let index = segments.count
        let segment = FolioSegment(title: title, selectedImage: selectedImage, normalImage: normalImage, index: index)
        segment.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        
        segments.append(segment)
        stackView.addArrangedSubview(segment)
        
        // 立即应用当前样式
        segment.updateStyle(
            textColor: (index == selectedIndex) ? self.selectedTextColor : self.normalTextColor,
            font: self.font
        )
        
        updateSeparators()
        
        if selectedIndex == -1 {
            selectSegment(at: 0, animated: false)
        } else {
            updateAppearance()
        }
    }
    
    private func updateSeparators() {
        separatorsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard segments.count > 1 && separatorWidth > 0 else { return }
        
        for i in 0..<segments.count {
            let wrapper = UIView()
            separatorsContainer.addArrangedSubview(wrapper)
            
            // 最后一个选项右侧不需要线
            if i < segments.count - 1 {
                let sep = UIView()
                sep.backgroundColor = separatorColour
                sep.translatesAutoresizingMaskIntoConstraints = false
                wrapper.addSubview(sep)
                
                if organizeMode == .horizontal {
                    NSLayoutConstraint.activate([
                        sep.widthAnchor.constraint(equalToConstant: separatorWidth),
                        sep.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: separatorWidth / 2),
                        sep.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 10),
                        sep.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -10)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        sep.heightAnchor.constraint(equalToConstant: separatorWidth),
                        sep.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: separatorWidth / 2),
                        sep.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
                        sep.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20)
                    ])
                }
            }
        }
    }
    
    public func addSegmentWithTitle(_ title: String?, onSelectionImage: UIImage?, offSelectionImage: UIImage?) {
        addSegment(title: title, selectedImage: onSelectionImage, normalImage: offSelectionImage)
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
    
    public func selectSegmentAtIndex(_ index: Int) {
        selectSegment(at: index, animated: false)
    }
    
    @objc private func segmentTapped(_ sender: FolioSegment) {
        selectSegment(at: sender.index)
        sendActions(for: .valueChanged)
        delegate?.segmentView(self, didSelectSegmentAtIndex: selectedIndex)
    }
    
    private func updateAppearance() {
        if selectedIndex >= 0 {
            selectSegment(at: selectedIndex, animated: false)
        }
    }
    
    private func setProperties(_ props: [String: Any]) {
        if let color = props["OnSelectionBackgroundColour"] as? UIColor { selectedBackgroundColor = color }
        if let color = props["OffSelectionBackgroundColour"] as? UIColor { normalBackgroundColor = color }
        if let color = props["OnSelectionTextColour"] as? UIColor { selectedTextColor = color }
        if let color = props["OffSelectionTextColour"] as? UIColor { normalTextColor = color }
        if let font = props["TitleFont"] as? UIFont { self.font = font }
        if let margin = props["VerticalMargin"] as? CGFloat { segmentMargin = margin }
    }
}

public typealias SMSegmentView = FolioSegmentedControl

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
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        
        imageView.contentMode = .scaleAspectFit
        
        containerStack.axis = .horizontal
        containerStack.spacing = 2
        containerStack.alignment = .center
        containerStack.isUserInteractionEnabled = false
        
        addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2),
            containerStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2)
        ])
        
        if selectedImage != nil || normalImage != nil {
            containerStack.addArrangedSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 24),
                imageView.heightAnchor.constraint(equalToConstant: 24)
            ])
            // 预设初始图片
            imageView.image = normalImage
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
        imageView.tintColor = textColor
    }
    
    override var isSelected: Bool {
        didSet {
            imageView.image = isSelected ? selectedImage : normalImage
        }
    }
}
