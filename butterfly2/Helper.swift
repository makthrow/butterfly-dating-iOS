//
//  Helper.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/8/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import Firebase
//
//func getCurrentFirebaseServerTimeInMilliseconds(callback:(Int) -> ()) {
//    databaseRef.observeSingleEventOfType(FIRDataEventType.Value) { (snap) in
//        let timestamp = snap.value as? NSTimeInterval
//        callback(timestamp)
//    }
//}


func topMostController() -> UIViewController {
    var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
    while (topController.presentedViewController != nil) {
        topController = topController.presentedViewController!
    }
    return topController
}

func calculateAgeFromDate (birthday: Date) -> Int {
//    return Calendar.current.components(.Year, fromDate: birthday, toDate: NSDate(), options: []).year
    
//    Calendar.current.dateComponents(Set<Calendar.Component>, from: birthday, to: Date())
    let yearOfBirth: Int = Calendar.current.component(Calendar.Component.year, from: birthday)
    print ("yearOfBirth: \(yearOfBirth)")
    let unitFlags = Set<Calendar.Component>([.year])
    let age = Calendar.current.dateComponents(unitFlags, from: birthday, to: Date()).year
    print ("age: \(age!)")
    return age!
}

func calculateAgeFromDateString (birthdayString: String) -> Int {

    // "MM/dd/yyyy"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy"
    let birthdayDate = dateFormatter.date(from: birthdayString)
    
    let yearOfBirth: Int = Calendar.current.component(Calendar.Component.year, from: birthdayDate!)
    let unitFlags = Set<Calendar.Component>([.year])
    let age = Calendar.current.dateComponents(unitFlags, from: birthdayDate!, to: Date()).year
    print ("age: \(age!)")
    return age!
}

func getCurrentViewController(vc: UIViewController) -> UIViewController? {
    if let pvc = vc.presentedViewController {
        return getCurrentViewController(vc: pvc)
    }
    else if let svc = vc as? UISplitViewController , svc.viewControllers.count > 0 {
        return getCurrentViewController(vc: svc.viewControllers.last!)
    }
    else if let nc = vc as? UINavigationController , nc.viewControllers.count > 0 {
        return getCurrentViewController(vc: nc.topViewController!)
    }
    else if let tbc = vc as? UITabBarController {
        if let svc = tbc.selectedViewController {
            return getCurrentViewController(vc: svc)
        }
    }
    return vc
}

extension String {
    
    func containsWhiteSpace() -> Bool {
        
        // check if there's a range for a whitespace
        let range = self.rangeOfCharacter(from: CharacterSet.whitespaces)
        
        // returns false when there's no range for whitespace
        if let _ = range {
            return true
        } else {
            return false
        }
    }
    
    func isEmptyOrWhitespace() -> Bool {
        
        if(self.isEmpty) {
            return true
        }
        
        if (self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)).isEmpty {
            return true
        }
        else {
            return false
        }
    }
}
