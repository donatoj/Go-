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

class ListingsDataSource {
    
    static let sharedInstance = ListingsDataSource()
    
    // Get a new listing
    func getNewListing(forKey : String, withSnapshotValue: [String : String]) -> Listing? {
        
        var newListing : Listing?
        
        newListing = Listing(userName: withSnapshotValue["Username"]!,
                             uid: withSnapshotValue["UserID"]!,
                             description: withSnapshotValue["Description"]!,
                             amount: withSnapshotValue["Amount"]!,
                             photoURL: withSnapshotValue["ProfileURL"]!,
                             datePosted: withSnapshotValue["DatePosted"]!,
                             latitude: withSnapshotValue["UserLatitude"]! as NSString,
                             longitude: withSnapshotValue["UserLongitude"]! as NSString,
                             key: withSnapshotValue["ListingKey"]! as String
        )
        
       return newListing
    }
    
}
