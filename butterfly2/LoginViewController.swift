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

    @IBOutlet weak var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let loginButton = FBSDKLoginButton.init(frame: CGRect(x: 0, y: 0, width: 250, height: 50))

        loginButton.delegate = self
        loginButton.center.y = self.view.bounds.height - 60
        loginButton.center.x = self.view.center.x
        loginButton.readPermissions = ["public_profile","user_friends", "user_education_history", "user_birthday"]
        
        self.view.addSubview(loginButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        FIRAuth.auth()?.addStateDidChangeListener {auth, user in
            if user != nil  {
                print ("authStateChanged: user not nil")

                self.performSegue(withIdentifier: Constants.ToTabBarController, sender: self)
            }
            else {
                // try not to add any code here. firebase upon sign in will call this multiple times even if the user has signed in already.
            }
        }
    }
    
    func facebookPermissionsRequiredAlert() {
        
        let title = "Facebook Permissions"
        let message = "Butterfly requires you to provide additional Facebook permissions in order to create or use this service. This information is for your and other users' safety, provides more authenticity to profiles, and allows us to better provide support."
        
        // Called upon login if user refuses to provide facebook permissions
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Ask me", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    
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
            
            // check key permissions from facebook granted.
            // if user goes into facebook settings and revokes permissions later, need to handle that somehow
            // but we will have all of the data we need saved upon login
            if verifyFacebookPermissionsGranted(result: result) {
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                if (FBSDKAccessToken.current().tokenString == nil) {
                    print ("FBSDKAccessToken: nil)")
                }
                else {
                    print ("FBSDKAccessToken: \(FBSDKAccessToken.current().tokenString!)")
                    FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                        getUserInfoFromFacebook(presentingViewController: self)
                        
                        if let user = FIRAuth.auth()?.currentUser {
                            setUserAdminStatusToDefaults()
                        } else {
                            // No user is signed in.
                        }
                    }
                }
            }
            else {
                facebookPermissionsRequiredAlert()
                try! FIRAuth.auth()!.signOut()
                FBSDKLoginManager().logOut()
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print ("logged out of facebook")
    }
    
    func verifyFacebookPermissionsGranted(result: FBSDKLoginManagerLoginResult) -> Bool {
        if result.declinedPermissions.contains("user_birthday") ||
            result.declinedPermissions.contains("user_friends") ||
            result.declinedPermissions.contains("user_education_history")
        {
            return false
        }
        return true
    }
    
    

}
