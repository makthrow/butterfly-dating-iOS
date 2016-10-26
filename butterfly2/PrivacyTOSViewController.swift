//
//  PrivacyTOSViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 10/24/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit
import WebKit

class PrivacyTOSViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!

    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let htmlFile = Bundle.main.path(forResource: "PrivacyPolicy_Oct242016_", ofType: "html")
        let htmlString = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        webView.loadHTMLString(htmlString!, baseURL: nil)
        
        setupBackButton()
        navigationItem.title = "Privacy and Terms of Service"

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    func setupBackButton() {
        let backButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
}
