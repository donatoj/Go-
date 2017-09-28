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
import GeoFire

class ListingsDataSource {
    
    static let sharedInstance = ListingsDataSource()
    
    var ref : DatabaseReference?
    
    var geoFireRef : DatabaseReference?
    var geoFire : GeoFire?
    var query : GFCircleQuery?
    var geoQueryHandle : DatabaseHandle?
    
    var worldListings = [String : Listing]()
    var followingistings = [String : Listing]()
    var selfListings = [String : Listing]()
    var requestListings = [String : Listing]()
    
    var listingLimit = 5
    let distanceLimit = 700.0
    
    // Get a new listing
    func getNewListing(forKey : String, withSnapshotValue: [String : Any], location : CLLocation) -> Listing? {
        
        var newListing : Listing?
        
        let requests = withSnapshotValue["Requests"] as? [String: Bool]
        let requested = requests?[(Auth.auth().currentUser?.uid)!] != nil
        
        newListing = Listing(userName: withSnapshotValue[Keys.Username.rawValue]! as! String,
                             uid: withSnapshotValue[Keys.UserID.rawValue]! as! String,
                             description: withSnapshotValue[Keys.Description.rawValue]! as! String,
                             amount: withSnapshotValue[Keys.Amount.rawValue]! as! String,
                             photoURL: withSnapshotValue[Keys.ProfileURL.rawValue]! as! String,
                             datePosted: withSnapshotValue[Keys.DatePosted.rawValue]! as! String,
                             latitude: location.coordinate.latitude,
                             longitude: location.coordinate.longitude,
                             key: forKey,
                             requested: requested
        )
        
       return newListing
    }
    
