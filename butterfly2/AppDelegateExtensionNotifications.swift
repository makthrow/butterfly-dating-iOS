//
//  AppDelegateExtensionNotifications.swift
//  butterfly2
//
//  Created by Alan Jaw on 10/19/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import UserNotifications


extension AppDelegate: UNUserNotificationCenterDelegate {

    // willPresent is called when app is in foreground
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        // Process notification content
        print ("willPresent notification")
        completionHandler([.alert]) // Display notification as regular alert and play sound

//        completionHandler([.alert, .badge, .sound]) // Display notification as regular alert and play sound
    }
    
    // didReceive is called when app is in background and user presses the notification
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        print ("didReceive notification")
        switch actionIdentifier {
        case UNNotificationDismissActionIdentifier: // Notification was dismissed by user
            // Do something
            let request = response.notification.request
            print("UNNotificationDismissActionIdentifier")
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])

            completionHandler()
        case UNNotificationDefaultActionIdentifier: // App was opened from notification
            // Do something
            let request = response.notification.request
            print("UNNotificationDefaultActionIdentifier")
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
            
            if request.content.title == Constants.NewIntroduction  {
                
                guard let rvc = self.window?.rootViewController else {
                    return
                }
                if let vc = getCurrentViewController(vc: rvc) {
                    // do your stuff here
                    vc.tabBarController?.selectedIndex = 2
                }

            }
            else if request.content.title == Constants.NewMessage {
                
                guard let rvc = self.window?.rootViewController else {
                    return
                }
                if let vc = getCurrentViewController(vc: rvc) {
                    // do your stuff here
                    vc.tabBarController?.selectedIndex = 3
                }
            }
            
            completionHandler()
        default:
            print ("default  action identifier")
            completionHandler()
        }
    }
    
}
