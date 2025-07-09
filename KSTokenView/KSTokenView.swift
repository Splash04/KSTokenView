//
//  KSTokenView.swift
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


@objc public enum KSTokenViewStyle: Int {
    case rounded
    case squared
}

@objc public enum KSTokenViewScrollDirection: Int {
    case vertical
    case horizontal
}

@objc public enum KSTokenImagePlacement: Int {
    case left
    case right
}

public enum KSTokenImageAlignment: Equatable {
    case top
    case left
    case right
    case center
    case bottom
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

public enum KSTokenImageSizeMode: Equatable {
    case fixed(size: CGSize, alignment: KSTokenImageAlignment)
    case fontBased(insets: UIEdgeInsets)
}

//MARK: - KSTokenViewDelegate
//__________________________________________________________________________________
//

@objc public protocol KSTokenViewDelegate {
    
    /**
     Asks the delegate whether the token should be added
     
     - parameter tokenView: KSTokenView object
     - parameter token:     KSToken object that needs to be added
     
     - returns: Boolean
     
     */
    @objc optional func tokenView(_ tokenView: KSTokenView, shouldAddToken token: KSToken) -> Bool
    @objc optional func tokenView(_ tokenView: KSTokenView, willAddToken token: KSToken)
    @objc optional func tokenView(_ tokenView: KSTokenView, shouldChangeAppearanceForToken token: KSToken) -> KSToken?
    @objc optional func tokenView(_ tokenView: KSTokenView, didAddToken token: KSToken)
    @objc optional func tokenView(_ tokenView: KSTokenView, didFailToAdd token: KSToken)
    
    @objc optional func tokenView(_ tokenView: KSTokenView, shouldDeleteToken token: KSToken) -> Bool
    @objc optional func tokenView(_ tokenView: KSTokenView, willDeleteToken token: KSToken)
    @objc optional func tokenView(_ tokenView: KSTokenView, didDeleteToken token: KSToken)
    @objc optional func tokenView(_ tokenView: KSTokenView, didFailToDeleteToken token: KSToken)
    
    @objc optional func tokenView(_ tokenView: KSTokenView, willChangeFrameWithX: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)
    @objc optional func tokenView(_ tokenView: KSTokenView, didChangeFrameWithX: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)
    
    @objc optional func tokenView(_ tokenView: KSTokenView, didSelectToken token: KSToken)
    @objc optional func tokenView(_ tokenView: KSTokenView, didClickOnTokenImage token: KSToken)
    @objc optional func tokenViewDidBeginEditing(_ tokenView: KSTokenView)
    @objc optional func tokenViewDidEndEditing(_ tokenView: KSTokenView)
    
    
    @objc func tokenView(_ tokenView: KSTokenView, performSearchWithString string: String, completion: ((_ results: Array<AnyObject>) -> Void)?)
    @objc func tokenView(_ tokenView: KSTokenView, displayTitleForObject object: AnyObject) -> String
    @objc optional func tokenView(_ tokenView: KSTokenView, withObject object: AnyObject, tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell
    @objc optional func tokenView(_ tokenView: KSTokenView, didSelectRowAtIndexPath indexPath: IndexPath)
    
    /**
     didSelectRowObject : Notifies delegate when a suggestion is selected from table view by the user
     - parameter object: Selected object which is an element of "_resultArray" array
     */
    @objc optional func tokenView(_ tokenView: KSTokenView, didSelectRowObject object: AnyObject)
    
    /**
     tokenObjectsFor : Notifies delegate when a suggestion is selected from table view by the user and expects list of token objects to be returned by the delegate, that are to be added in token Field for the given selection.
     This function enables support of adding multiple objects in token Field, on selecting a single suggestion object in suggestion table view.
     
     - parameter selectedRowObject: Selected object which is an element of "_resultArray" array
     
     - returns: Array of objects which should be added to tokens field
     
     Note: If the function is not implemented by delegate, then the selected suggestion object (selectedRowObject) itself is added to tokens field. If an empty array is returned for a selection, then no token is added in tokens field.
     */
    @objc optional func tokenView(_ tokenView: KSTokenView, tokenObjectsFor selectedRowObject: AnyObject) -> [AnyObject]
    
    @objc optional func tokenViewShouldDeleteAllToken(_ tokenView: KSTokenView) -> Bool
    @objc optional func tokenViewWillDeleteAllToken(_ tokenView: KSTokenView)
    @objc optional func tokenViewDidDeleteAllToken(_ tokenView: KSTokenView)
    @objc optional func tokenViewDidFailToDeleteAllTokens(_ tokenView: KSTokenView)
    
    @objc optional func tokenViewDidShowSearchResults(_ tokenView: KSTokenView)
    @objc optional func tokenViewDidHideSearchResults(_ tokenView: KSTokenView)
    
    @objc optional func tokenView(_ tokenView: KSTokenView, didLongPress token: KSToken)
}

//MARK: - KSTokenView
//__________________________________________________________________________________
//

/**
 *  A KSTokenView is a control that displays a collection of tokens in a an editable UITextField and sends messages to delegate object. It can be used to gather small amounts of text from user and perform search operation. User can choose multiple search results, which are displayed as token in UITextField.
 */
open class KSTokenView: UIView {
    