    func registerGeoQueryKeyEntered() {
        
        geoQueryHandle = query?.observe(.keyEntered, with: { (key, location) in
            
            print("key entered " + key! + " location " + (location?.description)!)
            
            self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: key).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                
                let listingKey = listingSnapshot.key
                if let listingItem = listingSnapshot.value as? [String : Any] {
                    
                    if listingItem[Keys.UserID.rawValue] as? String != Auth.auth().currentUser?.uid {
                        let newListing = self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
                        self.worldListings[listingKey] = newListing
                        print("World listing updated")
                        
                    }
                }
            })
        })
    }
    
    func registerGeoQueryKeyExit() {
        
        query?.observe(.keyExited, with: { (key, location) in
            
            print("key exited " + key!)
            self.worldListings.removeValue(forKey: key!)
        })
    }
    
    func registerGeoQueryObserveReady() {
        
        query?.observeReady({
            
            print("Query observe Ready")
            
            if self.worldListings.count < self.listingLimit {
                
                if (self.query?.radius.isLessThanOrEqualTo(self.distanceLimit))! {
                    self.query?.radius += 5
                    print("update radius " + (self.query?.radius.description)!)
                } else {
                    let stopLoading: String
                    print("stoploading 1")
                }
                
            } else {
                let stopLoading: String
                print("stop loading 2")
            }
        })
    }
    
    func registerUserPostAdded() {
        
        ref?.child(Keys.UserPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (userPostSnapshot) in
            print("User post added " + userPostSnapshot.key)
            let listingKey = userPostSnapshot.key
            
            self.geoFire?.getLocationForKey(listingKey, withCallback: { (location, error) in
                
                self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                    
                    if let listingItem = listingSnapshot.value as? [String : Any] {
                        let newListing = self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
                        self.selfListings[listingKey] = newListing
                    }
                    
                })
            })
        })
    }
    
    func registerListingRemoved() {
        
        ref?.child(Keys.Listings.rawValue).observe(.childRemoved, with: { (listingSnapshot) in
            
            print("Listing removed " + listingSnapshot.key)
            
            var childUpdates = [String : NSNull]()
            
            childUpdates["/\(Keys.GeoLocations.rawValue)/\(listingSnapshot.key)"] = NSNull()
            
            if let listingValue = listingSnapshot.value as? [String : Any] {
                
                childUpdates["/\(Keys.UserPosts.rawValue)/\(listingValue["UserID"]! as! String)/\(listingSnapshot.key)"] = NSNull()
                self.selfListings.removeValue(forKey: listingSnapshot.key)
                
                self.ref?.child(Keys.Users.rawValue).child(listingValue["UserID"]! as! String).child(Keys.Followers.rawValue).observeSingleEvent(of: .value, with: { (followerSnapshot) in
                    if let followers = followerSnapshot.value as? [String : Bool] {
                        for followerKey in followers.keys {
                            print("found follower post to remove from " + followerKey)
                            childUpdates["/\(Keys.FollowingPosts.rawValue)/\(followerKey)/\(listingSnapshot.key)"] = NSNull()
                            
                            self.ref?.updateChildValues(childUpdates)
                        }
                    }
                })
            }
        })
    }
    
    func registerFollowingPostAdded() {
        
        ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (followerPostSnapshot) in
            print("Following post added " + followerPostSnapshot.key)
            let listingKey = followerPostSnapshot.key
            
            self.geoFire?.getLocationForKey(listingKey, withCallback: { (location, error) in
                self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                    
                    if let listingItem = listingSnapshot.value as? [String : Any] {
                        let newListing = self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
                        self.followingistings[listingKey] = newListing
                    }
                    
                })
                
            })
            
        })
    }
    
    func registerFollowingPostRemoved() {
        
        ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childRemoved, with: { (followerPostSnapshot) in
            print("Following post removed " + followerPostSnapshot.key)
            self.followingistings.removeValue(forKey: followerPostSnapshot.key)
        })
    }
    
    func registerFollowingAdded() {
        
        ref?.child(Keys.Users.rawValue).child((Auth.auth().currentUser?.uid)!).child(Keys.Following.rawValue).observe(.childAdded, with: { (followingSnapshot) in
            print("Following child added " + followingSnapshot.key)
            let uid = followingSnapshot.key
            self.ref?.child(Keys.UserPosts.rawValue).child(uid).observeSingleEvent(of: .value, with: { (userPostSnapshot) in
                
                if let listings = userPostSnapshot.value as? [String : Bool] {
                    for listingKey in listings.keys {
                        self.ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).updateChildValues([listingKey : true])
                    }
                }
            })
        })
    }
    
    func registerFollowingRemoved() {
    ref?.child(Keys.Users.rawValue).child((Auth.auth().currentUser?.uid)!).child(Keys.Following.rawValue).observe(.childRemoved, with: { (followingSnapshot) in
            print("Following removed " + followingSnapshot.key)
            let uid = followingSnapshot.key
            self.ref?.child(Keys.UserPosts.rawValue).child(uid).observeSingleEvent(of: .value, with: { (userPostSnapshot) in
                
                if let listings = userPostSnapshot.value as? [String : Bool] {
                    for listingKey in listings.keys {
                        self.ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).child(listingKey).removeValue()
                    }
                }
            })
        })
    }
    
    func registerRequestsAdded() {
        ref?.child(Keys.Requests.rawValue).child((Auth.auth().currentUser?.uid)!).observe(DataEventType.childAdded, with: { (requestSnapshot) in
            
                let listingKey = requestSnapshot.key
                self.geoFire?.getLocationForKey(listingKey, withCallback: { (location, error) in
                self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                    
                    if let listingItem = listingSnapshot.value as? [String : Any] {
                        let newListing = self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
                        print("request added " + listingKey)
                        self.requestListings[listingKey] = newListing
                    }
                    
                    })
                
                })
                
            })
    }
    
    func registerRequestsRemoved() {
        
        ref?.child(Keys.Requests.rawValue).child((Auth.auth().currentUser?.uid)!).observe(DataEventType.childRemoved, with: { (requestSnapshot) in
            print("request removed " + requestSnapshot.key)
            let listingKey = requestSnapshot.key
            self.requestListings.removeValue(forKey: listingKey)
        })
    }
    
    func registerObservers(userLocation : CLLocation)  {
        
        // get reference to database
        ref = Database.database().reference()
        
        geoFireRef = ref?.child(Keys.GeoLocations.rawValue)
        geoFire = GeoFire(firebaseRef: geoFireRef)
        query = geoFire?.query(at: userLocation, withRadius: 5)
        
        registerGeoQueryKeyEntered()
        registerGeoQueryKeyExit()
        registerGeoQueryObserveReady()
        
        registerUserPostAdded()
        registerListingRemoved()
    
        registerFollowingPostAdded()
        registerFollowingPostRemoved()
        
        registerFollowingAdded()
        registerFollowingRemoved()
        
        registerRequestsAdded()
        registerRequestsRemoved()

    }
    
    func removeAllObservers() {
        
        query?.removeAllObservers()
        
        ref?.child(Keys.UserPosts.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
        ref?.child(Keys.Listings.rawValue).removeAllObservers()
        ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
        ref?.child(Keys.Users.rawValue).child((Auth.auth().currentUser?.uid)!).child(Keys.Following.rawValue).removeAllObservers()
        
    }
    
    func updateListingLimit() {
        
        if worldListings.count >= listingLimit {
            listingLimit = worldListings.count + 5
            print("Will Display Cell last element index path row ")
            let startLoading: String
        }
    }
    
    func updateRequests(forKey : String, updateChild : Bool) {
        
        if updateChild {
            
            var request = [String : Any]()
            request["/\(Keys.Listings.rawValue)/\(forKey)/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)"] = false
            request["/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)/\(forKey)"] = false
            ref?.updateChildValues(request)
            
            worldListings[forKey]?.requested = true
            followingistings[forKey]?.requested = true
            requestListings[forKey]?.requested = true
        } else {
            
            var request = [String : Any]()
            request["/\(Keys.Listings.rawValue)/\(forKey)/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)"] = NSNull()
            request["/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)/\(forKey)"] = NSNull()
            ref?.updateChildValues(request)
            
            worldListings[forKey]?.requested = false
            followingistings[forKey]?.requested = false
            requestListings[forKey]?.requested = false
        }
    }
    

    
}
