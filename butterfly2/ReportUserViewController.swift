//
//  ReportUserViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 11/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit

class ReportUserViewController: UIViewController {

    var userIDToReport:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print ("user id: \(userIDToReport)")

        
    }
    @IBAction func inappropriateContentButton(_ sender: UIButton) {
        
    }
    @IBAction func spamOrFakeUserButton(_ sender: UIButton) {
        
    }

    @IBAction func otherButton(_ sender: UIButton) {
        
    }
    @IBAction func cancelButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }


}