    //MARK: - Private Properties
    //__________________________________________________________________________________
    //
    fileprivate var _tokenField: KSTokenField!
    fileprivate var _searchTableView: UITableView = UITableView(frame: .zero, style: UITableView.Style.plain)
    fileprivate var _resultArray = [AnyObject]()
    fileprivate var _showingSearchResult = false
    fileprivate var _indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    fileprivate var _searchResultHeight: CGFloat = Constants.Defaults.searchResultHeight
    fileprivate var _lastSearchString: String = ""
    fileprivate var _intrinsicContentHeight: CGFloat = UIView.noIntrinsicMetric
    
    //MARK: - Public Properties
    //__________________________________________________________________________________
    //
    
    /// returns the value of field
    @objc open var text : String {
        get {
            return String(_tokenField.text![_tokenField.text!.startIndex..<self._tokenField.text!.endIndex])
        }
        set (string) {
            _tokenField.text = KSTextEmpty+string
        }
    }
    
    /// default is true. token can be deleted with keyboard 'x' button
    @objc open var shouldDeleteTokenOnBackspace = true
    
    /// Only works for iPhone now, not iPad devices. default is false. If true, search results are hidden when one of them is selected
    @objc open var shouldHideSearchResultsOnSelect = false
    
    /// default is false. If true, already added token still appears in search results
    @objc open var shouldDisplayAlreadyTokenized = false
    
    /// default is ture. Sorts the search results alphabatically according to title provided by tokenView(_:displayTitleForObject) delegate
    @objc open var shouldSortResultsAlphabatically = true
    
    /// default is true. If false, token can only be added from picking search results. All the text input would be ignored
    @objc open var shouldAddTokenFromTextInput = true
    
    /// default is 1. If set to 0, it shows all search results without typing anything
    @objc open var minimumCharactersToSearch = 1
    
    /// default is nil
    @objc weak open var delegate: KSTokenViewDelegate?
    
    /// default is .Vertical.
    @objc open var direction: KSTokenViewScrollDirection = Constants.Defaults.direction {
        didSet {
            _updateTokenField()
        }
    }
    
    /// Default is blackColor
    @objc open var inputFieldTextColor: UIColor? {
        didSet {
            if (oldValue != textColor && _tokenField != nil) {
                _tokenField.textColor = textColor
            }
        }
    }
    
    /// Default is whiteColor
    @objc override open var backgroundColor: UIColor? {
        didSet {
            if (oldValue != backgroundColor && _tokenField != nil) {
                _tokenField.backgroundColor = backgroundColor
            }
        }
    }
    
    /// Default is (TokenViewWidth, 200)
    @objc open var searchResultHeight: CGFloat = Constants.Defaults.searchResultHeight {
        didSet {
            _searchResultHeight = searchResultHeight
            _searchTableView.frame.size.height = searchResultHeight
        }
    }
    
