//
//  FAQContactViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 10/24/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit
import MessageUI
class FAQContactViewController: UIViewController , MFMailComposeViewControllerDelegate{

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var contactLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Contact Us"
        setupBackButton()
        // Do any additional setup after loading the view.
        self.textView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
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

    @IBAction func submitButtonPressed(_ sender: UIBarButtonItem) {
        
        getUserFacebookInfoFor(userID: (Constants.userID), callback:  {
            dic in
            if dic != nil {
                let birthday = dic!["birthday"] as? String
                let name = dic!["name"] as? String
                let gender = dic!["gender"] as? String
                let email = dic!["email"] as? String
                
                var contactDic: Dictionary<String, Any>
                
                contactDic = [
                    "message": self.textView.text,
                    "timestamp": Constants.firebaseServerValueTimestamp as AnyObject,
                    "name": name ?? "",
                    "gender": gender ?? "",
                    "email" : email ?? "",
                    "age" : calculateAgeFromDateString(birthdayString: birthday!)
                ]
                Constants.CONTACT_REF.childByAutoId().setValue(contactDic)
                self.showSentNotification()
            }
            
        })
    }
    
    func showSentNotification () {

        let alertController = UIAlertController(title: "Sent", message: "Thank you for contacting us. We will reply to your facebook provided email", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            self.backButtonTapped()
        }
        alertController.addAction(okAction)
        topMostController().present(alertController, animated: true, completion: nil)
        
    }
    

}
