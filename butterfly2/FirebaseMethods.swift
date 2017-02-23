//
//  FirebaseMethods.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/15/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

// helper class to store calls to Firebase Database
// refs can be found in Constants

// GLOBAL VARIABLES

var unreadChatCount: Int  = 0
var unreadMeetMediaCount: Int = 0

func setupNewChatWith(_ matchedUserID: String) {
    /* this will setup a new chat conversation between 2 users
     * NOTE - all these functions create for BOTH users
     * creates new entries under /users/userID/chats    and   /users/userID/chats_with_users
     * creates new entries in chats_members, and chats_messages
     * creates new entries in chats_meta
    */
    // CURRENT USER - create new entries
    let userIDRef = Constants.USERS_REF.child(Constants.userID)
    // new entry in /users/userID/chats -> chatID
    let userChatsRef = userIDRef.child("chats")
    let newChatIDRef = userChatsRef.childByAutoId()
    let newChatID = newChatIDRef.key
    newChatIDRef.setValue(true)
    // new entry in /users/userID/chats_with_users  -> userID
    let userChatsWithUsersRef = userIDRef.child("chats_with_users")
    userChatsWithUsersRef.setValue(["\(matchedUserID)": true])
    
    // WITH USER - create new entries
    let withUserIDRef = Constants.USERS_REF.child(matchedUserID)
    // new entry in /users/userID/chats -> chatID
    let withUserChatsRef = withUserIDRef.child("chats")
    let withUserNewChatIDRef = withUserChatsRef.child(newChatID) // be sure to use the same chatID from earlier
    withUserNewChatIDRef.setValue(true)
    // new entry in /users/userID/chats_with_users  -> userID
    let withUserChatsWithUsersRef = withUserIDRef.child("chats_with_users")
    withUserChatsWithUsersRef.setValue(["\(Constants.userID)": true])
    
    createChatsMembersFor(newChatID, user1: (Constants.userID), user2: matchedUserID)
    
    let currentDate = convertTimestampInMillisecondsToDate(timestamp: Date().timeIntervalSince1970 * 1000)
    let introductionMessage = "You've met someone new! Let's say hi"

    // need to call this twice. once to create a new chats_meta for each user.
    createChatsMetaFor(newChatID, lastMessage: introductionMessage, userID: Constants.userID, withUser: matchedUserID)
    createChatsMetaFor(newChatID, lastMessage: introductionMessage, userID: matchedUserID, withUser: Constants.userID)

}

func deleteChatFor(chatID: String, matchedUserID: String) {
    /* this will remove all traces of a match/chat between 2 users
     * if one user calls this method, the chats are removed for both users.
     * the current user of the app is not passed in as a parameter because we Constants.userID for himself
     * REMOVE new entries under /users/userID/chats    and   /users/userID/chats_with_users
     * REMOVE new entries in chats_members, and chats_messages
     * REMOVE new entries in chats_meta under "users/userId1/ID" and "users/userID2/ID"
     */
    
    // FOR CURRENT USER
    //   /users/userID/chats
    let userIDRef = Constants.USERS_REF.child(Constants.userID)
    // delete entry in /users/userID/chats -> chatID
    let userChatsRef = userIDRef.child("chats")
    userChatsRef.child(chatID).removeValue()
    
    // delete entry in /users/userID/chats_with_users  -> userID
    let userChatsWithUsersRef = userIDRef.child("chats_with_users")
    userChatsWithUsersRef.child(matchedUserID).removeValue()
    
    // for MATCHED USER
    //   /users/userID/chats
    let matchedUserIDRef = Constants.USERS_REF.child(matchedUserID)
    // delete entry in /users/userID/chats -> chatID
    let matchedUserChatsRef = matchedUserIDRef.child("chats")
    matchedUserChatsRef.child(chatID).removeValue()
    
    // delete entry in /users/userID/chats_with_users  -> userID
    let matchedUserChatsWithUsersRef = matchedUserIDRef.child("chats_with_users")
    matchedUserChatsWithUsersRef.child(Constants.userID).removeValue()
    
    
    
    // REMOVE new entries in chats_members
    let chatsMembersRef = Constants.CHATS_MEMBERS_REF
    let newChatsMembersRef = chatsMembersRef.child(chatID)
    newChatsMembersRef.removeValue()
    
    //REMOVE new entries in chats_messages
    let chatsMessagesRef = Constants.CHATS_MESSAGES_REF
    chatsMessagesRef.child(chatID).removeValue()
    
    // REMOVE new entries in chats_meta under "users/userId1/currentUserID" and "users/userID2/matchedUserID"

    // for current user
    let chatsMetaUserRef = Constants.CHATS_META_REF.child(Constants.userID)
    let newChatMetaRef = chatsMetaUserRef.child(chatID)
    newChatMetaRef.removeValue()
    
    // for matched user
    let chatsMetaMatchedUserRef = Constants.CHATS_META_REF.child(matchedUserID)
    let newChatMetaRefForMatchedUser = chatsMetaMatchedUserRef.child(chatID)
    newChatMetaRefForMatchedUser.removeValue()
    
}