    /// Default is white
    @objc open var searchResultBackgroundColor: UIColor = Constants.Defaults.searchResultBackgroundColor {
        didSet {
            _searchTableView.backgroundColor = searchResultBackgroundColor
        }
    }
    
    /// default is UIColor.blueColor()
    @objc open var activityIndicatorColor: UIColor = UIColor.blue {
        didSet {
            _indicator.color = activityIndicatorColor
        }
    }
    
    /// default is 120.0. After maximum limit is reached, tokens starts scrolling vertically
    @objc open var maximumHeight: CGFloat = 120.0 {
        didSet {
            _tokenField.maximumHeight = maximumHeight
        }
    }
    
    /// default is gray
    @objc open var cursorColor: UIColor = Constants.Defaults.cursorColor {
        didSet {
            _updateTokenField()
        }
    }
    
    /// default is vertiacal: 2, horisontal: 8. Token content insest.
    @objc open var contentInset: UIEdgeInsets = KSToken.Constants.Defaults.contentInsets {
        didSet {
            if (oldValue != contentInset) {
                _updateTokenField()
            }
        }
    }
    
    /// default is 0. Padding between image and title.
    @objc open var imagePadding: CGFloat = KSToken.Constants.Defaults.imagePadding {
        didSet {
            if (oldValue != imagePadding) {
                _updateTokenField()
            }
        }
    }
    
    /// default is right. Padding between image and title.
    @objc open var imagePlacement: KSTokenImagePlacement = KSToken.Constants.Defaults.imagePlacement {
        didSet {
            if (oldValue != imagePlacement) {
                _updateTokenField()
            }
        }
    }

    /// default is 5.0. Horizontal margin between tokens
    @objc open var marginX: CGFloat = Constants.Defaults.marginX {
        didSet {
            if (oldValue != marginX) {
                _updateTokenField()
            }
        }
    }
    
    /// default is 5.0. Vertical margin between tokens
    @objc open var marginY: CGFloat = Constants.Defaults.marginY {
        didSet {
            if (oldValue != marginY) {
                _updateTokenField()
            }
        }
    }
    
    /// default is 0. Horizontal buffer between prompt and content
    @objc open var bufferX: CGFloat = Constants.Defaults.bufferX {
        didSet {
            if (oldValue != bufferX) {
                _updateTokenField()
            }
        }
    }
    
    /// default is UIFont.systemFontOfSize(16)
    @objc open var font: UIFont = KSToken.Constants.Defaults.font {
        didSet {
            if (oldValue != font) {
                _updateTokenField()
            }
        }
    }
    
    /// default is 50.0. Caret moves to new line if input width is less than this value
    @objc open var minWidthForInput: CGFloat = 50.0 {
        didSet {
            if (oldValue != minWidthForInput) {
                _updateTokenField()
            }
        }
    }
    
    /// default is ", ". Used to separate titles when untoknized
    @objc open var separatorText: String = Constants.Defaults.separatorText {
        didSet {
            if (oldValue != separatorText) {
                _updateTokenField()
            }
        }
    }
    
    /// An array of string values. Default values are "." and ",". Token is created with typed text, when user press any of the character mentioned in this Array
    @objc open var tokenizingCharacters = [".", ","]
    
    /// default is 0.25.
    @objc open var animateDuration: TimeInterval = 0.25 {
        didSet {
            if (oldValue != animateDuration) {
                _updateTokenField()
            }
        }
    }
    
    /// default is true. When resignFirstResponder is called tokens are removed and description is displayed.
    @objc open var removesTokensOnEndEditing: Bool = true {
        didSet {
            if (oldValue != removesTokensOnEndEditing) {
                _updateTokenField()
            }
        }
    }
    
    /// Default is "selections"
    @objc open var descriptionText: String = "selections" {
        didSet {
            if (oldValue != descriptionText) {
                _updateTokenField()
            }
        }
    }
    
    /// set -1 for unlimited.
    @objc open var maxTokenLimit: Int = -1 {
        didSet {
            if (oldValue != maxTokenLimit) {
                _updateTokenField()
            }
        }
    }
    
