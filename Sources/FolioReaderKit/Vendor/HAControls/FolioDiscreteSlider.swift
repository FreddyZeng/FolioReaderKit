//
//  FolioDiscreteSlider.swift
//  FolioReaderKit
//
//  Created by Gemini (Pro Model).
//  Copyright © FolioReader. All rights reserved.
//

import UIKit
import QuartzCore

public enum FolioDiscreteSliderStyle: Int {
    case ios
    case rectangular
    case rounded
    case invisible
    case image
}

open class FolioDiscreteSlider: UIControl {
    
    // MARK: - Properties
    
    public var tickStyle: FolioDiscreteSliderStyle = .rectangular { didSet { setNeedsLayout() } }
    public var tickSize: CGSize = CGSize(width: 1.0, height: 4.0) { didSet { setNeedsLayout() } }
    public var tickCount: Int = 11 { didSet { setNeedsLayout() } }
    
    public var trackStyle: FolioDiscreteSliderStyle = .ios { didSet { setNeedsLayout() } }
    public var trackThickness: CGFloat = 2.0 { didSet { setNeedsLayout() } }
    
    public var thumbStyle: FolioDiscreteSliderStyle = .ios { didSet { setNeedsLayout() } }
    public var thumbSize: CGSize = CGSize(width: 10.0, height: 10.0) { didSet { setNeedsLayout() } }
    public var thumbShadowRadius: CGFloat = 0.0 { didSet { setNeedsLayout() } }
    public var thumbShadowOffset: CGSize = .zero { didSet { setNeedsLayout() } }
    public var thumbColor: UIColor? { didSet { setNeedsLayout() } }
    
    public var minimumValue: CGFloat = 0 { didSet { setNeedsLayout() } }
    public var incrementValue: CGFloat = 1 { didSet { setNeedsLayout() } }
    
    private var _value: CGFloat = 0
    public var value: CGFloat {
        get { return _value }
        set {
            _value = newValue
            setNeedsLayout()
        }
    }
    
    // MARK: - Layers
    private let trackLayer = CAShapeLayer()
    private let activeTrackLayer = CALayer()
    private let thumbLayer = CALayer()
    private let ticksContainerLayer = CALayer()
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        layer.addSublayer(trackLayer)
        layer.addSublayer(activeTrackLayer)
        layer.addSublayer(ticksContainerLayer)
        layer.addSublayer(thumbLayer)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }
    
    // MARK: - Layout
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutTrack()
    }
    
    public func layoutTrack() {
        guard bounds.width > 0 else { return }
        let usableWidth = bounds.width - thumbSize.width
        let trackHeight = (trackStyle == .ios) ? 2.0 : trackThickness
        let trackRect = CGRect(x: thumbSize.width/2, y: (bounds.height - trackHeight)/2, width: usableWidth, height: trackHeight)
        
        trackLayer.path = UIBezierPath(roundedRect: trackRect, cornerRadius: trackHeight/2).cgPath
        trackLayer.fillColor = tintColor?.withAlphaComponent(0.3).cgColor ?? UIColor.lightGray.withAlphaComponent(0.3).cgColor
        
        activeTrackLayer.backgroundColor = tintColor?.cgColor
        activeTrackLayer.cornerRadius = trackHeight/2
        
        layoutTicks(in: trackRect)
        layoutThumb()
    }
    
    public func layoutThumb() {
        guard bounds.width > 0 else { return }
        let segments = CGFloat(max(1, tickCount - 1))
        let ratio = max(0, min(1, (_value - minimumValue) / (segments * incrementValue)))
        
        let usableWidth = bounds.width - thumbSize.width
        let x = (thumbSize.width / 2) + (usableWidth * ratio)
        let y = bounds.height / 2
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        thumbLayer.frame = CGRect(x: x - thumbSize.width/2, y: y - thumbSize.height/2, width: thumbSize.width, height: thumbSize.height)
        
        switch thumbStyle {
        case .ios:
            thumbLayer.backgroundColor = UIColor.white.cgColor
            thumbLayer.borderWidth = 0.5
            thumbLayer.borderColor = UIColor(white: 0.8, alpha: 1.0).cgColor
            thumbLayer.cornerRadius = thumbSize.width / 2
        case .rounded:
            thumbLayer.backgroundColor = thumbColor?.cgColor ?? UIColor.white.cgColor
            thumbLayer.cornerRadius = thumbSize.width / 2
            thumbLayer.borderWidth = 0
        case .rectangular:
            thumbLayer.backgroundColor = thumbColor?.cgColor ?? UIColor.white.cgColor
            thumbLayer.cornerRadius = 0
            thumbLayer.borderWidth = 0
        default: break
        }
        
        if thumbShadowRadius > 0 {
            thumbLayer.shadowColor = UIColor.black.cgColor
            thumbLayer.shadowOffset = thumbShadowOffset
            thumbLayer.shadowOpacity = 0.15
            thumbLayer.shadowRadius = thumbShadowRadius
        } else {
            thumbLayer.shadowOpacity = 0
        }
        
        if trackStyle == .ios {
            activeTrackLayer.frame = CGRect(x: thumbSize.width/2, y: (bounds.height - (trackStyle == .ios ? 2.0 : trackThickness))/2, width: usableWidth * ratio, height: trackStyle == .ios ? 2.0 : trackThickness)
            activeTrackLayer.isHidden = false
        } else {
            activeTrackLayer.isHidden = true
        }
        
        CATransaction.commit()
    }
    
    private func layoutTicks(in rect: CGRect) {
        ticksContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        ticksContainerLayer.frame = rect
        
        if tickStyle == .invisible || tickStyle == .ios { return }
        
        let segments = max(1, tickCount - 1)
        let step = rect.width / CGFloat(segments)
        
        for i in 0..<tickCount {
            let tick = CALayer()
            tick.backgroundColor = tintColor?.cgColor
            let x = CGFloat(i) * step - (tickSize.width / 2)
            tick.frame = CGRect(x: x, y: (rect.height - tickSize.height)/2, width: tickSize.width, height: tickSize.height)
            if tickStyle == .rounded {
                tick.cornerRadius = tickSize.width / 2
            }
            ticksContainerLayer.addSublayer(tick)
        }
    }
    
    // MARK: - Interactions
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        updateValueFor(location.x)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            updateValueFor(touch.location(in: self).x)
        }
    }
    
    private func updateValueFor(_ x: CGFloat) {
        let usableWidth = bounds.width - thumbSize.width
        let clampedX = max(thumbSize.width/2, min(x, bounds.width - thumbSize.width/2))
        let ratio = usableWidth > 0 ? (clampedX - thumbSize.width/2) / usableWidth : 0
        
        let segments = CGFloat(max(1, tickCount - 1))
        let tick = round(ratio * segments)
        let newValue = minimumValue + (tick * incrementValue)
        
        if newValue != _value {
            _value = newValue
            layoutThumb()
            sendActions(for: .valueChanged)
        }
    }
    
    open override var tintColor: UIColor! {
        didSet { setNeedsLayout() }
    }
}