func createChatsMembersFor(_ chatID: String, user1: String, user2: String) {
    // chats_members
    let chatsMembersRef = Constants.CHATS_MEMBERS_REF
    let newChatsMembersRef = chatsMembersRef.child(chatID)
    
    var chatsMembersDic: Dictionary<String, [String: Bool]>
    
    chatsMembersDic = [
        "users" : [
            user1: true,
            user2: true
        ]
    ]
    newChatsMembersRef.setValue(chatsMembersDic)
}
/* not using this currently because we need to find user name for each userID. just easier to do it one at a time
func createChatsMetaForBothUsers(_ chatID: String, lastMessage: String?, currentUserID: String, withUser matchedUserID: String) {
    // **Note** THIS CREATES TWO CHATS_META entries!! one for each user in the chat.
    // updates entry with same key as the one in /users/userID/chats
    // the user who chooses to match has the code that creates both users' chats_meta entries.
    // the chatID is the same one because we generate it once in setupNewChatWith() and use it twice.
    
    // create for current user
    let chatsMetaCurrentUserRef = Constants.CHATS_META_REF.child(currentUserID)
    let currentUserNewChatMetaRef = chatsMetaCurrentUserRef.child(chatID)
    
    var currentUserChatsMetaDic: Dictionary<String, Any>
    
    if lastMessage != nil {
        
        currentUserChatsMetaDic = [
            "key": chatID as AnyObject,
            "withUserID": matchedUserID as AnyObject,
            "lastMessage": lastMessage! as AnyObject,
            "timestamp": Constants.firebaseServerValueTimestamp as AnyObject,
            "unread" : true,
            "lastSender": "none"
        ]
        currentUserNewChatMetaRef.setValue(currentUserChatsMetaDic)
    }
    
    // create for the other user
    let chatsMetaWithUserRef = Constants.CHATS_META_REF.child(matchedUserID)
    let withUserNewChatMetaRef = chatsMetaWithUserRef.child(chatID)

    var withUserChatsMetaDic: Dictionary<String, Any>

    if lastMessage != nil {
        
        withUserChatsMetaDic = [
            "key": chatID as AnyObject,
            "withUserID": currentUserID as AnyObject,
            "lastMessage": lastMessage! as AnyObject,
            "timestamp": Constants.firebaseServerValueTimestamp as AnyObject,
            "unread" : true,
            "lastSender": "none"
        ]
        withUserNewChatMetaRef.setValue(withUserChatsMetaDic)
    }
}
 */

func createChatsMetaFor(_ chatID: String, lastMessage: String?, userID: String, withUser matchedUserID: String) {
    let chatsMetaUserRef = Constants.CHATS_META_REF.child(userID)
    let newChatMetaRef = chatsMetaUserRef.child(chatID)

    if lastMessage != nil {
        
        getUserFacebookInfoFor(userID: matchedUserID, callback:  {
            dic in
            if dic != nil {
                let withUserName = dic!["first_name"] as? String
  
                var chatsMetaDic: Dictionary<String, Any>
                
                chatsMetaDic = [
                    "key": chatID as AnyObject,
                    "withUserID": matchedUserID as AnyObject,
                    "lastMessage": lastMessage! as AnyObject,
                    "timestamp": Constants.firebaseServerValueTimestamp as AnyObject,
                    "unread" : true,
                    "withUserName": withUserName!,
                    "lastSender": "none",
                    "unsent_notification": true
                ]
                newChatMetaRef.setValue(chatsMetaDic)
            }
        })
    }
}