    /// default is "To: "
    @objc open var promptText: String = "To: " {
        didSet {
            if (oldValue != promptText) {
                _updateTokenField()
            }
        }
    }
    
    /// default is true. If false, cannot be edited
    @objc open var editable: Bool = true {
        didSet {
            _tokenField.isEnabled = editable
        }
    }
    
    /// default is nil
    @objc open var placeholder: String {
        get {
            return _tokenField.placeholder!
        }
        set {
            _tokenField.placeholder = newValue
        }
    }
    
    /// default is UIColor.grayColor()
    @objc open var promptColor: UIColor = UIColor.gray {
        didSet {
            _updateTokenField()
        }
    }
    
    /// default is UIColor.grayColor()
    @objc open var placeholderColor: UIColor = UIColor.gray {
        didSet {
            _updateTokenField()
        }
    }
    
    /// default is UIColor.blackColor()
    @objc open var textColor: UIColor = UIColor.black {
        didSet {
            _updateTokenField()
        }
    }
    
    /// default is .Rounded, creates rounded corner
    @objc open var style: KSTokenViewStyle = .rounded {
        didSet(newValue) {
            _updateTokenFieldLayout(style)
        }
    }
    
    public var tokenFieldMaxY: CGFloat {
        _tokenField.frame.maxY
    }
    
    //MARK: - Constructors
    //__________________________________________________________________________________
    //
    
    /**
     Create and inialize KSTokenView object
     
     - parameter frame: An object of type CGRect
     
     - returns: KSTokenView object
     */
    override public init(frame: CGRect) {
        super.init(frame: frame)
        _commonSetup()
    }
    
    /**
     Create and inialize KSTokenView object from Interface builder
     
     - parameter aDecoder: An object of type NSCoder
     
     - returns: KSTokenView object
     */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        _commonSetup()
    }
    
    //MARK: - Common Setup
    //__________________________________________________________________________________
    //
    
    fileprivate func _commonSetup() {
        backgroundColor = UIColor.clear
        clipsToBounds = true
        _tokenField = KSTokenField(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        _tokenField.textColor = UIColor.black
        _tokenField.isEnabled = true
        _tokenField.tokenFieldDelegate = self
        _tokenField.placeholder = ""
        _tokenField.autoresizingMask = [.flexibleWidth]
        _updateTokenField()
        addSubview(_tokenField)
        
        _indicator.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        _indicator.hidesWhenStopped = true
        _indicator.stopAnimating()
        _indicator.color = activityIndicatorColor
        
        _searchTableView.frame = CGRect(x: 0, y: frame.height, width: frame.width, height: _searchResultHeight)
        _searchTableView.delegate = self
        _searchTableView.dataSource = self
        
        _hideSearchResults()
        _intrinsicContentHeight = _tokenField.bounds.height
        invalidateIntrinsicContentSize()
    }
    
    //MARK: - Layout Changes
    //__________________________________________________________________________________
    //
    override open func layoutSubviews() {
        _tokenField.updateLayout(false)
        _searchTableView.frame.size = CGSize(width: frame.width, height: _searchResultHeight)
    }
    
    override open var intrinsicContentSize : CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: _intrinsicContentHeight)
    }
    
    //MARK: - Public Methods
    //__________________________________________________________________________________
    //
    
    /// Changes the returnKeyType of KSTokenField
    open func returnKeyType(type: UIReturnKeyType) {
        _tokenField.returnKeyType = type
    }
    
    //MARK: - Private Methods
    //__________________________________________________________________________________
    //
    
    fileprivate func _updateTokenField() {
        _tokenField.parentView = self
    }
    
    fileprivate func _updateTokenFieldLayout(_ newValue: KSTokenViewStyle) {
        switch (newValue) {
        case .rounded:
            _tokenField.borderStyle = .roundedRect
            backgroundColor = UIColor.clear
            
        case .squared:
            _tokenField.borderStyle = .bezel
            backgroundColor = _tokenField.backgroundColor
        }
    }
    
    fileprivate func _lastToken() -> KSToken? {
        _tokenField.tokens.last
    }
    
