//
//  ListingsDataSource.swift
//  Go!
//
//  Created by Jordan Donato on 8/15/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import CoreLocation

class ListingsDataSource {
    
    static let sharedInstance = ListingsDataSource()
    
    // Get a new listing
    func getNewListing(forKey : String, withSnapshotValue: [String : Any], location : CLLocation) -> Listing? {
        
        var newListing : Listing?
        
        newListing = Listing(userName: withSnapshotValue[Keys.Username.rawValue]! as! String,
                             uid: withSnapshotValue[Keys.UserID.rawValue]! as! String,
                             description: withSnapshotValue[Keys.Description.rawValue]! as! String,
                             amount: withSnapshotValue[Keys.Amount.rawValue]! as! String,
                             photoURL: withSnapshotValue[Keys.ProfileURL.rawValue]! as! String,
                             datePosted: withSnapshotValue[Keys.DatePosted.rawValue]! as! String,
                             latitude: location.coordinate.latitude,
                             longitude: location.coordinate.longitude,
                             key: forKey
        )
        
       return newListing
    }
    
}