func fetchChatsMeta(_ callBack: @escaping ([ChatsMeta]) -> ()) {
    
    let currentUserChatsMetaRef = Constants.CHATS_META_REF.child("\(Constants.userID)")
    let latestChatsQuery = currentUserChatsMetaRef.queryOrdered(byChild: "timestamp")
    latestChatsQuery.observe(FIRDataEventType.value, with: { (snapshot) in
        
        var fetchedChatsMeta = [ChatsMeta]()
        
        let snapDic = snapshot.value as? NSDictionary
        if snapDic != nil {
            for child in snapDic! {
                let childDic = child.value as? NSDictionary

                let key = childDic?["key"] as? String
                let lastMessage = childDic?["lastMessage"] as? String
                let timestamp = childDic?["timestamp"] as? Double
                let withUserID = childDic?["withUserID"] as? String
                let lastSender = childDic?["lastSender"] as? String
                let unread = childDic?["unread"] as? Bool
                let withUserName = childDic?["withUserName"] as? String
                let unsent_notification = childDic?["unsent_notification"] as? Bool
                
                let newChatsMeta = ChatsMeta(key: key!, lastMessage: lastMessage!, timestamp: timestamp!, withUserID: withUserID!, lastSender: lastSender!, unread: unread!, withUserName: withUserName!, unsent_notification: unsent_notification!)
                
                
                // EXPLANATION: firebase has listeners, and these listeners fire in odd ways when you update data. sometimes it 
                // will return duplicate entries. until we fix our firebase database calls, we have this error checking code here 
                // that checks for duplicate chatID keys in our chatsMeta array.
                if (fetchedChatsMeta.filter{ $0.key == key }.count > 0) {
                    
                }
                else {
                    fetchedChatsMeta.append(newChatsMeta)
                }
            }
        }
        callBack(fetchedChatsMeta)
        
    })

}
private func snapshotToMessage(snapshot: FIRDataSnapshot) -> ChatsMessage {
    
    let dateFormat = "yyyyMMddHHmmss"
    
    func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }

//    let date = dateFormatter().date(from: snapshot.key)
    print ("snapshot: \(snapshot)")
    
    let snapDic = snapshot.value as? NSDictionary
    
    let sender = snapDic?["senderId"] as? String
    let text = snapDic?["text"] as? String
    let timestamp = snapDic?["timestamp"] as? Double
    return ChatsMessage(message: text!, senderId: sender!, timestamp: timestamp!)
}

// senderId is currentUser's ID.
func createChatsMessagesFor(_ chatID: String, senderId: String, withUserID: String, text: String) {
    let chatsMessagesRef = Constants.CHATS_MESSAGES_REF
    let newChatsMessagesRef = chatsMessagesRef.child(chatID).childByAutoId()
    
    let chatMessageDic: [String : Any] = [
        "timestamp": Constants.firebaseServerValueTimestamp,
        "senderId": senderId,
        "text": text
    ]
    newChatsMessagesRef.setValue(chatMessageDic)
    updateChatsMetaFor(chatID, text: text, senderId: senderId, withUserID: withUserID)
}

// senderId is currentUser's ID.
func updateChatsMetaFor(_ chatID: String, text: String, senderId: String, withUserID: String) {
    // NOTE: This method updates chats_meta for BOTH USERS in the chat

    // currentUserId: update chats_meta with last message and last sender
    let chatsMetaUserRef = Constants.CHATS_META_REF.child(senderId)
    let newChatsMetaIDRef = chatsMetaUserRef.child(chatID)
    
    var chatsMetaDic: Dictionary<String, Any>

    chatsMetaDic = [
        "key": chatID as AnyObject,
        "lastMessage": text as AnyObject,
        "timestamp": Constants.firebaseServerValueTimestamp as AnyObject,
        "lastSender": senderId as AnyObject,
        "unread" : false, // set to false because this is the currentUser own message
        "unsent_notification": false // set to false because this is the currentUser own message
    ]
    newChatsMetaIDRef.updateChildValues(chatsMetaDic)
    
    // withUserId: update chats_meta with last message and last sender

    
    let withUserChatsMetaRef = Constants.CHATS_META_REF.child(withUserID)
    let newWithUserChatsMetaIDRef = withUserChatsMetaRef.child(chatID)
    
    var withUserChatsMetaDic: Dictionary<String, Any>
    
    withUserChatsMetaDic = [
        "key": chatID as AnyObject,
        "lastMessage": text as AnyObject,
        "timestamp": Constants.firebaseServerValueTimestamp as AnyObject,
        "lastSender": senderId as AnyObject,
        "unread" : true,
        "unsent_notification": true
    ]
    newWithUserChatsMetaIDRef.updateChildValues(withUserChatsMetaDic)

}

