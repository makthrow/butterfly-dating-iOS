//
//  SettingsViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 10/12/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var womensSwitch: UISwitch!
    
    @IBOutlet weak var mensSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackButton()
        
        loadPhoto()
        
        let defaults = UserDefaults.standard
        mensSwitch.isOn = defaults.bool(forKey: "men")
        womensSwitch.isOn = defaults.bool(forKey: "women")
        mensSwitch.addTarget(self, action: #selector(valueChanged), for: UIControlEvents.valueChanged)
        womensSwitch.addTarget(self, action: #selector(valueChanged), for: UIControlEvents.valueChanged)
        
        let name = defaults.object(forKey: "firstName") as? String
        let age = defaults.integer(forKey: "age")
        if name != nil {
            nameLabel.text = "\(name!), \(age)"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupBackButton() {
        let backButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
    func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func valueChanged(sender: AnyObject) {
        let defaults = UserDefaults.standard

        if sender as! NSObject == mensSwitch {
            defaults.set(mensSwitch.isOn, forKey: "men")
            print ("mens switch: \(mensSwitch.isOn)")
        }
        else if sender as! NSObject == womensSwitch {
            defaults.set(womensSwitch.isOn, forKey: "women")
            print ("womens switch: \(womensSwitch.isOn)")
        }
        
        // update user defaults to tell our views that they need to update match lists based on new settings
        defaults.set(true, forKey: "needToUpdateMatches")
    }

    func loadPhoto() {
        getFBProfilePicFor(userID: Constants.userID, callback: {
            image in
            DispatchQueue.main.async(execute: {
            self.imageView.layer.masksToBounds = true
            self.imageView.contentMode = .center
            self.imageView.image = image
            })
        })
    }
    @IBAction func logoutButton(_ sender: UIButton) {
        try! FIRAuth.auth()!.signOut()
        FBSDKLoginManager().logOut()
        self.performSegue(withIdentifier: Constants.ToLoginVC, sender: self)
    }
    
    
    @IBAction func faqContactButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: Constants.ToFAQContactVC, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        var destination = segue.destination as? UIViewController

        if segue.identifier == Constants.eulaToHTMLVC {
            if let navCon = destination as? UINavigationController {
                destination = navCon.visibleViewController
            }
            let vc =  destination as! HTMLViewController
            vc.vcType = "eula"
        }
        if segue.identifier == Constants.privacyToHTMLVC {
            let navVC = segue.destination as? UINavigationController
            let vc = navVC?.topViewController as! HTMLViewController
            
            vc.vcType = "privacyTOS"
        }
        
    }
    @IBAction func privacyTOSButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: Constants.privacyToHTMLVC, sender: self)
    }
    @IBAction func eulaButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: Constants.eulaToHTMLVC, sender: self)
    }
}
