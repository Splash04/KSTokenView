//
//  KSUtils.swift
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

let KSTextEmpty = "\u{200B}"

class KSUtils : NSObject {
    
    class func getTitleRect(_ str: NSString, width: CGFloat, height: CGFloat, font: UIFont) -> CGRect {
        let rectangleStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        rectangleStyle.alignment = NSTextAlignment.center
        let rectangleFontAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: rectangleStyle]
        return str.boundingRect(with: CGSize(width: width, height: height), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: rectangleFontAttributes, context: nil)
    }
    
    class func getTokenRect(token: KSToken, maxWidth: CGFloat, defaultFont: UIFont, defaultInsets: UIEdgeInsets, defaultImagePadding: CGFloat) -> CGRect {
        let font = token.getDisplayFont(defaultTextFont: defaultFont)
        let contentInset = token.getContentInset(defaultInsets: defaultInsets)
        let fontLineHeight: CGFloat = ceil(font.lineHeight)
        let tokenMaxWidth = token.maxWidth
        let resultMaxWidth = min(tokenMaxWidth, maxWidth)
        let imageWithPaddingWidth: CGFloat
        if token.image != nil {
            let imageWidth = fontLineHeight
            let _imagePadding = token.getImagePadding(defaultPadding: defaultImagePadding)
            imageWithPaddingWidth = imageWidth + _imagePadding
        } else {
            imageWithPaddingWidth = 0
        }
        
        let tokenHeight = getTokenHeight(font: font, insets: contentInset)
        let maxTextWidth = resultMaxWidth - imageWithPaddingWidth - contentInset.right - contentInset.left
        let textRect = getTitleRect(token.title as NSString, width: maxTextWidth, height: CGFloat(MAXFLOAT), font: font)
        let calculatedTextHeight = ceil(min(textRect.size.height, fontLineHeight))
        let calculatedTokenWidth = ceil(textRect.size.width + imageWithPaddingWidth + contentInset.right + contentInset.right)
        return CGRect(
            x: textRect.origin.x,
            y: textRect.origin.y,
            width: min(calculatedTokenWidth, maxWidth),
            height: max(calculatedTextHeight, tokenHeight)
        )
    }
    
    class func getTokenHeight(font: UIFont, insets: UIEdgeInsets) -> CGFloat {
        ceil(font.lineHeight + insets.top + insets.bottom)
    }
    
    class func widthOfString(_ str: String, font: UIFont) -> CGFloat {
        let attrs = [NSAttributedString.Key.font: font]
        let attributedString = NSMutableAttributedString(string:str, attributes:attrs)
        return attributedString.size().width
    }
    
}

extension UIColor {
    func darkendColor(_ darkRatio: CGFloat) -> UIColor {
        var h: CGFloat = 0.0, s: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        if (getHue(&h, saturation: &s, brightness: &b, alpha: &a)) {
            return UIColor(hue: h, saturation: s, brightness: b*darkRatio, alpha: a)
        } else {
            return self
        }
    }
}


extension String {
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        get {
            return self[..<index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeThrough<Int>) -> Substring {
        get {
            return self[...index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeFrom<Int>) -> Substring {
        get {
            return self[index(startIndex, offsetBy: value.lowerBound)...]
        }
    }
}
