//
//  FirebaseUploads.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/26/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import FirebaseAuth

func uploadVideoToMediaInfo(_ videoURL: URL, title: String) {
    
    // generate a timestamp
    //        let videoTimeStamp: NSTimeInterval = NSDate().timeIntervalSince1970
    let videoTimeStamp = String(Int(round(Date().timeIntervalSince1970)))
    
    // combine the two to form a unique video ID of userID + timestamp
    let mediaID = ("\(Constants.userID)-\(videoTimeStamp)")
    print (mediaID)
    
    // -----------FIREBASE STORAGE-----------
    // upload video file to Firebase storage

    let newMediaRef = Constants.storageMediaRef.child(mediaID)
        
    // NSURL for video
    let uploadTask = newMediaRef.putFile(videoURL, metadata: nil) { metadata, error in
        if (error != nil) {
            print ("upload to firebase error: \(error)")
        } else {
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata!.downloadURL
            print ("upload success")
                
            // if SUCCESS in upload to FIREBASE STORAGE, upload video info to FIREBASE DATABASE
            uploadMediaInfoToDatabase(title: title, mediaID: mediaID)
        }
    }
}

func uploadVideoToMeetMedia(_ videoURL: URL, title: String, toUserID: String, currentMediaTypeToUpload:String) {
    
    let currentMediaTypeToUpload = "video"
    
    // generate a timestamp
    //        let videoTimeStamp: NSTimeInterval = NSDate().timeIntervalSince1970
    let videoTimeStamp = String(Int(round(Date().timeIntervalSince1970)))
    
    // combine the two to form a unique video ID of userID + timestamp. this will be the unique filename in Firebase Storage
    let mediaID = ("\(Constants.userID)-\(videoTimeStamp)")
    // use userID of sender.
    
    // -----------FIREBASE STORAGE-----------
    // upload video file to Firebase storage
    let newMediaRef = Constants.storageMediaRef.child(mediaID)
    
    // NSURL for video
    let uploadTask = newMediaRef.putFile(videoURL, metadata: nil) { metadata, error in
        if (error != nil) {
            print ("upload to firebase error: \(error)")
        } else {
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata!.downloadURL
            
            // SUCCESS uploaded. add meet_media_for_userID entry
            
            // -----------FIREBASE DATABASE-----------
            //upload video info to Firebase real-time database (separate from the video file itself which goes to Firebase storage, with the title we generate above)
            uploadMeetMediaInfoToDatabase(mediaID: mediaID, userID: Constants.userID, toUserID: toUserID, title: title, mediaType: currentMediaTypeToUpload)
            
        }
    }
}

func uploadMediaInfoToDatabase(title: String, mediaID: String) {
    
    getUserLocation()
    Constants.geoFireMedia?.setLocation(currentLocation, forKey: mediaID )
    
    // -----------FIREBASE DATABASE-----------
    //upload video info to Firebase real-time database (separate from the video file itself which goes to Firebase storage, with the title we generate above)
    
    // create and upload video info data
    if let newMediaInfoPost = setupMediaInfoToSave(title, mediaID: mediaID, userID: (Constants.userID)) {
        
        let newMediaInfoChildRef = Constants.MEDIA_INFO_REF.child(mediaID)
        
        newMediaInfoChildRef.setValue(newMediaInfoPost)
        
    }
}

func setupMediaInfoToSave(_ title: String, mediaID: String, userID: String)-> Dictionary<String, Any>? {
    
    var mediaInfoDic: Dictionary<String, Any>?
    
    let defaults = UserDefaults.standard
    var name = defaults.object(forKey: "firstName") as? String
    var age = defaults.integer(forKey: "age")
    var gender = defaults.object(forKey: "gender") as? String
    
    if (name != nil && gender != nil) { // TODO: age == 0  take out age for now until facebook approves birthday info
        
        mediaInfoDic = [
            "mediaID": mediaID,
            "timestamp": Constants.firebaseServerValueTimestamp,
            "userID": userID,
            "title": title,
            "age": age,
            "name": name!,
            "gender": gender!
        ]
    }
    
    return mediaInfoDic
}

func uploadMeetMediaInfoToDatabase(mediaID: String, userID: String, toUserID: String, title: String, mediaType: String) {
    
    let defaults = UserDefaults.standard
    let userGender = defaults.string(forKey: "gender")
    
    // create and upload video info data
    if let newMeetMedia = setupMeetMediaToSave(mediaID: mediaID, userID: (Constants.userID), toUserID: toUserID, title: title, mediaType: mediaType, userGender: userGender!) {
        
        let meetMediaUserRef = Constants.MEET_MEDIA_REF.child(toUserID)
        let newMeetMediaChildRef = meetMediaUserRef.child(mediaID)
        
        newMeetMediaChildRef.setValue(newMeetMedia)
    }
}


func setupMeetMediaToSave(mediaID: String, userID: String, toUserID: String, title: String, mediaType: String, userGender: String)-> Dictionary<String, Any>? {
    
    var mediaInfoDic: Dictionary<String, Any>?
    /*
     meet_media: {
     mediaID // name of file in firebase storage
     fromUserId
     toUserID
     mediaType: ("picture", "video", "text")
     title
     timestamp
     unread: true
     gender
     */
    
    mediaInfoDic = [
        "mediaID": mediaID,
        "mediaType": mediaType,
        "timestamp": Constants.firebaseServerValueTimestamp,
        "fromUserID": userID,
        "toUserID": toUserID,
        "title": title,
        "unread": true,
        "unsent_notification": true,
        "gender": userGender
    ]
    
    return mediaInfoDic
}

func uploadImage(fileToUploadDATA: Data, mediaID: String) {
    // NSData for image
    let newMediaRef = Constants.storageMediaRef.child(mediaID)
    let uploadTask = newMediaRef.put(fileToUploadDATA, metadata: nil) { metadata, error in
        if (error != nil) {
            // Uh-oh, an error occurred!
        } else {
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata!.downloadURL
        }
    }

}

// name, gender, picture, birthday, first_name, last_name"
func uploadFBUserInfo(name: String, birthday: String, gender: String, first_name: String, last_name: String, pictureURL: String) {
    if let newFBUserInfoPost = setupFBUserInfoDic(name: name, birthday: birthday, gender: gender, first_name: first_name, last_name: last_name, pictureURL: pictureURL)
    {
        let userIDRef = Constants.USERS_REF.child(Constants.userID)
        let userFacebookInfoRef = userIDRef.child("facebook_info")
        
        userFacebookInfoRef.setValue(newFBUserInfoPost)
    }
}

func setupFBUserInfoDic(name: String, birthday: String, gender: String, first_name: String, last_name: String, pictureURL: String)-> Dictionary<String, Any>? {
    var FBUserInfoDic: Dictionary<String, Any>?
    
    FBUserInfoDic = [
        "name" : name,
        "gender": gender,
        "birthday": birthday,
        "first_name" : first_name,
        "last_name" : last_name,
        "pictureURL" : pictureURL
    ]
    return FBUserInfoDic
}