func updateChatsMetaLastMessageReadFor(_ chatID: String) {
    let chatsMetaUserRef = Constants.CHATS_META_REF.child(Constants.userID)
    let chatsMetaIDRef = chatsMetaUserRef.child(chatID)
    
    var chatsMetaDic: Dictionary<String, Any>

    chatsMetaDic = [
        "unread" : false
    ]
    chatsMetaIDRef.updateChildValues(chatsMetaDic)
}

//func fetchChatsMessagesFor(chatID: String, callback: @escaping ([ChatsMessage]) -> ()) {
//    let latestChatsMessageQuery = Constants.CHATS_MESSAGES_REF.child(chatID).queryOrdered(byChild: "timestamp")
//    
//    latestChatsMessageQuery.observe(FIRDataEventType.value, with: { (snapshot: FIRDataSnapshot) in
//        
//        print ("latestChatsMessageQuery Snapshot: \(snapshot)")
//        var messages = [ChatsMessage]()
//        let enumerator = snapshot.children
//        while let data = enumerator.nextObject() as? FIRDataSnapshot {
//            messages.append(snapshotToMessage(snapshot: data))
//        }
//        callback(messages)
//    })
//}

// MARK: meetMedia

func getMeetMedia(_ callBack: @escaping ([MeetMedia]) -> ()) {
    
    /*
     An important note on Firebase queries:
     Firebase does not allow multiple query chaining -ie. multiple where clauses.
     eg. our use case:
     toUserID = userID AND timestamp <= 24 hours
     
     (and does not look like they will ever support this in the future)
     
     One way to handle this is to filter the data in our client. Hopefully the item set does not contain too many entries, or else this filter could become really slow as we download.
     
     So we have two options to filter the data.
     
     A. Download the list of personal meet intros sent in the last 24 hours, then filter in our iOS code by the ones only sent to our current user (ie.  toUserID = userID)
     
     B. Download the list of personal meet intros sent to our user regardless of timestamp, then filter in our iOS code by the ones with a timestamp within the last 24 hours.
     
     If our user base ever gets large, the list of A is bound to be vastly large than the list of B, not to mention the potential privacy issues of downloading personal intros not meant to be seen by the current user to every user's phone.
     Another PRO to using method B is that we will probably eventually prune the database list by deleting older entries than 24 hours. So our filter here will still work, and we won't have to filter by the latest 24 hours in the iOS code.
     
     Therefore we have chosen option B
     
     */
    // NEW UPDATE OCT 14
    // MEET_MEDIA has been renamed to meet_media_for_userID, and the structure has been changed to be based on /userID/meet_media_ID
    // this allows for faster database calls because we can index on the userID
    
    
    
    // Nov 29 added filter for blocked IDs
    var blockList = [String]()
    getBlockList({
        list in
        blockList = list
    })
    
    
    // timeIntervalSince1970 takes seconds, while the timestamp from firebase is in milliseconds
    let currentTimeInMilliseconds = Date().timeIntervalSince1970 * 1000
    // filter list by the dates that are within 24 hours (86400000 milliseconds = 24 hours)
    let startTime = currentTimeInMilliseconds - (Constants.twentyFourHoursInMilliseconds * 2) // CURRENT FILTER: 48 hours
    let endTime = currentTimeInMilliseconds
    
    let meetMediaUserRef = Constants.MEET_MEDIA_REF.child("\(Constants.userID)")
    
    let media48HourQuery = meetMediaUserRef
        .queryOrdered(byChild: "timestamp")
        .queryStarting(atValue: currentTimeInMilliseconds - (Constants.twentyFourHoursInMilliseconds * 2))
        .queryEnding(atValue: currentTimeInMilliseconds)
    media48HourQuery.observe(FIRDataEventType.value, with: { snapshot in
        
        var fetchedMeetMedia = [MeetMedia]()
        
        let snapDic = snapshot.value as? NSDictionary
        
        if snapDic != nil {

            for child in snapDic! {
                
                let childDic = child.value as? NSDictionary
                
                let title  = childDic?["title"] as? String
                let mediaID = childDic?["mediaID"] as? String
                let timestamp = childDic?["timestamp"] as? Double
                let fromUserID = childDic?["fromUserID"] as? String
                let toUserID = childDic?["toUserID"] as? String
                let mediaType = childDic?["mediaType"] as? String
                let unread = childDic?["unread"] as? Bool
                let unsent_notification = childDic?["unsent_notification"] as? Bool
                
                let newMeetMedia = MeetMedia(fromUserID: fromUserID!, mediaID: mediaID!, mediaType: mediaType!, timestamp: timestamp!, title: title!, toUserID: toUserID!, unread: unread!, unsent_notification: unsent_notification!)
                
                //blockedUser filter
                if !blockList.contains(fromUserID!) {
                    fetchedMeetMedia.append(newMeetMedia)
                }
                
            }

        }
        callBack(fetchedMeetMedia)
    })
}


