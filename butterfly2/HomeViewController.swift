//
//  HomeViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 7/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.


import UIKit
import MobileCoreServices
import Photos
import FirebaseAuth
import CoreLocation
import FBSDKLoginKit


class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {

    var fileToUploadURL: URL!
    var fileToUploadDATA: Data!
    var currentMediaTypeToUpload: String?
    
    var locationManager: CLLocationManager!
    var locationStatus : NSString = "Not Started"
    var locationFixAchieved : Bool = false
    
    var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginManager = FBSDKLoginManager()
        // Do any additional setup after loading the view.
        
        if let user = FIRAuth.auth()?.currentUser {
            getUserInfoFromFacebook()
            for profile in user.providerData {
                let providerID = profile.providerID
                let uid = profile.uid;  // Provider-specific UID
                let name = profile.displayName
                let email = profile.email
                let photoURL = profile.photoURL
                
//                print (providerID)
//                print (uid)
//                print (name)
//                print (email)
//                print (photoURL)
//                
                // save Facebook info
                // displayname, email, photoURL
                
            }
        } else {
            // No user is signed in.
        }
        
//        NotificationMethods().sendNotifications()
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
    
        initLocationManager()
        getUserLocation()        
        
        let timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.runListeners), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cameraButton(_ sender: UIButton) {
        
        
    }
    
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 80467.2 // meters. or 50 miles
        locationManager.startUpdatingLocation()
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestLocation()
    }
    
    // MARK: CLLocationManager Delegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status {
        case CLAuthorizationStatus.restricted:
            locationStatus = "Restricted Access to location"
        case CLAuthorizationStatus.denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.notDetermined:
            locationStatus = "Status not determined"
        default:
            locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LabelHasbeenUpdated"), object: nil)
        if (shouldIAllow == true) {
            NSLog("Location to Allowed")
            // Start location services
            locationManager.startUpdatingLocation()
        } else {
            NSLog("Denied access: \(locationStatus)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            if let location = locations.last {
                print ("last location: \(location)")
                
                // firebase database update location
                let lat = location.coordinate.latitude
                let long = location.coordinate.longitude
                currentLocation = CLLocation(latitude: lat, longitude: long)
                Constants.geoFireUsers?.setLocation(currentLocation, forKey: Constants.userID)

            }
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    
    @IBAction func settingsButton(_ sender: UIButton) {
        
    }
    func runListeners() {
        // new chat messages: unread true in chats_meta
        setupChatsMetaUnreadListener()
        // new intros: meet_media_for_userID
        setupMeetMediaUnreadListener()

        updateTabBars()
        
    }

    
    func updateTabBars() {
    
        // notifications not working currently. seems to be a bug in the new UserNotifications
        if (unreadChatCount > 0 ) {
            self.tabBarController?.tabBar.items![3].badgeValue = "\(unreadChatCount)"
//            NotificationMethods().sendNotifications()
        }
        else {
            self.tabBarController?.tabBar.items![3].badgeValue = nil
        }
        
        if (unreadMeetMediaCount > 0) {
            self.tabBarController?.tabBar.items![2].badgeValue = "\(unreadMeetMediaCount)"
//            NotificationMethods().sendNotifications()

        }
        else {
            self.tabBarController?.tabBar.items![2].badgeValue = nil
        }
    }
}