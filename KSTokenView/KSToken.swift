//
//  KSToken.swift
//  KSTokenView
//
//  Created by Khawar Shahzad on 01/01/2015.
//  Copyright (c) 2015 Khawar Shahzad. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import AVFoundation

//MARK: - KSToken
//__________________________________________________________________________________
//
open class KSToken : UIControl {
    
    protocol KSTokenGlobalConfig: AnyObject {
        func tokenFont() -> UIFont
        func contentInset() -> UIEdgeInsets
        func imagePadding() -> CGFloat
        func imagePlacement() -> KSTokenImagePlacement
    }
    
    //MARK: - Public Properties
    //__________________________________________________________________________________
    //
    
    /// retuns title as description
    override open var description : String {
        get {
            return title
        }
    }
    
    /// default is ""
    open var title = "" {
        didSet {
            accessibilityLabel = title
        }
    }
    
    /// default is nil. Any Custom object.
    open var object: AnyObject?
    
    /// default is false. If set to true, token can not be deleted
    open var sticky = false
    
    /// default is 15
    open var tokenCornerRadius: CGFloat = Constants.Defaults.cornerRadius
    
    /// default is nil. So it using font from Text Input
    open var tokenTextFont: UIFont?
    
    /// Token Title color
    open var tokenTextColor = Constants.Defaults.textColor
    
    /// Token background color
    open var tokenBackgroundColor = Constants.Defaults.backgroundColor
    
    /// Token title color in selected state
    open var tokenTextHighlightedColor: UIColor?
    
    /// Token backgrould color in selected state
    open var tokenBackgroundHighlightedColor: UIColor?
    
    /// Token background color in selected state. It doesn't have effect if 'tokenBackgroundHighlightedColor' is set
    open var darkRatio: CGFloat = Constants.Defaults.darkRatio
    
    /// Token border width
    open var borderWidth: CGFloat = Constants.Defaults.borderWidth
    
    ///Token border color
    open var borderColor: UIColor = Constants.Defaults.borderColor
    
    ///Token image
    open var image: UIImage?
    
    ///Token image position
    open var imagePlacement: KSTokenImagePlacement?
    
    ///Token image size behavior
    open var imageSizeMode: KSTokenImageSizeMode = Constants.Defaults.imageSizeMode
    
    /// Padding between image and title
    open var imagePadding: CGFloat?
    
    /// Token content insets
    open var contentInset: UIEdgeInsets?
    
    /// default is 200. Maximum width of token. After maximum limit is reached title is truncated at end with '...'
    fileprivate var _maxWidth: CGFloat? = Constants.Defaults.maxWidth
    open var maxWidth: CGFloat {
        get {
            return _maxWidth!
        }
        set (newWidth) {
            if _maxWidth != newWidth {
                _maxWidth = newWidth
                sizeToFit()
                setNeedsDisplay()
            }
        }
    }
    
    weak var globalConfigDelegate: KSTokenGlobalConfig?
    
    /// returns true if token is selected
    override open var isSelected: Bool {
        didSet (newValue) {
            setNeedsDisplay()
        }
    }
    
    //MARK: - Constructors
    //__________________________________________________________________________________
    //
    convenience required public init(coder aDecoder: NSCoder) {
        self.init(title: "")
    }
    
    convenience public init(title: String) {
        self.init(title: title, image: nil, object: title as AnyObject?)
    }
    
    convenience public init(title: String, object: AnyObject?) {
        self.init(title: title, image: nil, object: object)
    }
    convenience public init(title: String, image: UIImage?) {
        self.init(title: title, image: image, object: title as AnyObject?)
    }
    
    public init(title: String, image: UIImage?, object: AnyObject?) {
        self.title = title
        self.image = image
        self.object = object
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
    }
    
    //MARK: - Drawing code
    //__________________________________________________________________________________
    //
    override open func draw(_ rect: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Rectangle Drawing
        
        // fill background
        let rectanglePath = UIBezierPath(roundedRect: rect, cornerRadius: tokenCornerRadius)
        
        var textColor: UIColor
        var backgroundColor: UIColor
        
        if isSelected {
            if tokenBackgroundHighlightedColor != nil {
                backgroundColor = tokenBackgroundHighlightedColor!
            } else {
                backgroundColor = tokenBackgroundColor.darkendColor(darkRatio)
            }
            
            if let tokenTextHighlightedColor {
                textColor = tokenTextHighlightedColor
            } else {
                textColor = tokenTextColor
            }
        } else {
            backgroundColor = tokenBackgroundColor
            textColor = tokenTextColor
        }
        
        backgroundColor.setFill()
        rectanglePath.fill()
        
        let _font: UIFont = getDisplayFont()
        let _contentInsets = getContentInset()
        let _imagePlacement = getImagePlacement()
        
        let maxDrawableHeight = max(rect.height, _font.lineHeight)
        
        // Calculate icon size
        let imageSize: CGSize
        let imageInsetsForTextDrawing: UIEdgeInsets
        let baseImageHeight: CGFloat
        let paddingBetweenTitleAndImage: CGFloat
        let imageEdgeInsets: UIEdgeInsets
        if image != nil {
            baseImageHeight = ceil(_font.lineHeight)
            imageSize = Self.getImageSize(baseHeight: baseImageHeight, imageSizeMode: imageSizeMode)
            imageEdgeInsets = Self.getImageEdgeInsets(baseHeight: baseImageHeight, imageSizeMode: imageSizeMode)
            switch _imagePlacement {
            case .left:
                imageInsetsForTextDrawing = UIEdgeInsets(top: 0, left: baseImageHeight, bottom: 0, right: 0)
            case .right:
                imageInsetsForTextDrawing = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: baseImageHeight)
            }
            paddingBetweenTitleAndImage = getImagePadding()
        } else {
            baseImageHeight = 0
            paddingBetweenTitleAndImage = 0
            imageSize = .zero
            imageInsetsForTextDrawing = .zero
            imageEdgeInsets = .zero
        }

