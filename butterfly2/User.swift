//
//  User.swift
//  butterfly2
//
//  Created by Alan Jaw on 7/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import Firebase

class User {
    // facebook user
    var email: String?
    var faceBookId: String?
    var profileImageURL: String?
    var displayName: String?
    
    init(id: String) {
        self.faceBookId = id
    }
    init() {
        
    }
    init(email: String?, faceBookId: String?, profileImageURL: String?, displayName: String? ) {
        self.email = email
        self.faceBookId = faceBookId
        self.profileImageURL = profileImageURL
        self.displayName = displayName
    }
    
    
    init ( dictionary: Dictionary<String, AnyObject>) {
        if let email = dictionary["email"] as? String {
            self.email = email
        }
        if let faceBookId = dictionary["faceBookId"] as? String {
            self.faceBookId = faceBookId
        }
        if let profileImageURL = dictionary["profileImageURL"] as? String {
            self.profileImageURL = profileImageURL
        }
        if let displayName = dictionary["displayName"] as? String {
            self.displayName = displayName
        }
    }
    
    func getPhoto(_ callback:(UIImage) -> ()) {
        
        if let imgURL = URL(string: self.profileImageURL!) {
            if let data = try? Data(contentsOf: imgURL) {
                callback(UIImage(data: data)!)
            }
        }
    }
}