    fileprivate func _removeToken(_ token: KSToken, removingAll: Bool = false) {
        if token.sticky {return}
        if (!removingAll) {
            var shouldRemoveToken: Bool? = true
            
            if let shouldRemove = delegate?.tokenView?(self, shouldDeleteToken: token) {
                shouldRemoveToken = shouldRemove
            }
            if (shouldRemoveToken != true) {
                delegate?.tokenView?(self, didFailToDeleteToken: token)
                return
            }
            delegate?.tokenView?(self, willDeleteToken: token)
        }
        _tokenField.removeToken(token, removingAll: removingAll)
        if (!removingAll) {
            delegate?.tokenView?(self, didDeleteToken: token)
        }
    }
    
    fileprivate func _canAddMoreToken() -> Bool {
        if (maxTokenLimit != -1 && _tokenField.tokens.count >= maxTokenLimit) {
            _hideSearchResults()
            return false
        }
        return true
    }
    
    
    /**
     Returns an Array of KSToken objects
     
     - returns: Array of KSToken objects
     */
    open func tokens () -> Array<KSToken>? {
        return _tokenField.tokens
    }
    
    //MARK: - Add Token
    //__________________________________________________________________________________
    //
    
    
    /**
     Creates KSToken from input text, when user press keyboard "Done" button
     
     - parameter tokenField: Field to add in
     
     - returns: Boolean if token is added
     */
    fileprivate func _addTokenFromUntokenizedText(_ tokenField: KSTokenField) -> Bool {
        if (shouldAddTokenFromTextInput && tokenField.text != nil && tokenField.text != KSTextEmpty) {         
            let trimmedString = tokenField.text!.trimmingCharacters(in: CharacterSet.whitespaces)
            addTokenWithTitle(trimmedString)
            _hideSearchResults()
            return true
        }
        return false
    }
    
    /**
     Creates and add a new KSToken object
     
     - parameter title:       Title of token
     - parameter tokenObject: Any custom object
     
     - returns: KSToken object
     */
    @discardableResult open func addTokenWithTitle(_ title: String, tokenObject: AnyObject? = nil) -> KSToken? {
        let token = KSToken(title: title, object: tokenObject)
        return addToken(token)
    }
    
    
    /**
     Creates and add a new KSToken object
     
     - parameter token: KSToken object
     
     - returns: KSToken object
     */
    @discardableResult open func addToken(_ token: KSToken) -> KSToken? {
        guard _canAddMoreToken() else  {
            return nil
        }
        
        let shouldAddToken: Bool
        if let shouldAdd = delegate?.tokenView?(self, shouldAddToken: token) {
            shouldAddToken = shouldAdd
        } else {
            shouldAddToken = true
        }
        
        guard shouldAddToken else {
            delegate?.tokenView?(self, didFailToAdd: token)
            return nil
        }
        
        delegate?.tokenView?(self, willAddToken: token)
        var addedToken: KSToken?
        if let updatedToken = delegate?.tokenView?(self, shouldChangeAppearanceForToken: token) {
            addedToken = _tokenField.addToken(updatedToken)
        } else {
            addedToken = _tokenField.addToken(token)
        }
        
        delegate?.tokenView?(self, didAddToken: addedToken!)
        _ = _canAddMoreToken()
        return addedToken
    }
    
    
    //MARK: - Delete Token
    //__________________________________________________________________________________
    //
    
    /**
     Deletes an already added KSToken object
     
     - parameter token: KSToken object
     */
    open func deleteToken(_ token: KSToken) {
        _removeToken(token)
    }
    
    /**
     Searches for KSToken object and deletes
     
     - parameter object: Custom object
     */
    open func deleteTokenWithObject(_ object: AnyObject?) {
        guard let object = object else { return }
        for token in _tokenField.tokens {
            guard let tokenObject = token.object else { continue }
            if (tokenObject.isEqual(object)) {
                _removeToken(token)
                break
            }
        }
    }
    
