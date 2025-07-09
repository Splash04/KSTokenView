//
//  KSTokenField.swift
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

enum KSTokenFieldState {
    case opened
    case closed
}


@objc protocol KSTokenFieldDelegate : UITextFieldDelegate {
    func tokenFieldShouldChangeHeight(_ height: CGFloat)
    @objc optional func tokenFieldDidSelectToken(_ token: KSToken)
    @objc optional func tokenFieldDidClickOnTokenImage(_ token: KSToken)
    @objc optional func tokenFieldDidBeginEditing(_ tokenField: KSTokenField)
    @objc optional func tokenFieldDidEndEditing(_ tokenField: KSTokenField)
    func tokenLongPressed(_ token: KSToken)
}


open class KSTokenField: UITextField {
    
    // MARK: - Private Properties
    fileprivate var _cursorColor: UIColor = KSTokenView.Constants.Defaults.cursorColor {
        willSet {
            tintColor = newValue
        }
    }
    fileprivate var _setupCompleted: Bool = false
    fileprivate var _selfFrame: CGRect?
    fileprivate var _caretPoint: CGPoint?
    fileprivate var _placeholderValue: String?
    fileprivate var _placeholderLabel: UILabel?
    fileprivate var _state: KSTokenFieldState = .opened
    fileprivate var _minWidthForInput: CGFloat = 50.0
    fileprivate var _separatorText: String = KSTokenView.Constants.Defaults.separatorText
    fileprivate var _font: UIFont = KSToken.Constants.Defaults.font
    fileprivate var _contentInset: UIEdgeInsets = KSToken.Constants.Defaults.contentInsets
    fileprivate var _imagePadding: CGFloat = KSToken.Constants.Defaults.imagePadding
    fileprivate var _imagePlacement: KSTokenImagePlacement = KSToken.Constants.Defaults.imagePlacement
    fileprivate var _marginX: CGFloat = KSTokenView.Constants.Defaults.marginX
    fileprivate var _marginY: CGFloat = KSTokenView.Constants.Defaults.marginY
    fileprivate var _bufferX: CGFloat = KSTokenView.Constants.Defaults.bufferX
    fileprivate var _removesTokensOnEndEditing = true
    fileprivate var _scrollView = UIScrollView(frame: .zero)
    fileprivate var _scrollPoint = CGPoint.zero
    fileprivate var _direction: KSTokenViewScrollDirection = .vertical {
        didSet {
            if (oldValue != _direction) {
                updateLayout()
            }
        }
    }
    fileprivate var _descriptionText: String = "selections" {
        didSet {
            _updateText()
        }
    }
    
    // MARK: - Public Properties
    
    /// default is grayColor()
    var promptTextColor: UIColor = UIColor.gray
    
    /// default is grayColor()
    var placeHolderColor: UIColor = UIColor.gray
    
    /// default is 120.0. After maximum limit is reached, tokens starts scrolling vertically
    var maximumHeight: CGFloat = 120.0
    
    /// default is nil
    override open var placeholder: String? {
        get {
            return _placeholderValue
        }
        set {
            super.placeholder = newValue
            if (newValue == nil) {
                return
            }
            _placeholderValue = newValue
        }
    }
    
    weak var parentView: KSTokenView? {
        willSet (tokenView) {
            if let tokenView {
                _cursorColor = tokenView.cursorColor
                _contentInset = tokenView.contentInset
                _imagePadding = tokenView.imagePadding
                _imagePlacement = tokenView.imagePlacement
                _marginX = tokenView.marginX
                _marginY = tokenView.marginY
                _bufferX = tokenView.bufferX
                _direction = tokenView.direction
                _font = tokenView.font
                if (_font != font) {
                    font = _font
                }
                _minWidthForInput = tokenView.minWidthForInput
                _separatorText = tokenView.separatorText
                _removesTokensOnEndEditing = tokenView.removesTokensOnEndEditing
                _descriptionText = tokenView.descriptionText
                placeHolderColor = tokenView.placeholderColor
                promptTextColor = tokenView.promptColor
                textColor = tokenView.textColor
                _setPromptText(tokenView.promptText)
                
                if _setupCompleted {
                    updateLayout()
                }
            }
        }
    }
    