func updateMeetMediaReadFor(_ meetMediaID: String) {
    let meetMediaUserRef = Constants.MEET_MEDIA_REF.child("\(Constants.userID)")
    let meetMediaIDRef = meetMediaUserRef.child("\(meetMediaID)")
    
    var dic: Dictionary<String, Any>
    
    dic = [
        "unread" : false
    ]
    meetMediaIDRef.updateChildValues(dic)
}

func updateMeetMediaNotifiedFor(_ meetMediaID: String) {
    let meetMediaUserRef = Constants.MEET_MEDIA_REF.child("\(Constants.userID)")
    let meetMediaIDRef = meetMediaUserRef.child("\(meetMediaID)")
    
    var dic: Dictionary<String, Any>
    
    dic = [
        "unsent_notification" : false
    ]
    meetMediaIDRef.updateChildValues(dic)
}

// CHAT_META
func updateChatMetaNotifiedFor(_ chatMetaID: String) {
    let chatMetaUserRef = Constants.CHATS_META_REF.child("\(Constants.userID)")
    let chatMetaIDRef = chatMetaUserRef.child(chatMetaID)
    
    var dic: Dictionary<String, Any>
    
    dic = [
        "unsent_notification" : false
    ]
    chatMetaIDRef.updateChildValues(dic)
}


func observeChatActiveStatusFor(chatID: String, callback: @escaping (Bool) -> ()) {
    let userIDRef = Constants.USERS_REF.child(Constants.userID)
    // delete entry in /users/userID/chats -> chatID
    let userChatsRef = userIDRef.child("chats")
    userChatsRef.child(chatID).observe(.value, with: { (snapshot) in

        if snapshot.exists() {
            callback(true)
            print ("chat is active")
        }
        else {
            callback(false)
            print ("Chat is not active")
        }
    })
}


func observeMessagesFor(chatID: String, callback: @escaping (ChatsMessage) -> ()){
    let latestChatsMessageQuery = Constants.CHATS_MESSAGES_REF.child(chatID).queryLimited(toLast: 25)
    // observes each child message added one at a time
    latestChatsMessageQuery.observe(.childAdded, with: { (snapshot) in
        let snapDic = snapshot.value as? NSDictionary
        
        let sender = snapDic?["senderId"] as? String
        let text = snapDic?["text"] as? String
        let timestamp = snapDic?["timestamp"] as? Double
        let newMessage = ChatsMessage(message: text!, senderId: sender!, timestamp: timestamp!)
        callback(newMessage)
    })
}

func checkIfMatched(currentUserID: String, withUserID: String, callback: @escaping (Bool) -> ()){

    // run a check to see if there is an existing match already in users/currentUseridxxx/chats_with_users/withUserIDxxx
    let currentUser_UsersRef = Constants.USERS_REF.child(currentUserID)
    let chats_with_users_ref = currentUser_UsersRef.child("chats_with_users")
    let chats_with_particular_user_ref = chats_with_users_ref.child(withUserID)
    
    chats_with_particular_user_ref.observeSingleEvent(of: .value, with: { (snapshot) in
        let exists: Bool = snapshot.exists()
        callback(exists)
    })
}

// MARK: Reports

func reportUserInDatabase(type: Int, userIDToReport: String, text: String) {
    // types: "inappropriateContent" (1), "spamOrFakeUser" (2), "harassment" (3), "other" (4)
    
    // reportedUsers
    //   userID:
    //      types: 1
    //      fromUser:
    //      toUser (not necessary? it's the key)
    //      text: ""
    let reportRef = Constants.REPORTED_USERS_REF.child(userIDToReport).childByAutoId()

    let dic: [String : Any] = [
        "type": type,
        "timestamp": Constants.firebaseServerValueTimestamp,
        "fromUserID": Constants.userID,
        "text": text
    ]
    
    reportRef.setValue(dic)

}

