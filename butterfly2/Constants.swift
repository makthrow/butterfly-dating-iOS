//
//  Constants.swift
//  butterfly2
//
//  Created by Alan Jaw on 7/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import Firebase

struct Constants {
    

    static let BASE_URL = "https://butterfly2.firebaseio.com"

    static let IconReuseIdentifier = "IconCell"
    static let UserReuseIdentifier = "UserCell"
    
    
    static let LoginToHomeVC = "LoginToHomeViewController"
    static let HomeToUsersVC = "HomeToUsersVC"
    static let ToTabBarController = "LoginToTabBarController"
    static let ToSendMeetCamVC = "toSendMeetCamVC"
    static let ToLoginVC = "ToLoginViewController"
    static let ToFAQContactVC = "ToFAQContactViewController"
    static let privacyToHTMLVC = "privacyToHTMLVC"
    static let eulaToHTMLVC = "eulaToHTMLVC"
    static let InboxToReportVC = "InboxToReportVC"
    
    //USER
    static let userID = (FIRAuth.auth()?.currentUser?.uid)!
    
    // Firebase
    
    // The kFirebaseServerValueTimestamp is a property that is really used as a placeholder that firebase fills in when writing data.
//    static let kFirebaseServerValueTimestamp = [".sv":"timestamp"]
    static let firebaseServerValueTimestamp = FIRServerValue.timestamp()
    
    
    // Firebase Storage
    // Get a reference to the storage service, using the default Firebase App
    static let storage = FIRStorage.storage()
    // Create a storage reference from our storage service
    static let storageRef = storage.reference(forURL: "gs://butterfly2-ac0f9.appspot.com")
    static let storageMediaRef = storageRef.child("media")
    static let storageFBProfilePicRef = storageRef.child("fbProfilePic")
    
    // Firebase Database
    static let databaseRef = FIRDatabase.database().reference()
    
    // TABLE: for introduction blast videos (available to see by anyone in the area)
    static let MEDIA_INFO_REF = databaseRef.child("media_info")
    
    // TABLE: location reference table for entries in media_info
    static let MEDIA_LOCATION_REF = databaseRef.child("media_location")
    
    // TABLE: "MEET" MEDIA  : Private introduction media ("video", "text", "picture") sent to other users
    // first key is for the userID it is being sent to eg. meet_media_for_userID/CXFmdsafnasdhf
    // second key is a mediaID, comprised of fromUserID-timestamp (fromUserID is userID of the sender)
    static let MEET_MEDIA_REF = databaseRef.child("meet_media_for_userID")

    // TABLE: "USERS"
    static let USERS_REF = databaseRef.child("users")
    
    // TABLE: "USER_LOCATIONS"
    static let USER_LOCATIONS_REF = databaseRef.child("user_locations")
    
    // TABLE: "CHATS_MEMBERS"
    static let CHATS_MEMBERS_REF = databaseRef.child("chats_members")
    
    // TABLE: "CHATS_META"
    static let CHATS_META_REF = databaseRef.child("chats_meta")
    
    // TABLE: "CHATS_MESSAGES"
    static let CHATS_MESSAGES_REF = databaseRef.child("chats_messages")
    
    // TABLE: "CONTACT"
    static let CONTACT_REF = databaseRef.child("contact")
    
    // Geofire
    static let geoFireUsers = GeoFire(firebaseRef: USER_LOCATIONS_REF)
    static let geoFireMedia = GeoFire(firebaseRef: MEDIA_LOCATION_REF)
    
    // TIMES
    static let twentyFourHoursInMilliseconds:Double = 86400000

    // NOTIFIERS
    static let NewIntroduction = "New Introduction"
    static let NewMessage = "New Message"
 
    static let PrivacyTOS_String = ""
}
