//
//  HTMLViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 11/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import UIKit
import WebKit


class HTMLViewController: UIViewController, WKNavigationDelegate {
    
    var vcType:String?
    
    var webView: WKWebView!
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var htmlString:String? = nil
        let htmlString_privacy_policy = "PrivacyPolicy_Oct242016_"
        let htmlString_eula = "EULA_11_28_2016"
        
        // "eula" and "privacyTOS" from SettingsViewController
        if vcType == "eula" {
            htmlString = htmlString_eula
            navigationItem.title = "End User License Agreement"

        }
        else if vcType == "privacyTOS" {
            htmlString = htmlString_privacy_policy
            navigationItem.title = "Privacy and Terms of Service"

        }
        else {
            dismiss(animated: true, completion: nil)
        }
        
        
        let htmlFile = Bundle.main.path(forResource: htmlString, ofType: "html")
        let htmlViewString = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        webView.loadHTMLString(htmlViewString!, baseURL: nil)
        
        setupBackButton()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    func setupBackButton() {
        let backButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
}