func blockUser(userIDToBlock: String) {
    //   users/userID/blockedUserIDs:
    //          userID1: true, userID2:true
    let blockedUserIDsRef = Constants.USERS_REF.child(Constants.userID).child("/blockedUserIDs")
    
    let dic: [String : Any] = [
        userIDToBlock: true
    ]
    
    blockedUserIDsRef.setValue(dic)
    
    // add block for the reporting user too
    let reportingUserIDRef = Constants.USERS_REF.child(userIDToBlock).child("/blockedUserIDs")

    let dic2: [String : Any] = [
        Constants.userID: true
    ]
    
    reportingUserIDRef.setValue(dic2)
    
}


func getBlockList(_ callBack: @escaping ([String]) -> ()) {
    let blockedUsersRef = Constants.USERS_REF.child(Constants.userID).child("blockedUserIDs")
    
    blockedUsersRef.observe(FIRDataEventType.value, with: { snapshot in
        
        var blockedUsers = [String]()
        
        let snapDic = snapshot.value as? NSDictionary
        
        if snapDic != nil {
            blockedUsers = snapDic!.allKeys as! [String]
            print (snapDic!.allKeys)
            for child in (snapDic!.allKeys) {
                print("child: \(child)")
            }
        }
        callBack(blockedUsers)
    })
}



func convertTimestampInMillisecondsToDate(timestamp: Double) -> String {
    let dateTimeStamp = Date(timeIntervalSince1970:Double(timestamp)/1000)  //UTC time
    
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = NSTimeZone.local //Edit
    dateFormatter.dateFormat = "MM-dd"
    dateFormatter.dateStyle = DateFormatter.Style.medium
    dateFormatter.timeStyle = DateFormatter.Style.none
    
    
    let strDate = dateFormatter.string(from: dateTimeStamp)

    return strDate
    
}

// MARK: Facebook-Related

func getFBProfilePicFor(userID: String, callback:@escaping (UIImage) -> ()) {

    let fbPhotoRef = Constants.storageFBProfilePicRef.child(userID)
    fbPhotoRef.data(withMaxSize: 1 * 1024 * 1024) { (data, error) in
        print ("called getFBProfilePicFor: \(userID)")
        if (error != nil ) {
            print ("get fb photo error in SettingsVC: \(error)")
        }
        else {
            let image: UIImage! = UIImage(data: data!)
            callback(image)
        }
    }
}

func getUserFacebookInfoFor (userID: String, callback:@escaping (Dictionary<String, Any>?) -> ()) {
    let userIDRef = Constants.USERS_REF.child(userID)
    let userFacebookInfoRef = userIDRef.child("facebook_info")
    
    var FBUserInfoDic: Dictionary<String, Any>?
    
    userFacebookInfoRef.observeSingleEvent(of: .value, with: { (snapshot) in
        
        let snapDic = snapshot.value as? NSDictionary
        
        let name = snapDic?["name"] as? String
        let gender = snapDic?["gender"] as? String
        let birthday = snapDic?["birthday"] as? String
        let first_name = snapDic?["first_name"] as? String
        let last_name = snapDic?["last_name"] as? String
        let pictureURL = snapDic?["pictureURL"] as? String
        let email = snapDic?["email"] as? String
        
        FBUserInfoDic = [
            "name" : name,
            "gender": gender,
            "birthday": birthday,
            "first_name" : first_name,
            "last_name" : last_name,
            "pictureURL" : pictureURL,
            "email" : email
        ]
        
        callback(FBUserInfoDic)
    })
}

//MARK: Listeners