    /**
     Deletes all added tokens. This doesn't delete sticky token
     */
    open func deleteAllTokens() {
        if (_tokenField.tokens.count == 0) {return}
        var shouldDeleteAllTokens: Bool? = true
        
        if let shouldRemoveAll = delegate?.tokenViewShouldDeleteAllToken?(self) {
            shouldDeleteAllTokens = shouldRemoveAll
        }
        
        if (shouldDeleteAllTokens != true) {
            delegate?.tokenViewDidFailToDeleteAllTokens?(self)
            return
        }
        
        delegate?.tokenViewWillDeleteAllToken?(self)
        for token in _tokenField.tokens {_removeToken(token, removingAll: true)}
        _tokenField.updateLayout()
        delegate?.tokenViewDidDeleteAllToken?(self)
        
        if (_showingSearchResult) {
            _startSearchWithString(_lastSearchString)
        }
    }
    
    /**
     Deletes last added KSToken object
     */
    open func deleteLastToken() {
        guard let token = _lastToken() else { return }
        _removeToken(token)
    }
    
    /**
     Deletes selected KSToken object
     */
    open func deleteSelectedToken() {
        guard let token = selectedToken() else { return }
        _removeToken(token)
    }
    
    /**
     Returns Selected KSToken object
     
     - returns: KSToken object
     */
    open func selectedToken() -> KSToken? {
        return _tokenField.selectedToken
    }
    
    
    //MARK: - KSTokenFieldDelegates
    //__________________________________________________________________________________
    //
    func tokenFieldDidBeginEditing(_ tokenField: KSTokenField) {
        delegate?.tokenViewDidBeginEditing?(self)
        tokenField.tokenize()
        if (minimumCharactersToSearch == 0) {
            _startSearchWithString("")
        }
    }
    
    func tokenFieldDidEndEditing(_ tokenField: KSTokenField) {
        delegate?.tokenViewDidEndEditing?(self)
        tokenField.untokenize()
        _hideSearchResults()
    }
    
    open override var isFirstResponder : Bool {
        return _tokenField.isFirstResponder
    }
    
    override open func becomeFirstResponder() -> Bool {
        return _tokenField.becomeFirstResponder()
    }
    
    @discardableResult override open func resignFirstResponder() -> Bool {
        if (!_addTokenFromUntokenizedText(_tokenField)) {
            _tokenField.resignFirstResponder()
        }
        return false
    }
    
    //MARK: - Search
    //__________________________________________________________________________________
    //
    
    /**
     Triggers the search after user input text
     
     - parameter string: Search keyword
     */
    fileprivate func _startSearchWithString(_ string: String) {
        guard _canAddMoreToken() else { return }
        _showEmptyResults()
        _showActivityIndicator()
        
        let trimmedSearchString = string.trimmingCharacters(in: CharacterSet.whitespaces)
        delegate?.tokenView(self, performSearchWithString:trimmedSearchString, completion: { [weak self] (results) -> Void in
            guard let self else { return }
            self._hideActivityIndicator()
            if !results.isEmpty {
                self._displayData(results)
            }
        })
    }
    
    fileprivate func _displayData(_ results: Array<AnyObject>) {
        _resultArray = _filteredSearchResults(results)
        _searchTableView.reloadData()
        _showSearchResults()
    }
    
    fileprivate func _showEmptyResults() {
        _resultArray.removeAll(keepingCapacity: false)
        _searchTableView.reloadData()
        _showSearchResults()
    }
    
    fileprivate func _showSearchResults() {
        guard !_showingSearchResult else {return}
        _showingSearchResult = true
        addSubview(_searchTableView)
        let tokenFieldHeight = _tokenField.frame.height
        _searchTableView.isHidden = false
        _changeHeight(tokenFieldHeight)
        delegate?.tokenViewDidShowSearchResults?(self)
    }
    
    fileprivate func _hideSearchResults() {
        guard _showingSearchResult else {return}
        _showingSearchResult = false
        let searchTableView = self._searchTableView
        _changeHeight(_tokenField.frame.height) {
            searchTableView.isHidden = true
            searchTableView.removeFromSuperview()
        }
        delegate?.tokenViewDidHideSearchResults?(self)
    }
    
