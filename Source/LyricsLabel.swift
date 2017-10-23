//
//  LyricsLabel.swift
//  LyricsView
//
//  Created by Aqua on 20/10/2017.
//  Copyright © 2017 Aqua. All rights reserved.
//

import UIKit

public class LyricsLabel: UIView {

    // MARK: - Public Properties
    public var sangTextColor = UIColor.red {
        didSet {
            sangLabel.textColor = sangTextColor
        }
    }
    
    public var backgroundTextColor = UIColor.black {
        didSet {
            backgroundLabel.textColor = backgroundTextColor
        }
    }
    
    public var text: String = "" {
        didSet {
            labels.forEach{ $0.text = text }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            widths = layerWidths()
        }
    }
    
    public var font: UIFont = UIFont.systemFont(ofSize: 16) {
        didSet {
            labels.forEach{ $0.font = font }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    
    public var textAlignment: NSTextAlignment = .center {
        didSet {
            labels.forEach{ $0.textAlignment = textAlignment}
        }
    }
    
    public var timeIntervals: [TimeInterval] = [] {
        didSet {
            updateLayerWidth()
        }
    }
    
    public var currentTime: TimeInterval = 0.0 {
        didSet {
            updateLayerWidth()
        }
    }
    
    // MARK: - Private Properties
    
    private let backgroundLabel = UILabel()
    private let sangLabel = UILabel()
    private var labels: [UILabel] {
        return [backgroundLabel, sangLabel]
    }
    
    private let sangLabelMask = CALayer()
    
    private var widths: [CGFloat] = [] {
        didSet {
            updateLayerWidth()
        }
    }
    
    // MARK: - Init / Deinit
    
    private func commonInit() {
        font = UIFont.systemFont(ofSize: 26)
        textAlignment = .center
        
        labels.forEach { (label) in
            addSubview(label)
        }
        
        sangLabel.textColor = sangTextColor
        backgroundLabel.textColor = backgroundTextColor
        sangLabelMask.anchorPoint = CGPoint(x: 0, y: 0.5)
        sangLabelMask.backgroundColor = UIColor.white.cgColor
        sangLabel.layer.mask = sangLabelMask
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override var intrinsicContentSize: CGSize {
        return backgroundLabel.intrinsicContentSize
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        sangLabelMask.bounds.size.height = bounds.height
        
        sangLabelMask.position = CGPoint(x: 0, y: bounds.height / 2)
        labels.forEach{ $0.frame = bounds }
        widths = layerWidths()
        updateLayerWidth()
    }
    
    private func layerWidths() -> [CGFloat] {
        
        var widths = [CGFloat]()
        for index in 0...text.utf16.count {
            
            let substring = text.substring(to: text.index(text.startIndex, offsetBy: index))
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
            paragraphStyle.lineBreakMode = .byTruncatingTail
            let attributes: [NSAttributedStringKey : Any] = [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.paragraphStyle: paragraphStyle as NSParagraphStyle
                ]
     
            let boundingSize = CGSize(width: bounds.width, height: bounds.height)
            let rect: CGRect = substring.boundingRect(with: boundingSize,
                                                      options: .usesDeviceMetrics,
                                                      attributes: attributes,
                                                      context: nil)

            widths.append(rect.maxX)
        }
        return widths
    }
    
    private func updateLayerWidth() {
        var timeOffset = 0.0
        var currentIndex = 0
        var currentLetterTimeOffsetRatio = 0.0
        for (index, timeInterval) in timeIntervals.enumerated() {
            if currentTime > timeOffset && currentTime <= timeOffset + timeInterval {
                currentIndex = index
                currentLetterTimeOffsetRatio = (currentTime - timeOffset) / timeInterval
                break
            }
            if index == timeIntervals.count - 1,
                currentTime > timeOffset + timeInterval {
                currentIndex = index
                currentLetterTimeOffsetRatio = 1
            }
            timeOffset += timeInterval
        }

        var layerWidth: CGFloat = 0.0
        if widths.count > currentIndex {
            let letterOffset = widths[currentIndex]
            var nextLetterOffset: CGFloat = 0.0
            let nextIndex = currentIndex + 1
            if widths.count > nextIndex {
                nextLetterOffset = widths[nextIndex]
            }
            layerWidth = (nextLetterOffset - letterOffset) * CGFloat(currentLetterTimeOffsetRatio) + letterOffset
        }
        CATransaction.setDisableActions(true)
        sangLabelMask.bounds.size.width = layerWidth
    }
}

// MARK: - Public Methods
extension LyricsLabel {
    
    public func animate(intervals: [TimeInterval]) {
        
        var duration = 0.0
        var times = intervals.map { (time) -> TimeInterval in
            let newTime = duration
            duration += time
            return newTime
        }
        times.append(duration)
        
        animate(timeOffsets: times)
    }
    
    public func animate(timeOffsets: [TimeInterval]) {
        
        guard let duration = timeOffsets.last else { return }
        
        let animation = CAKeyframeAnimation(keyPath: "bounds.size.width")
        let timeOffsetRatios = timeOffsets.map{ $0 / duration }
        let widths = layerWidths()
        animation.values = widths
        animation.keyTimes = timeOffsetRatios as [NSNumber]
        animation.duration = duration
        animation.calculationMode = kCAAnimationLinear
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        sangLabelMask.add(animation, forKey: "kLyrcisAnimation")
    }
}


