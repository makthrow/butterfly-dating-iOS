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
        reportUserInDatabase(type: 1, userIDToReport: userIDToReport!, text: "")
        showReportedAlert()
    }
    @IBAction func spamOrFakeUserButton(_ sender: UIButton) {
        reportUserInDatabase(type: 2, userIDToReport: userIDToReport!, text: "")
        showReportedAlert()

    }
    @IBAction func harassmentButton(_ sender: UIButton) {
        reportUserInDatabase(type: 3, userIDToReport: userIDToReport!, text: "")
        showReportedAlert()
    }
    
    @IBAction func otherButton(_ sender: UIButton) {
        reportUserInDatabase(type: 4, userIDToReport: userIDToReport!, text: "")
        showReportedAlert()
    }

    
    @IBAction func cancelButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    func showReportedAlert() {
        let title = "Thank You For Reporting"
        let message = "Block this User Too? You Won't Be Able To See Their Introductions"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let blockAction = UIAlertAction(title: "Block", style: .destructive) { (action) in
            blockUser(userIDToBlock: self.userIDToReport!)
            self.showBlockedAlert()
        }
        
        let okAction = UIAlertAction(title: "No Thanks", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        alertController.addAction(blockAction)
        
        topMostController().present(alertController, animated: true, completion: nil)
        
    }
    func showBlockedAlert() {
        let title = "Success"
        let message = "User Blocked"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }

        alertController.addAction(okAction)
        topMostController().present(alertController, animated: true, completion: nil)

    }

}
