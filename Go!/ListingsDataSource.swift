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
        
        newListing = Listing(userName: withSnapshotValue["Username"]! as! String,
                             uid: withSnapshotValue["UserID"]! as! String,
                             description: withSnapshotValue["Description"]! as! String,
                             amount: withSnapshotValue["Amount"]! as! String,
                             photoURL: withSnapshotValue["ProfileURL"]! as! String,
                             datePosted: withSnapshotValue["DatePosted"]! as! String,
                             latitude: location.coordinate.latitude,
                             longitude: location.coordinate.longitude,
                             key: forKey
        )
        
       return newListing
    }
    
}
