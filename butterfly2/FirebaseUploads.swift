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
            uploadVideoInfoToDatabase(title: title, mediaID: mediaID)
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
    let mediaRef = Constants.storageRef.child("media")
    let newMediaRef = mediaRef.child(mediaID)
    
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
            
            // create and upload video info data
            if let newVideoPost = setupMeetMediaToSave(mediaID: mediaID, userID: (Constants.userID), toUserID: toUserID, title: title, mediaType: currentMediaTypeToUpload) {
                
                let meetMediaUserRef = Constants.MEET_MEDIA_REF.child(toUserID)
                let newVideoPostChild = meetMediaUserRef.child(mediaID)
                
                newVideoPostChild.setValue(newVideoPost)
                
            }
            
        }
    }
}

func uploadVideoInfoToDatabase(title: String, mediaID: String) {
    
    getUserLocation()
    Constants.geoFireMedia?.setLocation(currentLocation, forKey: mediaID )
    
    // -----------FIREBASE DATABASE-----------
    //upload video info to Firebase real-time database (separate from the video file itself which goes to Firebase storage, with the title we generate above)
    
    // create and upload video info data
    if let newVideoPost = setupMediaInfoToSave(title, mediaID: mediaID, userID: (Constants.userID)) {
        
        let newVideoPostChild = Constants.MEDIA_INFO_REF.child(mediaID)
        
        newVideoPostChild.setValue(newVideoPost)
        
    }
}

func setupMediaInfoToSave(_ title: String, mediaID: String, userID: String)-> Dictionary<String, Any>? {
    
    var videoInfoDic: Dictionary<String, Any>?
    /*
     video_info_table: {
     { videoID : unique ID}  referencing video
     {userID }:  ID of the user who created
     {age: } age of user who created
     { timestamp} : date/time created
     {title} : user-entered title for video
     */
    
    let defaults = UserDefaults.standard
    var name = defaults.object(forKey: "firstName") as? String
    var age = defaults.integer(forKey: "age")
    var gender = defaults.object(forKey: "gender") as? String
    
    if (name != nil && gender != nil) { // age == 0  take out age for now until facebook approves birthday info
        
        videoInfoDic = [
            "mediaID": mediaID,
            "timestamp": Constants.firebaseServerValueTimestamp,
            "userID": userID,
            "title": title,
            "age": age,
            "name": name!,
            "gender": gender!
        ]
    }
//
//    else {
//        // THIS IS REALLY CONVOLUTED CODE THAT SHOULD BE UNNECESSARY. ONLY HERE BECAUSE THERE'S CURRENTLY AN ISSUE WITH FACEBOOK ACCESS TOKEN NOT WORKING AND SOMETIMES THE NSDEFAULTS DON'T GET SET. HOPEFULLY THIS CODE IS NEVER CALLED
//        print ("*ERROR* ns defaults name, age, gender nil")
//        getUserFacebookInfoFor(userID: (Constants.userID), callback:  {
//            dic in
//            if dic != nil {
//                let birthday = dic!["birthday"] as? String
//                let name = dic!["name"] as? String
//                let pictureURL = dic!["pictureURL"] as? String
//                let gender = dic!["gender"] as? String
//                
//                // save basic settings in standard user defaults: age, gender, first name
//                let defaults = UserDefaults.standard
//                if (name != nil && gender != nil && birthday != nil) {
//                    
//                    defaults.set(name!, forKey: "firstName")
//                    defaults.set(gender!, forKey: "gender")
//                    let currentUserAge = calculateAgeFromDateString(birthdayString: birthday!)
//                    defaults.set(currentUserAge, forKey: "age")
//                    
//                    videoInfoDic = [
//                        "mediaID": mediaID,
//                        "timestamp": Constants.firebaseServerValueTimestamp,
//                        "userID": userID,
//                        "title": title,
//                        "age": age,
//                        "name": name!,
//                        "gender": gender!
//                    ]
//                    
//                }
//            }
//        })
//
//    }
    
    return videoInfoDic
}


func setupMeetMediaToSave(mediaID: String, userID: String, toUserID: String, title: String, mediaType: String)-> Dictionary<String, Any>? {
    
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
     */
    
    mediaInfoDic = [
        "mediaID": mediaID,
        "mediaType": mediaType,
        "timestamp": Constants.firebaseServerValueTimestamp,
        "fromUserID": userID,
        "toUserID": toUserID,
        "title": title,
        "unread": true,
        "unsent_notification": true
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
func uploadFBUserInfo(name: String, birthday: String?, gender: String, first_name: String, last_name: String, pictureURL: String, email: String) {
    if let newFBUserInfoPost = setupFBUserInfoDic(name: name, birthday: birthday, gender: gender, first_name: first_name, last_name: last_name, pictureURL: pictureURL, email: email)
    {
        let userIDRef = Constants.databaseRef.child("users/\(Constants.userID)/")
        let userFacebookInfoRef = userIDRef.child("facebook_info")
        
        userFacebookInfoRef.setValue(newFBUserInfoPost)
    }

}

func setupFBUserInfoDic(name: String, birthday: String?, gender: String, first_name: String, last_name: String, pictureURL: String, email: String)-> Dictionary<String, Any>? {
    var FBUserInfoDic: Dictionary<String, Any>?
    
    FBUserInfoDic = [
        "name" : name,
        "gender": gender,
        "birthday": birthday,
        "first_name" : first_name,
        "last_name" : last_name,
        "pictureURL" : pictureURL,
        "email" : email
    ]
    return FBUserInfoDic
}