    fileprivate func _repositionSearchResults(_ height: CGFloat) {
        guard _showingSearchResult else { return }
        _searchTableView.frame.origin = CGPoint(x: 0, y: height)
    }
    
    fileprivate func _filteredSearchResults(_ results: Array <AnyObject>) -> Array <AnyObject> {
        var filteredResults: Array<AnyObject> = Array()
        
        for object: AnyObject in results {
            // Check duplicates in array
            var shouldAdd = !(filteredResults as NSArray).contains(object)
            
            if (shouldAdd) {
                if (!shouldDisplayAlreadyTokenized && _tokenField.tokens.count > 0) {
                    
                    // Search if already tokenized
                    for token: KSToken in _tokenField.tokens {
                        guard let tokenObject = token.object else { continue }
                        if (object.isEqual(tokenObject)) {
                            shouldAdd = false
                            break
                        }
                    }
                }
                
                if (shouldAdd) {
                    filteredResults.append(object)
                }
            }
        }
        
        if (shouldSortResultsAlphabatically) {
            return filteredResults.sorted(by: { s1, s2 in return self._sortStringForObject(s1) < self._sortStringForObject(s2) })
        }
        return filteredResults
    }
    
    fileprivate func _sortStringForObject(_ object: AnyObject) -> String {
        let title = (delegate?.tokenView(self, displayTitleForObject: object))!
        return title
    }
    
    fileprivate func _showActivityIndicator() {
        _indicator.startAnimating()
        _searchTableView.tableHeaderView = _indicator
    }
    
    fileprivate func _hideActivityIndicator() {
        _indicator.stopAnimating()
        _searchTableView.tableHeaderView = nil
    }
    
    fileprivate func _changeHeight(_ tokenFieldHeight: CGFloat, completion: (() -> Void)? = nil) {
        let fullHeight = tokenFieldHeight + (_showingSearchResult ? _searchResultHeight : 0.0)
        delegate?.tokenView?(self, willChangeFrameWithX: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: fullHeight)
        self._repositionSearchResults(tokenFieldHeight)
        
        UIView.animate(
            withDuration: animateDuration,
            animations: {
                self._tokenField.frame.size.height = tokenFieldHeight
                self.frame.size.height = fullHeight
                self._intrinsicContentHeight = fullHeight
                self.invalidateIntrinsicContentSize()
                self.superview?.layoutIfNeeded()
            },
            completion: {completed in
                completion?()
                if (completed) {
                    self.delegate?.tokenView?(self, didChangeFrameWithX: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: fullHeight)
                }
            })
    }
    
    //MARK: - Memory Mangement
    //__________________________________________________________________________________
    //
    deinit {
        
    }
    
}

//MARK: - Extension KSTokenFieldDelegate
//__________________________________________________________________________________
//
extension KSTokenView : KSTokenFieldDelegate {
    
    func tokenFieldDidSelectToken(_ token: KSToken) {
        delegate?.tokenView?(self, didSelectToken: token)
    }
    
    func tokenFieldDidClickOnTokenImage(_ token: KSToken) {
        delegate?.tokenView?(self, didClickOnTokenImage: token)
    }
    
    func tokenFieldShouldChangeHeight(_ height: CGFloat) {
        _changeHeight(height)
    }
    
    func tokenLongPressed(_ token: KSToken) {
        delegate?.tokenView?(self, didLongPress: token)
    }
    
}


