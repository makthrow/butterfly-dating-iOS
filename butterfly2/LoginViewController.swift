//
//  LoginViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 7/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import FBSDKCoreKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    let tabBarVC: UIViewController! = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarController")

    @IBOutlet weak var logoImageView: UIImageView!
    
//    @IBOutlet weak var emailField: UITextField!
//    
//    @IBOutlet weak var passwordField: UITextField!
//    
    override func viewDidLoad() {
        super.viewDidLoad()

        let loginButton = FBSDKLoginButton.init(frame: CGRect(x: 0, y: 0, width: 250, height: 50))

        loginButton.delegate = self
        loginButton.center.y = self.view.bounds.height - 60
        loginButton.center.x = self.view.center.x
        loginButton.readPermissions = ["public_profile", "email", "user_friends", "user_education_history", "user_birthday"]
        
        self.view.addSubview(loginButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        FIRAuth.auth()?.addStateDidChangeListener {auth, user in
            if user != nil  {
                self.performSegue(withIdentifier: Constants.ToTabBarController, sender: self)
            }
        }
//        if FIRAuth.auth()?.currentUser != nil {
//            self.performSegue(withIdentifier: Constants.ToTabBarController, sender: self)
//        }
    }
    
    /*
    @IBAction func loginButton(_ sender: UIButton) {
        if let email = self.emailField.text, let password = self.passwordField.text {
            
            if email != "" && password != "" {
                
                FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                    
                    if error != nil {
                        print(error)
                        self.loginErrorAlert("Oops!", message: "Check your username and password.")
                    }
                        
                    else {
                        
                    }
                }
                
            }
        }
        else {
            
            // There was a problem
            
            loginErrorAlert("Oops!", message: "no see email, password, username.")
        }
        
    }
 
    
    func loginErrorAlert(_ title: String, message: String) {
        
        // Called upon login error to let the user know login didn't work.
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
 */
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        else if result.isCancelled {
            return
        }
        else { // SUCCESS LOGIN
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in

            }
            
        }

    }
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print ("logged out of facebook")
    }

}
