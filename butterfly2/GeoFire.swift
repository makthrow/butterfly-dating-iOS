//
//  GeoFire.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/7/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation
import FirebaseAuth

var currentLocation: CLLocation?


func getUserLocation () {
    Constants.geoFireUsers?.getLocationForKey(Constants.userID, withCallback: { (location, error) in
        if (error != nil) {
            print("An error occurred getting the location for \(Constants.userID): \(error?.localizedDescription)")
        }
        else if (location != nil) {
//            print("Location for \(Constants.userID) is [\(location?.coordinate.latitude), \(location?.coordinate.longitude)]")
            currentLocation = location
        }
        else {
            print("GeoFire does not contain a location for \(Constants.userID)")
        }
    })
}