    weak var tokenFieldDelegate: KSTokenFieldDelegate? {
        didSet {
            delegate = tokenFieldDelegate
        }
    }
    
    /// returns Array of tokens
    var tokens = [KSToken]()
    
    /// returns selected KSToken object
    var selectedToken: KSToken?
    
    // MARK: - Constructors
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setupTokenField()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setupTokenField()
    }
    
    
    // MARK: - Methods
    
    // MARK: - Setup
    fileprivate func _setupTokenField() {
        text = ""
        autocorrectionType = UITextAutocorrectionType.no
        autocapitalizationType = UITextAutocapitalizationType.words
        contentVerticalAlignment = UIControl.ContentVerticalAlignment.top
        returnKeyType = UIReturnKeyType.done
        text = KSTextEmpty
        backgroundColor = UIColor.white
        clipsToBounds = true
        _state = .closed
        
        _setScrollRect()
        _scrollView.backgroundColor = UIColor.clear
        _scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIResponder.becomeFirstResponder))
        gestureRecognizer.cancelsTouchesInView = false
        _scrollView.addGestureRecognizer(gestureRecognizer)
        _scrollView.delegate = self
        addSubview(_scrollView)
        
        addTarget(self, action: #selector(KSTokenField.tokenFieldTextDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    fileprivate func _setScrollRect() {
        let buffer:CGFloat = _bufferX
        let width = frame.width - _leftViewRect().width
        let height = frame.height
        
        _scrollView.frame = CGRect(x: _leftViewRect().width + buffer, y: 0, width: width, height: height)
    }
    
    override open func draw(_ rect: CGRect) {
        if !_setupCompleted {
            _selfFrame = rect
        }
        _setupCompleted = true
        _updateText()
        
        // Fix the bug which doesn't update the UI when _selfFrame is not set.
        // https://github.com/khawars/KSTokenView/issues/11
        
        if !tokens.isEmpty {
            updateLayout()
        }
    }
    
    // MARK: - Add Token
    /**
     Create and add new token
     
     - parameter title: String value
     
     - returns: KSToken object
     */
    func addTokenWithTitle(_ title: String) -> KSToken? {
        return addTokenWithTitle(title, tokenObject: nil)
    }
    
    /**
     Create and add new token with custom object
     
     - parameter title:       String value
     - parameter tokenObject: Any custom object
     
     - returns: KSToken object
     */
    func addTokenWithTitle(_ title: String, tokenObject: AnyObject?) -> KSToken? {
        let token = KSToken(title: title, object: tokenObject)
        return addToken(token)
    }
    
    /**
     Add new token
     
     - parameter token: KSToken object
     
     - returns: KSToken object
     */
    func addToken(_ token: KSToken) -> KSToken? {
        if token.title.isEmpty {
            token.title = "Untitled"
        }
        
        if !tokens.contains(token) {
            token.addTarget(self, action: #selector(KSTokenField.tokenTouchDown(_:forEvent:)), for: .touchDown)
            token.addTarget(self, action: #selector(KSTokenField.tokenTouchUpInside(_:forEvent:)), for: .touchUpInside)
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureAction))
            token.addGestureRecognizer(longPressGesture)
            
            tokens.append(token)
            _insertToken(token)
        }
        
        return token
    }
    
    fileprivate func _insertToken(_ token: KSToken, shouldLayout: Bool = true) {
        _scrollView.addSubview(token)
        _scrollView.bringSubviewToFront(token)
        token.globalConfigDelegate = self
        token.setNeedsDisplay()
        if shouldLayout {
            updateLayout()
        }
    }
    
    //MARK: - Delete Token
    /*
     **************************** Delete Token ****************************
     */
    
    /**
     Deletes a token from view
     
     - parameter token: KSToken object
     */
    func deleteToken(_ token: KSToken) {
        removeToken(token)
    }
    
    /**
     Deletes a token from view, if any token is found for custom object
     
     - parameter object: Custom object
     */
    func deleteTokenWithObject(_ object: AnyObject?) {
        if object == nil {return}
        for token in tokens {
            if (token.object!.isEqual(object)) {
                removeToken(token)
                break
            }
        }
    }
    
    /**
     Deletes all tokens from view
     */
    func forceDeleteAllTokens() {
        tokens.removeAll(keepingCapacity: false)
        for token in tokens {
            removeToken(token, removingAll: true)
        }
        updateLayout()
    }
    
    /**
     Deletes token from view
     
     - parameter token:       KSToken object
     - parameter removingAll: A boolean to describe if removingAll tokens
     */
    func removeToken(_ token: KSToken, removingAll: Bool = false) {
        if token.isEqual(selectedToken) {
            deselectSelectedToken()
        }
        token.removeFromSuperview()
        token.globalConfigDelegate = nil
        
        if let index = tokens.firstIndex(of: token) {
            tokens.remove(at: index)
        }
        if !removingAll {
            updateLayout()
        }
    }
    
    
    //MARK: - Layout
    /*
     **************************** Layout ****************************
     */
    
    /**
     Untokenzies the layout
     */
    func untokenize() {
        guard _removesTokensOnEndEditing else {
            return
        }
        _state = .closed
        for subview in _scrollView.subviews {
            if subview is KSToken {
                subview.removeFromSuperview()
            }
        }
        updateLayout()
    }
    
    /**
     Tokenizes the layout
     */
    func tokenize() {
        _state = .opened
        for token: KSToken in tokens {
            _insertToken(token, shouldLayout: false)
        }
        updateLayout()
    }
    
    /**
     Updates the tokenView layout and calls delegate methods
     */
    func updateLayout(_ shouldUpdateText: Bool = true) {
        guard parentView != nil else {
            return
        }
        
        _caretPoint = _layoutTokens()
        deselectSelectedToken()
        
        if shouldUpdateText {
            _updateText()
        }
        
        if _caretPoint != .zero {
            let tokensMaxY = max(_caretPoint!.y, _selfFrame!.height)
            
            if frame.size.height != tokensMaxY {
                tokenFieldDelegate?.tokenFieldShouldChangeHeight(tokensMaxY)
            }
        }
    }
    
    /**
     Layout tokens
     
     - returns: CGPoint maximum position values
     */
    fileprivate func _layoutTokens() -> CGPoint {
        guard let _selfFrame else {
            return .zero
        }
        
        if _state == .closed {
            return CGPoint(x: _marginX + _bufferX, y: _selfFrame.size.height)
        }
        
        if _direction == .horizontal {
            return _layoutTokensHorizontally()
        }
        
        var lineNumber = 1
        let leftMargin = _leftViewRect().width
        let rightMargin = _rightViewRect().width
        
        var tokenPosition = CGPoint(x: _marginX, y: _marginY)
        let baseTokenHeight = KSUtils.getTokenHeight(font: _font, insets: _contentInset)
        
        for token: KSToken in tokens {
            let tokenSize = KSUtils.getTokenRect(token: token, maxWidth: bounds.size.width, defaultFont: _font, defaultInsets: _contentInset, defaultImagePadding: _imagePadding).size
            let tokenWidth = tokenSize.width
            let tokenHeight = tokenSize.height
            
            // Add token at specific position
            if let _ = token.superview {
                if (tokenPosition.x + tokenWidth + _marginX + leftMargin > bounds.size.width - rightMargin) {
                    lineNumber += 1
                    tokenPosition.x = _marginX
                    tokenPosition.y += (tokenHeight + _marginY)
                }
                
                token.frame = CGRect(x: tokenPosition.x, y: tokenPosition.y, width: tokenWidth, height: tokenHeight)
                tokenPosition.x += tokenWidth + _marginX
            }
        }
        
        // check if next token can be added in same line or new line
        if (bounds.size.width - (tokenPosition.x + _marginX) - leftMargin) < _minWidthForInput {
            
            lineNumber += 1
            tokenPosition.x = _marginX
            tokenPosition.y += (baseTokenHeight + _marginY)
        }
        
        var positionY = (lineNumber == 1 && tokens.isEmpty) ? _selfFrame.size.height: (tokenPosition.y + baseTokenHeight + _marginY)
        _scrollView.contentSize = CGSize(width: _scrollView.frame.width, height: positionY)
        if positionY > maximumHeight {
            positionY = maximumHeight
        }
        
        _scrollView.frame.size = CGSize(width: _scrollView.frame.width, height: positionY)
        scrollViewScrollToEnd()
        
        return CGPoint(x: tokenPosition.x + leftMargin, y: positionY)
    }
    
    
    /**
     Layout tokens horizontally
     
     - returns: CGPoint maximum position values
     */
    fileprivate func _layoutTokensHorizontally() -> CGPoint {
        let leftMargin = _leftViewRect().width
        var tokenPosition = CGPoint(x: _marginX, y: _marginY)
        
        for token: KSToken in tokens {
            let tokenSize = KSUtils.getTokenRect(token: token, maxWidth: bounds.size.width, defaultFont: _font, defaultInsets: _contentInset, defaultImagePadding: _imagePadding).size
            let tokenWidth = tokenSize.width
            let tokenHeight = tokenSize.height
            
            if ((token.superview) != nil) {
                token.frame = CGRect(x: tokenPosition.x, y: tokenPosition.y, width: tokenWidth, height: tokenHeight)
                tokenPosition.x += tokenWidth + _marginX
            }
        }
        
        let offsetWidth = ((tokenPosition.x + _marginX + _leftViewRect().width) > (frame.width - _minWidthForInput)) ? _minWidthForInput : 0
        _scrollView.contentSize = CGSize(width: max(_scrollView.frame.width, tokenPosition.x + offsetWidth), height: frame.height)
        scrollViewScrollToEnd()
        
        return CGPoint(x: min(tokenPosition.x + leftMargin, frame.width - _minWidthForInput), y: frame.height)
    }
    
    /**
     Scroll the tokens to end
     */
    func scrollViewScrollToEnd() {
        var bottomOffset: CGPoint
        switch _direction {
        case .vertical:
            bottomOffset = CGPoint(x: 0, y: _scrollView.contentSize.height - _scrollView.bounds.height)
        case .horizontal:
            bottomOffset = CGPoint(x: _scrollView.contentSize.width - _scrollView.bounds.width, y: 0)
        }
        _scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    //MARK: - Text Rect
    /*
     **************************** Text Rect ****************************
     */
    
    fileprivate func _textRectWithBounds(_ bounds: CGRect) -> CGRect {
        guard _setupCompleted else { return .zero }
        
        if tokens.isEmpty || _caretPoint == nil {
            return CGRect(
                x: _leftViewRect().width + _marginX + _bufferX,
                y: _leftViewRect().origin.y,
                width: bounds.size.width - 5.0,
                height: bounds.size.height
            )
        }
        
        if !tokens.isEmpty && _state == .closed {
            return CGRect(
                x: _leftViewRect().maxX + _marginX + _bufferX,
                y: _leftViewRect().origin.y,
                width: (frame.size.width - _caretPoint!.x - _marginX),
                height: bounds.size.height
            )
        }
        
        return CGRect(
            x: _caretPoint!.x,
            y: floor((_caretPoint!.y - font!.lineHeight - (_marginY))),
            width: (frame.size.width - _caretPoint!.x - _marginX),
            height: bounds.size.height
        )
    }
    
    override open func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: _marginX,
            y: (_selfFrame != nil) ? (_selfFrame!.height - _leftViewRect().height) * 0.5 : (bounds.height - _leftViewRect().height) * 0.5,
            width: _leftViewRect().width,
            height: ceil(_leftViewRect().height)
        )
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return _textRectWithBounds(bounds)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return _textRectWithBounds(bounds)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return _textRectWithBounds(bounds)
    }
    
    fileprivate func _leftViewRect() -> CGRect {
        if (leftViewMode == .never ||
            (leftViewMode == .unlessEditing && isEditing) ||
            (leftViewMode == .whileEditing && !isEditing)) {
            return .zero
        }
        return leftView!.frame
    }
    
    fileprivate func _rightViewRect() -> CGRect {
        if (rightViewMode == .never ||
            rightViewMode == .unlessEditing && isEditing ||
            rightViewMode == .whileEditing && !isEditing) {
            return .zero
        }
        return rightView!.bounds
    }
    
    
    //MARK: - Prompt Text
    /*
     **************************** Prompt Text ****************************
     */
    fileprivate func _setPromptText(_ text: String?) {
        if text != nil {
            let label: UILabel
            if let leftlabel = leftView as? UILabel {
                label = leftlabel
            } else {
                label = UILabel(frame: .zero)
                label.frame.origin.x += _marginX
                leftViewMode = .always
            }
            label.text = text
            label.font = font
            label.textColor = promptTextColor
            label.sizeToFit()
            leftView = label
        } else {
            leftView = nil
        }
        _setScrollRect()
    }
    
    
    //MARK: - Placeholder
    /*
     **************************** Placeholder ****************************
     */
    
    fileprivate func _updateText() {
        guard _setupCompleted else { return }
        _initPlaceholderLabel()
        
        switch(_state) {
        case .opened:
            text = KSTextEmpty
            break
            
        case .closed:
            if tokens.isEmpty {
                text = KSTextEmpty
            } else {
                var title = KSTextEmpty
                for token: KSToken in tokens {
                    title += "\(token.title)\(_separatorText)"
                }
                
                if !title.isEmpty {
                    title = String(title[..<title.index(title.endIndex, offsetBy: -_separatorText.count)])
                }
                
                let width = KSUtils.widthOfString(title, font: font!)
                if width + _leftViewRect().width > bounds.width {
                    text = "\(tokens.count) \(_descriptionText)"
                } else {
                    text = title
                }
            }
            break
        }
        _updatePlaceHolderVisibility()
    }
    
    fileprivate func _updatePlaceHolderVisibility() {
        guard let _placeholderLabel else { return }
        if tokens.isEmpty && (text == KSTextEmpty || (text?.isEmpty == true)) {
            _placeholderLabel.text = _placeholderValue!
            _placeholderLabel.sizeToFit()
            _placeholderLabel.isHidden = false
            
        } else {
            _placeholderLabel.isHidden = true
        }
    }
    
    fileprivate func _initPlaceholderLabel() {
        let xPos = _marginX
        if let _placeholderLabel {
            _placeholderLabel.frame.origin.x = xPos
        } else {
            let newPlaceholderLabel = UILabel(frame: CGRect(
                x: xPos,
                y: leftView!.frame.origin.y,
                width: _selfFrame!.width - xPos - _leftViewRect().size.width,
                height: _leftViewRect().size.height
            ))
            newPlaceholderLabel.textColor = placeHolderColor
            newPlaceholderLabel.font = _font
            _placeholderLabel = newPlaceholderLabel
            _scrollView.addSubview(newPlaceholderLabel)
        }
    }
    
    
    //MARK: - Token Gestures
    //__________________________________________________________________________________
    //
    
    func isSelectedToken(_ token: KSToken) -> Bool {
        return token.isEqual(selectedToken)
    }
    
    func deselectSelectedToken() {
        selectedToken?.isSelected = false
        selectedToken = nil
    }
    
    func selectToken(_ token: KSToken) {
        guard !token.sticky else { return }
        
        for token: KSToken in tokens {
            if isSelectedToken(token) {
                deselectSelectedToken()
                break
            }
        }
        
        token.isSelected = true
        selectedToken = token
        tokenFieldDelegate?.tokenFieldDidSelectToken?(token)
    }
    
    @objc func tokenTouchDown(_ token: KSToken, forEvent event: UIEvent) {
        guard selectedToken != nil else { return }
        selectedToken?.isSelected = false
        selectedToken = nil
    }
    
    @objc func tokenTouchUpInside(_ token: KSToken, forEvent event: UIEvent) {
        selectToken(token)
        
        if let touches: Set<UITouch> = event.touches(for: token) {
            let touchPoints = touches.map { $0.location(in: token) }
            
            let isTouchedImage = token.isTouchingImage(touchPoints: touchPoints)
            if isTouchedImage {
                tokenFieldDelegate?.tokenFieldDidClickOnTokenImage?(token)
            }
        }
    }
    
    @objc func longPressGestureAction(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let token = gesture.view as? KSToken
        else { return }
        selectToken(token)
        tokenFieldDelegate?.tokenLongPressed(token)
        
        let touchPoints = (0..<gesture.numberOfTouches).map {
            gesture.location(ofTouch: $0, in: token)
        }
        let isTouchedImage = token.isTouchingImage(touchPoints: touchPoints)
        if isTouchedImage {
            tokenFieldDelegate?.tokenFieldDidClickOnTokenImage?(token)
        }
    }
    
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if touch.view == self {
            deselectSelectedToken()
        }
        return super.beginTracking(touch, with: event)
    }
    
    @objc func tokenFieldTextDidChange(_ textField: UITextField) {
        _updatePlaceHolderVisibility()
    }
    
    // MARK: - Other Methods
    
    func objects() -> NSArray {
        let objects = NSMutableArray()
        for object: AnyObject in tokens {
            objects.add(object)
        }
        return objects
    }
    
    override open func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        tokenFieldDelegate?.tokenFieldDidBeginEditing?(self)
        return true
    }
    
    @discardableResult override open func resignFirstResponder() -> Bool {
        tokenFieldDelegate?.tokenFieldDidEndEditing?(self)
        return super.resignFirstResponder()
    }
    
}


