//
//  InactiveList.swift
//  Examples
//
//  Created by Splash on 10.07.25.
//  Copyright © 2025 Khawar Shahzad. All rights reserved.
//

import UIKit

class InactiveList: UIViewController {
    
    @IBOutlet weak var tokenView: KSTokenView!
    @IBOutlet weak var tableView: UITableView!
    
    let names: Array<String> = List.names()
    let tokenImage: UIImage = UIImage(systemName: "xmark.square")!.withTintColor(UIColor(resource: .tokenTitle), renderingMode: .alwaysTemplate)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tokenView.delegate = self
        tokenView.promptText = nil
        tokenView.descriptionText = ""
        tokenView.maximumHeight = 180
        tokenView.shouldAddTokenFromTextInput = false
        tokenView.removesTokensOnEndEditing = false // DEV-7572
        tokenView.searchResultHeight = 0
        tokenView.tokenizingCharacters = []
        tokenView.startInputOnTouch = false
        tokenView.style = .squared
        tokenView.backgroundColor = .clear
        tokenView.shouldSelectTokenOnTap = false
        tokenView.minWidthForInput = 0
        tokenView.tokenize()

        var initialTokens: [KSToken] = []
        for i in 0...10 {
            let token = tagForTitle(title: names[i])
            initialTokens.append(token)
            
        }
        tokenView.addTokens(initialTokens)
    }
    
    func tagForTitle(title: String) -> KSToken {
        let token: KSToken = KSToken(title: title,  image: tokenImage)
        token.tokenBackgroundColor = UIColor(resource: .tokenBackground)
        token.tokenTextColor = UIColor(resource: .tokenTitle)
        token.imageSizeMode = .fixed(size: CGSize(width: 16, height: 16), alignment: .center)
        return token
    }
}

extension InactiveList: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let token = tagForTitle(title: names[indexPath.row])
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self, token] in
            self?.tokenView.addToken(token)
        }, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension InactiveList: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentfier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentfier) as UITableViewCell?
        
        if (cell == nil) {
            cell = UITableViewCell(style:UITableViewCell.CellStyle.default, reuseIdentifier:cellIdentfier)
        }
        
        cell?.textLabel?.text = names[indexPath.row]
        
        return cell!
    }
}

extension InactiveList: KSTokenViewDelegate {
    func tokenView(_ tokenView: KSTokenView, performSearchWithString string: String, completion: ((_ results: [AnyObject]) -> Void)?) {}
    func tokenView(_ tokenView: KSTokenView, displayTitleForObject object: AnyObject) -> String { return "" }
    func tokenView(_ tokenView: KSTokenView, shouldAddToken token: KSToken) -> Bool { true }
    func tokenViewDidHideSearchResults(_ tokenView: KSTokenView) {}
    func tokenView(_ tokenView: KSTokenView, didAddToken token: KSToken) {}
    func tokenView(_ tokenView: KSTokenView, didDeleteToken token: KSToken) {}
    func tokenViewDidDeleteAllToken(_ tokenView: KSTokenView) {}
    func tokenView(_ tokenView: KSTokenView, didClickOnTokenImage token: KSToken) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self, token] in
            self?.tokenView.deleteToken(token)
        }, completion: nil)
    }
}