        // Text
        let rectangleTextContent = title
        let rectangleStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        rectangleStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
        rectangleStyle.alignment = NSTextAlignment.center
        let rectangleFontAttributes = [NSAttributedString.Key.font: _font, NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.paragraphStyle: rectangleStyle] as [NSAttributedString.Key : Any]
        let textDrawableWidth = ceil(rect.width - baseImageHeight - _contentInsets.left - _contentInsets.right - paddingBetweenTitleAndImage)
        
        let textHeight: CGFloat = ceil(KSUtils.getTitleRect(rectangleTextContent as NSString, width: textDrawableWidth, height: maxDrawableHeight , font: _font).size.height)
        let additionalImagePadding = imageInsetsForTextDrawing.left > 0 ? paddingBetweenTitleAndImage : 0
        let textWidth = min(maxWidth - _contentInsets.left - _contentInsets.right, textDrawableWidth)
        let textRect = CGRect(
            x: rect.minX + _contentInsets.left + imageInsetsForTextDrawing.left + additionalImagePadding,
            y: rect.minY + (maxDrawableHeight - textHeight) / 2.0,
            width: textWidth,
            height: maxDrawableHeight
        )
        
        rectangleTextContent.draw(in: textRect, withAttributes: rectangleFontAttributes)
        
        // Draw icon
        if let image {
            let imagePoint: CGPoint
            switch _imagePlacement {
            case .left:
                imagePoint = CGPoint(
                    x: rect.minX + _contentInsets.left + imageEdgeInsets.left,
                    y: rect.minY + _contentInsets.top + imageEdgeInsets.top
                )
            case .right:
                imagePoint = CGPoint(
                    x: rect.minX + _contentInsets.left + textWidth + paddingBetweenTitleAndImage + imageEdgeInsets.left,
                    y: rect.minY + _contentInsets.top + imageEdgeInsets.top
                )
            }
            
            let imageRect = CGRect(origin: imagePoint, size: imageSize)
            let aspectFitRect = AVMakeRect(aspectRatio: image.size, insideRect: imageRect)
            image.draw(in: aspectFitRect)
        }
        
#if swift(>=2.3)
        if let context {
            context.saveGState()
            context.clip(to: rect)
            context.restoreGState()
        }
#else
        context.saveGState()
        context.clip(to: rect)
        context.restoreGState()
#endif
        