//MARK: - UIScrollViewDelegate
//__________________________________________________________________________________
//
extension KSTokenField : UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _scrollPoint = scrollView.contentOffset
    }
    
    public func scrollViewDidScroll(_ aScrollView: UIScrollView) {
        if _state == .opened {
            text = KSTextEmpty
        }
        if _direction == .horizontal {
            aScrollView.contentOffset.y = 0
        } else {
            aScrollView.contentOffset.x = 0
        }
        updateCaretVisiblity(aScrollView)
    }
    
    func updateCaretVisiblity(_ aScrollView: UIScrollView) {
        switch _direction {
        case .vertical:
            let scrollViewHeight = aScrollView.frame.size.height
            let scrollContentSizeHeight = aScrollView.contentSize.height
            let scrollOffset = aScrollView.contentOffset.y
            
            if (scrollOffset + scrollViewHeight < scrollContentSizeHeight - 10) {
                hideCaret()
                
            } else if (scrollOffset + scrollViewHeight >= scrollContentSizeHeight - 10) {
                showCaret()
            }
            
        case .horizontal:
            let scrollViewWidth = aScrollView.frame.size.width
            let scrollContentSizeWidth = aScrollView.contentSize.width
            let scrollOffset = aScrollView.contentOffset.x
            
            if (scrollOffset + scrollViewWidth < scrollContentSizeWidth - 10) {
                hideCaret()
                
            } else if (scrollOffset + scrollViewWidth >= scrollContentSizeWidth - 10) {
                showCaret()
            }
        }
    }
    
    func hideCaret() {
        tintColor = UIColor.clear
    }
    
    func showCaret() {
        tintColor = _cursorColor
    }
    
}

extension KSTokenField: KSToken.KSTokenGlobalConfig {
    func tokenFont() -> UIFont { _font }
    func contentInset() -> UIEdgeInsets { _contentInset }
    func imagePadding() -> CGFloat { _imagePadding }
    func imagePlacement() -> KSTokenImagePlacement { _imagePlacement }
}
