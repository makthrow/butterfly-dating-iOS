//
//  FacebookSDKMethods.swift
//  butterfly2
//
//  Created by Alan Jaw on 7/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//


import Foundation
import FBSDKLoginKit
import FirebaseAuth

let facebookLoginManager = FBSDKLoginManager()


func getUserInfoFromFacebook() {
    let facebookRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name, gender, picture, birthday, first_name, last_name, email"])
    
    facebookRequest?.start(completionHandler: { (connection: FBSDKGraphRequestConnection?, result, error) in
        if error == nil {
            print ("result: \(result)")
            
            let r = result as! NSDictionary
            let first_name = r["first_name"] as? String
            let gender  = r["gender"] as? String
            let facebookID = r["id"] as? String
            let name = r["name"] as? String
            let lastName = r["last_name"] as? String
            let email = r["email"] as? String
            
            let birthdayString = r["birthday"] as? String
            
            // get the URL of a larger picture
            let urlString = "https://graph.facebook.com/\(facebookID!)/picture?type=large"
            //                print (urlString)
            let largerPicURL = URL(string: urlString)
            //                print (largerPicURL)
            do {
                let data = try Data(contentsOf: largerPicURL!)
                let profilePicStorageRef = Constants.storageFBProfilePicRef.child("\(Constants.userID).jpg")
                
                let task = profilePicStorageRef.put(data, metadata: nil, completion: { (metaData, error) in
                    if (error != nil ) {
                        print ("FBStorage upload profile pic error: \(error)")
                    }
                    else {
                        print ("Fb profile pic successfully uploaded")
                    }
                })
            }
            catch {
                print ("error:failed to get picture from fb result")
            }
            
            // save basic settings in standard user defaults: age, gender, first name
            let defaults = UserDefaults.standard
            if (first_name != nil) {
                defaults.set(first_name!, forKey: "firstName")
            }
            if gender != nil {
                defaults.set(gender!, forKey: "gender")
            }
            if birthdayString != nil {
                let currentUserAge = calculateAgeFromDateString(birthdayString: birthdayString!)
                defaults.set(currentUserAge, forKey: "age")
            }

//            let nameFromDefaults = defaults.object(forKey: "firstName") as? String
//            let ageFromDefaults = defaults.integer(forKey: "age")
//            let genderFromDefaults = defaults.object(forKey: "gender") as? String
//            print ("getuserfacebookinfo Defaults: \(nameFromDefaults), \(ageFromDefaults), \(genderFromDefaults)")
            // upload basic user info to Users table
            uploadFBUserInfo(name: name!, birthday: birthdayString!, gender: gender!, first_name: first_name!, last_name: lastName!, pictureURL: urlString, email: email!)
            
        }
        else { // facebookRequest.startWithCompletionHandler
            print ("get fb info error: \(error)")
        }
    })
}