        // Border
        if borderWidth > 0.0 && borderColor != UIColor.clear {
            borderColor.setStroke()
            rectanglePath.lineWidth = borderWidth
            rectanglePath.stroke()
        }
    }
    
    func isTouchingImage(touchPoints: [CGPoint]) -> Bool {
        guard image != nil, !touchPoints.isEmpty else { return false }
        
        let _font: UIFont = getDisplayFont()
        let _imagePlacement = getImagePlacement()
        let _contentInsets = getContentInset()
        let baseImageHeight = ceil(_font.lineHeight)
        let imageSize = Self.getImageSize(baseHeight: baseImageHeight, imageSizeMode: imageSizeMode)
        let imageEdgeInsets = Self.getImageEdgeInsets(baseHeight: baseImageHeight, imageSizeMode: imageSizeMode)
        
        switch _imagePlacement {
        case .left:
            let imageMaxX = bounds.minX + _contentInsets.left + imageEdgeInsets.left + imageSize.width
            for point in touchPoints {
                if point.x <= imageMaxX {
                    return true
                }
            }
        case .right:
            let imageMinX = bounds.maxX - _contentInsets.right - imageEdgeInsets.right - imageSize.width
            for point in touchPoints {
                if point.x >= imageMinX {
                    return true
                }
            }
        }
        return false
    }
    
    func getDisplayFont(defaultTextFont: UIFont = Constants.Defaults.font) -> UIFont {
        if let tokenTextFont {
            return tokenTextFont
        } else if let tokenFieldFont = globalConfigDelegate?.tokenFont() {
            return tokenFieldFont
        } else {
            return defaultTextFont
        }
    }
    
    func getContentInset(defaultInsets: UIEdgeInsets = Constants.Defaults.contentInsets) -> UIEdgeInsets {
        if let contentInset {
            return contentInset
        } else if let tokenFieldInset = globalConfigDelegate?.contentInset() {
            return tokenFieldInset
        } else {
            return defaultInsets
        }
    }
    
    func getImagePadding(defaultPadding: CGFloat = Constants.Defaults.imagePadding) -> CGFloat {
        if let imagePadding {
            return imagePadding
        } else if let tokenImagePadding = globalConfigDelegate?.imagePadding() {
            return tokenImagePadding
        } else {
            return defaultPadding
        }
    }
    
    func getImagePlacement(defaultPlacement: KSTokenImagePlacement = Constants.Defaults.imagePlacement) -> KSTokenImagePlacement {
        if let imagePlacement {
            return imagePlacement
        } else if let tokenImagePlacement = globalConfigDelegate?.imagePlacement() {
            return tokenImagePlacement
        } else {
            return defaultPlacement
        }
    }
    
    private static func getImageSize(baseHeight: CGFloat, imageSizeMode: KSTokenImageSizeMode) -> CGSize {
        switch imageSizeMode {
        case .fixed(let size, _):
            return CGSize(
                width: min(baseHeight, size.width),
                height: min(baseHeight, size.height)
            )
        case .fontBased(let imageEdgeInsets):
            let imageHeightInsets = imageEdgeInsets.top + imageEdgeInsets.bottom
            let imageWidthWithInsets = imageEdgeInsets.left + imageEdgeInsets.right
            return CGSize(
                width: baseHeight - imageWidthWithInsets,
                height: baseHeight - imageHeightInsets
            )
        }
    }
    
    private static func getImageEdgeInsets(baseHeight: CGFloat, imageSizeMode: KSTokenImageSizeMode) -> UIEdgeInsets {
        switch imageSizeMode {
        case .fixed(let size, let alignment):
            let realImageSize = CGSize(
                width: min(baseHeight, size.width),
                height: min(baseHeight, size.height)
            )
            switch alignment {
            case .top:
                let horizontalOffset:CGFloat = (baseHeight - realImageSize.width) / 2.0
                return UIEdgeInsets(top: 0, left: horizontalOffset, bottom: baseHeight - realImageSize.height, right: horizontalOffset)
            case .left:
                let verticalOffset:CGFloat = (baseHeight - realImageSize.height) / 2.0
                return UIEdgeInsets(top: verticalOffset, left: 0, bottom: verticalOffset, right: baseHeight - realImageSize.width)
            case .right:
                let verticalOffset:CGFloat = (baseHeight - realImageSize.height) / 2.0
                return UIEdgeInsets(top: verticalOffset, left: baseHeight - realImageSize.width, bottom: verticalOffset, right: 0)
            case .center:
                let verticalOffset:CGFloat = (baseHeight - realImageSize.height) / 2.0
                let horizontalOffset:CGFloat = (baseHeight - realImageSize.width) / 2.0
                return UIEdgeInsets(top: verticalOffset, left: horizontalOffset, bottom: verticalOffset, right: horizontalOffset)
            case .bottom:
                let horizontalOffset:CGFloat = (baseHeight - realImageSize.width) / 2.0
                return UIEdgeInsets(top: baseHeight - realImageSize.height, left: horizontalOffset, bottom: 0, right: horizontalOffset)
            case .topLeft:
                return UIEdgeInsets(top: 0, left: 0, bottom: baseHeight - realImageSize.height, right: baseHeight - realImageSize.width)
            case .topRight:
                return UIEdgeInsets(top: 0, left: baseHeight - realImageSize.width, bottom: baseHeight - realImageSize.height, right: 0)
            case .bottomLeft:
                return UIEdgeInsets(top: baseHeight - realImageSize.height, left: 0, bottom: 0, right: baseHeight - realImageSize.width)
            case .bottomRight:
                return UIEdgeInsets(top: baseHeight - realImageSize.height, left: baseHeight - realImageSize.width, bottom: 0, right: 0)
            }
        case .fontBased(let imageEdgeInsets):
            return imageEdgeInsets
        }
    }
    
    //MARK: - Dark mode handling
    //__________________________________________________________________________________
    //
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
    }
}

//MARK: - Constants
//__________________________________________________________________________________
//

public extension KSToken { enum Constants {} }
public extension KSToken.Constants {
    enum Defaults {
        static let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        static let imagePadding: CGFloat = 2
        static let font = UIFont.systemFont(ofSize: 16)
        static let imagePlacement: KSTokenImagePlacement = .right
        static let imageSizeMode: KSTokenImageSizeMode = .fontBased(insets: .zero)
        static let cornerRadius: CGFloat = 16
        static let textColor = UIColor.white
        static let backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 255/255, alpha: 1)
        static let borderColor = UIColor.black
        static let maxWidth: CGFloat = 200
        static let darkRatio: CGFloat = 0.75
        static let borderWidth: CGFloat = 0
    }
}
