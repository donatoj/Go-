//
//  HomeViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/17/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase
import CoreLocation

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var ref : FIRDatabaseReference?
    var databaseListingsHandle : FIRDatabaseHandle?
    var databaseFriendsHandle : FIRDatabaseHandle?
    
    var worldListings = [String : Listing]()
    var followerListings = [String : Listing]()
    var selfListings = [String : Listing]()
    
    var currentListings = [Listing]()
    
    let manager = CLLocationManager()
    var userLocation = CLLocation()
    
    @IBAction func OnSegmentValueChanged(_ sender: Any) {
        
        updateListings()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
        
        // get reference to database
        ref = FIRDatabase.database().reference()
        
        ref?.child("UserPosts").child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childAdded, with: { (userPostSnapshot) in
            
            let listingKey = userPostSnapshot.key

            self.ref?.child("Listings").queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in

                if let listingItem = listingSnapshot.value as? [String : String] {
                    let newListing = ListingsDataSource.sharedInstance.getNewListing(forKey: listingKey, withSnapshotValue: listingItem)
                    self.selfListings[listingKey] = newListing
                    self.updateListings()
                }
                
            })
        })
        
        ref?.child("FollowerPosts").child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childAdded, with: { (followerPostSnapshot) in
            
            let listingKey = followerPostSnapshot.key
            
            self.ref?.child("Listings").queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                
                if let listingItem = listingSnapshot.value as? [String : String] {
                    let newListing = ListingsDataSource.sharedInstance.getNewListing(forKey: listingKey, withSnapshotValue: listingItem)
                    self.followerListings[listingKey] = newListing
                    self.updateListings()
                }
                
            })
        })
        
        ref?.child("Following").child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childAdded, with: { (followingSnapshot) in

            let uid = followingSnapshot.key
            self.ref?.child("UserPosts").child(uid).observeSingleEvent(of: .value, with: { (userPostSnapshot) in
                
                if let listins = userPostSnapshot.value as? [String : Bool] {
                    for listingKey in listins.keys {
                        self.ref?.child("FollowerPosts").child((FIRAuth.auth()?.currentUser?.uid)!).updateChildValues([listingKey : true])
                    }
                }
            })
        })
        
        ref?.child("Following").child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childRemoved, with: { (followingSnapshot) in

            let uid = followingSnapshot.key
            self.ref?.child("UserPosts").child(uid).observeSingleEvent(of: .value, with: { (userPostSnapshot) in
                
                if let listings = userPostSnapshot.value as? [String : Bool] {
                    for listingKey in listings.keys {
                        self.ref?.child("FollowerPosts").child((FIRAuth.auth()?.currentUser?.uid)!).child(listingKey).removeValue()
                    }
                }
            })
        })
        
        let implementGeoListings : String
        ref?.child("Listings").observe(.childAdded, with: { (listingSnapshot) in
            
            let listingKey = listingSnapshot.key
            if let listingItem = listingSnapshot.value as? [String : String] {
                let newListing = ListingsDataSource.sharedInstance.getNewListing(forKey: listingKey, withSnapshotValue: listingItem)
                self.worldListings[listingKey] = newListing
                self.updateListings()
            }
        })
        
        ref?.child("Listings").observe(.childRemoved, with: { (listingSnapshot) in
            
            self.ref?.child("Listings").child(listingSnapshot.key).removeValue()
            self.worldListings.removeValue(forKey: listingSnapshot.key)
            
            if let listingValue = listingSnapshot.value as? [String : String] {
                self.ref?.child("UserPosts").child(listingValue["UserID"]!).child(listingSnapshot.key).removeValue()
                self.selfListings.removeValue(forKey: listingSnapshot.key)
            }
            
                self.ref?.child("FollowerPosts").child((FIRAuth.auth()?.currentUser?.uid)!).child(listingSnapshot.key).removeValue()
                self.followerListings.removeValue(forKey: listingSnapshot.key)
            
            
            self.updateListings()
        })
        
        ref?.child("FollowerPosts").child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childRemoved, with: { (followerPostSnapshot) in
            
            self.followerListings.removeValue(forKey: followerPostSnapshot.key)
            self.updateListings()
        })
        
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    
    func reloadListings() {
        
    }
    
    func updateListings() {
        
        switch segmentControl.selectedSegmentIndex {
        case 0:
            currentListings = Array(worldListings.values)
            break
        case 1:
            currentListings = Array(followerListings.values)
            break
        case 2:
            currentListings = Array(selfListings.values)
            break
        default:
            break
        }
        
        tableView.reloadData()
        tableView.separatorStyle = .none
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.viewWithTag(1)?.removeFromSuperview()
        let separatorLine = UIImageView.init(frame: CGRect(x: 61, y: cell.frame.height - 1, width: cell.frame.width - 61, height: 1))
        separatorLine.backgroundColor = UIColor.lightGray
        separatorLine.tag = 1
        cell.addSubview(separatorLine)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        let userLocationCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        userLocation = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return currentListings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PostTableViewCell
        
        let listingItem = currentListings[indexPath.row]
                
        // check for only items not from user
        cell.userNameButton.setTitle(listingItem.userName, for: UIControlState.normal)
        (cell.userNameButton as! UserNameButton).uid = listingItem.uid
        cell.requestButton.uid = listingItem.uid
        cell.requestButton.key = listingItem.key
        cell.descriptionLabel.text = listingItem.description
        cell.amountLabel.text = "$" + listingItem.amount
        
        cell.profileImageView.image = listingItem.profilePhoto
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = true;
        
        cell.timeAgo.text = listingItem.timeAgoSinceDate(true)
        cell.distance.text = listingItem.getDistanceFromListing(userLocation: userLocation)
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell 
    }
    
    deinit {
        print("HomeViewController Deinitialized")
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
        
        if let userNameButton = sender as? UserNameButton {
            print("sender is ui button")
            let nextScene = segue.destination as! ProfileViewController
            nextScene.uid = userNameButton.uid
        }
        else {
            print("sender is not a ui button")
        }
     }
 
    
}