func setupMeetMediaUnreadListener() {
    
    // meet_media_for_userID
    // timeIntervalSince1970 takes seconds, while the timestamp from firebase is in milliseconds
    let currentTimeInMilliseconds = Date().timeIntervalSince1970 * 1000
    let startTime = currentTimeInMilliseconds - (Constants.twentyFourHoursInMilliseconds * 2) // CURRENT FILTER: 48 hours
    
    let meetMediaUserRef = Constants.MEET_MEDIA_REF.child("\(Constants.userID)")
    
    // careful with these time-based queries. we need to run these continually on a timer because the times need to be updated to the current time.
    
    let media48HourQuery = meetMediaUserRef
        .queryOrdered(byChild: "timestamp")
        .queryStarting(atValue: startTime)
        .queryEnding(atValue: currentTimeInMilliseconds)
    media48HourQuery.observeSingleEvent(of: FIRDataEventType.value, with: { snapshot in
        
        var fetchedMeetMedia = [MeetMedia]()
        
        let snapDic = snapshot.value as? NSDictionary
        
        var counter = 0
        if snapDic != nil {
            for child in snapDic! {
                
                let childDic = child.value as? NSDictionary
                
                let title  = childDic?["title"] as? String
                let mediaID = childDic?["mediaID"] as? String
                let timestamp = childDic?["timestamp"] as? Double
                let fromUserID = childDic?["fromUserID"] as? String
                let toUserID = childDic?["toUserID"] as? String
                let mediaType = childDic?["mediaType"] as? String
                let unread = childDic?["unread"] as? Bool
                let unsent_notification = childDic?["unsent_notification"] as? Bool
                
                let newMeetMedia = MeetMedia(fromUserID: fromUserID!, mediaID: mediaID!, mediaType: mediaType!, timestamp: timestamp!, title: title!, toUserID: toUserID!, unread: unread!, unsent_notification: unsent_notification!)
                
                fetchedMeetMedia.append(newMeetMedia)
                if unread == true {
                    counter += 1
                }
                
                if unsent_notification == true {
                    NotificationMethods().newMeetMediaNotificationFor(meetMediaID: mediaID!)
                    // TODO: mark notification as sent
                    updateMeetMediaNotifiedFor(mediaID!)
                }
            }
        }
        unreadMeetMediaCount = counter
    })
}

func setupChatsMetaUnreadListener() {
    
    let currentUserChatsMetaRef = Constants.CHATS_META_REF.child(Constants.userID)
    let latestChatsQuery = currentUserChatsMetaRef.queryOrdered(byChild: "timestamp")
    latestChatsQuery.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
        
        var fetchedChatsMeta = [ChatsMeta]()
        
        let snapDic = snapshot.value as? NSDictionary
        var counter = 0
        if snapDic != nil {
            
            for child in snapDic! {
                let childDic = child.value as? NSDictionary
                
                let key = childDic?["key"] as? String
                let lastMessage = childDic?["lastMessage"] as? String
                let timestamp = childDic?["timestamp"] as? Double
                let withUserID = childDic?["withUserID"] as? String
                let lastSender = childDic?["lastSender"] as? String
                let unread = childDic?["unread"] as? Bool
                let withUserName = childDic?["withUserName"] as? String
                let unsent_notification = childDic?["unsent_notification"] as? Bool
                
                let newChatsMeta = ChatsMeta(key: key!, lastMessage: lastMessage!, timestamp: timestamp!, withUserID: withUserID!, lastSender: lastSender!, unread: unread!, withUserName: withUserName!, unsent_notification: unsent_notification!)
                
                
                // EXPLANATION: firebase has listeners, and these listeners fire in odd ways when you update data. sometimes it
                // will return duplicate entries. until we fix our firebase database calls, we have this error checking code here
                // that checks for duplicate chatID keys in our chatsMeta array.
                if (fetchedChatsMeta.filter{ $0.key == key }.count > 0) {
                    
                }
                else {
                    fetchedChatsMeta.append(newChatsMeta)
                    if unread == true && lastSender != Constants.userID {
                        counter += 1
                        
                        if unsent_notification == true {
                            NotificationMethods().newChatNotificationFor(chatID: key!, fromUserID: lastSender!, message: lastMessage!, fromUserName: withUserName!)

                            updateChatMetaNotifiedFor(key!)
                        }
                    }
                }

            }
        }
        unreadChatCount = counter
    })
}

func contactSent() {
    
}

func setUserAdminStatusToDefaults() {
    let userIDRef = Constants.USERS_REF.child(Constants.userID)
    
    userIDRef.observeSingleEvent(of: .value, with: { (snapshot) in
        
        let snapDic = snapshot.value as? NSDictionary
        
        let adminBool = snapDic?["admin"] as? Bool
        
        let defaults = UserDefaults.standard
        
        if adminBool == nil || adminBool == false {
            defaults.set(false, forKey: "admin")
        }
        else {
            defaults.set(adminBool, forKey: "admin")
        }

    })
}

func getUserAdminStatusFromDefaults() -> Bool {
    let defaults = UserDefaults.standard
    return defaults.bool(forKey: "admin")
}
