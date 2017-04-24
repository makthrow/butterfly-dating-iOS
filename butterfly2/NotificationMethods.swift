//
//  NotificationMethods.swift
//  butterfly2
//
//  Created by Alan Jaw on 10/19/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import UserNotifications

// NOTE: READ THIS: ***** notifications not working currently. seems to be a bug in the new UserNotifications

class NotificationMethods:NSObject, UNUserNotificationCenterDelegate {
    
    override init() {
        super.init()
        if #available(iOS 10.0, *) {
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    func newMeetMediaNotificationFor(meetMediaID: String) {
        // send when you receive a meet_media
        if #available(iOS 10.0, *) {
            let timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = Constants.NewIntroduction
            content.subtitle = "Let's see who it is"
            content.body = "Someone wants to meet you..."
            content.badge = 1
//            content.sound = UNNotificationSound.default()
            
            let currentTimeInMilliseconds = Date().timeIntervalSince1970 * 1000
            
            let request = UNNotificationRequest(identifier: "meet_media-\(meetMediaID)", content: content, trigger: timeTrigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    // Do something with error
                    print ("newMeetMediaNotificationFor() error: \(error)")
                } else {
                    print (request)
                }
            }
        } else {
            // Fallback on earlier versions
        }

    }
    
    func newChatNotificationFor(chatID: String, fromUserID: String, message: String, fromUserName: String) {
        // send when you receive a new chat message
        if #available(iOS 10.0, *) {
            let timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = Constants.NewMessage
            content.subtitle = fromUserName
            content.body = message
            content.badge = 1
            //            content.sound = UNNotificationSound.default()
            
            let currentTimeInMilliseconds = Date().timeIntervalSince1970 * 1000
            
            let request = UNNotificationRequest(identifier: chatID, content: content, trigger: timeTrigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    // Do something with error
                    print ("newChatNotificationFor() error: \(error)")
                } else {
                    print (request)
                }
            }
        } else {
            // Fallback on earlier versions
        }

    }
    
    func newMatchAcceptedNotification() {
        // send when a user you sent a meet request to, chooses to match with you
        
    }
    
    func removeAppIconContentBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