//MARK: - Extension UITextFieldDelegate
//__________________________________________________________________________________
//
extension KSTokenView : UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // If backspace is pressed
        if (!_tokenField.tokens.isEmpty) && _tokenField.text == KSTextEmpty && string.isEmpty == true && shouldDeleteTokenOnBackspace {
            if let lastToken = _lastToken() {
                if let _ = selectedToken() {
                    deleteSelectedToken()
                } else {
                    _tokenField.selectToken(lastToken)
                }
            }
            return false
        }
        
        // Prevent removing KSTextEmpty
        if string.isEmpty && _tokenField.text == KSTextEmpty {
            return false
        }
        
        var searchString: String
        let olderText = _tokenField.text ?? ""
        var olderTextTrimmed = olderText
        
        // remove the empty text marker from the beginning of the string
        if olderText.first == KSTextEmpty.first {
            olderTextTrimmed = String(olderText.dropFirst())
        }
        
        // Check if character is removed at some index
        // Remove character at that index
        if string.isEmpty {
            // Safely convert NSRange to Swift Range
            if let rangeInText = Range(range, in: olderText) {
                var mutableText = olderText
                mutableText.removeSubrange(rangeInText)
                searchString = mutableText.trimmingCharacters(in: .whitespaces)
            } else {
                // Fallback for invalid range
                searchString = olderText.trimmingCharacters(in: .whitespaces)
            }
        } else { // new character added
            if (tokenizingCharacters.contains(string) && olderText != KSTextEmpty && olderTextTrimmed != "") {
                addTokenWithTitle(olderTextTrimmed, tokenObject: nil)
                _hideSearchResults()
                return false
            }
            // Safely replace characters using NSString to handle NSRange properly
            if let olderTextNSString = olderText as NSString? {
                searchString = olderTextNSString.replacingCharacters(in: range, with: string)
            } else {
                searchString = string
            }
            // Remove the empty text marker if present
            if (searchString.first == KSTextEmpty.first) {
                searchString = String(searchString.dropFirst())
            }
        }
        
        // Allow all other characters
        if (searchString.count >= minimumCharactersToSearch && searchString != "\n") {
            _lastSearchString = searchString
            _startSearchWithString(_lastSearchString)
        } else {
            _hideSearchResults()
        }
        
        _tokenField.scrollViewScrollToEnd()
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }
    
}

//MARK: - Extension UITableViewDelegate
//__________________________________________________________________________________
//

extension KSTokenView : UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.tokenView?(self, didSelectRowAtIndexPath: indexPath)
        //selectedRowObject can either be individual contact or a contact list
        let selectedRowObject: AnyObject = _resultArray[(indexPath as NSIndexPath).row]
        
        delegate?.tokenView?(self, didSelectRowObject: selectedRowObject)
        //Will return multiple participants in case of contact list else will return a single participant.
        let objects: [AnyObject] = delegate?.tokenView?(self, tokenObjectsFor: selectedRowObject) ?? [selectedRowObject]
        
        for object in objects {
            let title  = delegate?.tokenView(self, displayTitleForObject: object)
            let token = KSToken(title: title!, object: object)
            addToken(token)
        }
        
        if shouldHideSearchResultsOnSelect {
            _hideSearchResults()
        } else if !shouldDisplayAlreadyTokenized {
            _resultArray.remove(at: (indexPath as NSIndexPath).row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.left)
        }
    }
    
}

//MARK: - Extension UITableViewDataSource
//__________________________________________________________________________________
//
extension KSTokenView : UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _resultArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let _cell: UITableViewCell = delegate?.tokenView?(self, withObject: _resultArray[(indexPath as NSIndexPath).row], tableView: tableView, cellForRowAtIndexPath: indexPath) {
            cell = _cell
        } else if let _cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) {
            cell = _cell
        } else {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: Constants.cellIdentifier)
        }
        
        let title = delegate?.tokenView(self, displayTitleForObject: _resultArray[(indexPath as NSIndexPath).row])
        cell.textLabel?.text = (title != nil) ? title : "No Title"
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
}

//MARK: - Constants
//__________________________________________________________________________________
//

public extension KSTokenView { enum Constants {} }
public extension KSTokenView.Constants {
    static let cellIdentifier = "KSSearchTableCell"
    
    enum Defaults {
        static let direction: KSTokenViewScrollDirection = .vertical
        static let searchResultHeight: CGFloat = 200
        static let searchResultBackgroundColor = UIColor.white
        static let cursorColor: UIColor = UIColor.gray
        static let marginX: CGFloat = 5.0
        static let marginY: CGFloat = 5.0
        static let bufferX: CGFloat = 0.0
        static let separatorText: String = ", "
    }
}
