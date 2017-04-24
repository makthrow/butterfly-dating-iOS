//
//  CreateAccountViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 7/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit
import FirebaseAuth

class CreateAccountViewController: UIViewController {
    
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBAction func makeAccountButton(_ sender: UIButton) {
        
        if let email = emailField.text, let password = passwordField.text, let username = usernameField.text {
            FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
                
                if error != nil {
                    self.signupErrorAlert("Oops!", message: "Having some trouble creating your account. Try again.")
                }
                
                else {
                    // Enter the app.
                    self.performSegue(withIdentifier: "NewUserLoggedIn", sender: nil)
                }
            }
        }
            
        else {
            signupErrorAlert(":(", message: "no email, password, or username.")
        }
        
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {})
        
    }
    
    
    func signupErrorAlert(_ title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
}
