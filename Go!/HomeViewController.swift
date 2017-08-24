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
import GeoFire

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var ref : DatabaseReference?
    
    var geoFireRef : DatabaseReference?
    var geoFire : GeoFire?
    var query : GFCircleQuery?
    var geoQueryHandle : DatabaseHandle?
    
    var radius = 5.0
    var listingLimit = 5
    let distanceLimit = 700.0
    
    var databaseListingsHandle : DatabaseHandle?
    var databaseFriendsHandle : DatabaseHandle?
    
    var worldListings = [String : Listing]()
    var followingistings = [String : Listing]()
    var selfListings = [String : Listing]()
    
    var currentListings = [Listing]()
    
    let manager = CLLocationManager()
    var userLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // get reference to database
        ref = Database.database().reference()
        
        geoFireRef = ref?.child(Keys.GeoLocations.rawValue)
        geoFire = GeoFire(firebaseRef: geoFireRef)
        query = geoFire?.query(at: userLocation, withRadius: 5)
        
        geoQueryHandle = query?.observe(.keyEntered, with: { (key, location) in
            
            print("key entered " + key! + " location " + (location?.description)!)
            
            self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: key).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                
                let listingKey = listingSnapshot.key
                if let listingItem = listingSnapshot.value as? [String : Any] {
                    
                    if listingItem[Keys.UserID.rawValue] as? String != Auth.auth().currentUser?.uid {
                        let newListing = ListingsDataSource.sharedInstance.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
                        self.worldListings[listingKey] = newListing
                        print("World listing updated")
                        
                        self.updateListings()
                    }
                }
            })
            
            
        })
        
        query?.observe(.keyExited, with: { (key, location) in
            
            print("key exited " + key!)
            self.worldListings.removeValue(forKey: key!)
            self.updateListings()
        })
        
        query?.observeReady({
            
            print("Query observe Ready")
            
            if self.worldListings.count < self.listingLimit {
                
                if (self.query?.radius.isLessThanOrEqualTo(self.distanceLimit))! {
                   self.query?.radius += 5
                    print("update radius " + (self.query?.radius.description)!)
                } else {
                    let stopLoading: String
                }
                
            } else {
                let stopLoading: String
            }

        })
        
        ref?.child(Keys.UserPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (userPostSnapshot) in
            print("User post added " + userPostSnapshot.key)
            let listingKey = userPostSnapshot.key
            
            self.geoFire?.getLocationForKey(listingKey, withCallback: { (location, error) in
                
                self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                    
                    if let listingItem = listingSnapshot.value as? [String : Any] {
                        let newListing = ListingsDataSource.sharedInstance.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
                        self.selfListings[listingKey] = newListing
                        self.updateListings()
                    }
                    
                })
            })
        })
        
        ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (followerPostSnapshot) in
            print("Following post added " + followerPostSnapshot.key)
            let listingKey = followerPostSnapshot.key
            
            self.geoFire?.getLocationForKey(listingKey, withCallback: { (location, error) in
                self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
                    
                    if let listingItem = listingSnapshot.value as? [String : Any] {
                        let newListing = ListingsDataSource.sharedInstance.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
                        self.followingistings[listingKey] = newListing
                        self.updateListings()
                    }
                    
                })

            })
            
        })
        
        ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childRemoved, with: { (followerPostSnapshot) in
            print("Following post removed " + followerPostSnapshot.key)
            self.followingistings.removeValue(forKey: followerPostSnapshot.key)
            self.updateListings()
        })
        
        ref?.child(Keys.Following.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (followingSnapshot) in
            print("Following child added " + followingSnapshot.key)
            let uid = followingSnapshot.key
            self.ref?.child(Keys.UserPosts.rawValue).child(uid).observeSingleEvent(of: .value, with: { (userPostSnapshot) in
                
                if let listins = userPostSnapshot.value as? [String : Bool] {
                    for listingKey in listins.keys {
                        self.ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).updateChildValues([listingKey : true])
                    }
                }
            })
        })
        
        ref?.child(Keys.Following.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childRemoved, with: { (followingSnapshot) in
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
        
        ref?.child(Keys.Listings.rawValue).observe(.childRemoved, with: { (listingSnapshot) in
            print("Listing removed " + listingSnapshot.key)
            self.ref?.child(Keys.Listings.rawValue).child(listingSnapshot.key).removeValue()
            self.ref?.child(Keys.GeoLocations.rawValue).child(listingSnapshot.key).removeValue()
            //self.worldListings.removeValue(forKey: listingSnapshot.key)
            
            if let listingValue = listingSnapshot.value as? [String : Any] {
                self.ref?.child(Keys.UserPosts.rawValue).child(listingValue["UserID"]! as! String).child(listingSnapshot.key).removeValue()
                self.selfListings.removeValue(forKey: listingSnapshot.key)
            }
            
            self.ref?.child(Keys.Following.rawValue).child((Auth.auth().currentUser?.uid)!).child(listingSnapshot.key).removeValue()
            self.followingistings.removeValue(forKey: listingSnapshot.key)
            
            
            self.updateListings()
        })
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("View Did Appear")
        //updateListings()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("MEMORY WARNING")
    }
    
    @IBAction func OnSegmentValueChanged(_ sender: Any) {
        
        updateListings()
    }
    
    func updateListings() {
        print("Update listings")
        switch segmentControl.selectedSegmentIndex {
        case 0:
            currentListings = Array(worldListings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.distance(to: userLocation) < listing2.distance(to: userLocation)
            })
            break
        case 1:
            currentListings = Array(followingistings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.distance(to: userLocation) < listing2.distance(to: userLocation)
            })

            break
        case 2:
            currentListings = Array(selfListings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.distance(to: userLocation) < listing2.distance(to: userLocation)
            })

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
        
        let lastElement = currentListings.count - 1
        if indexPath.row == lastElement  {
            
            if worldListings.count >= listingLimit {
                listingLimit = worldListings.count + 5
                print("Will Display Cell last element index path row " + indexPath.row.description + " listing limit " + listingLimit.description)
                let startLoading: String
            }
            
            
        }
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
        
        if cell.requestButton.uid == Auth.auth().currentUser?.uid {
            cell.requestButton.backgroundColor = UIColor.red
            cell.requestButton.setTitle("View Requests", for: UIControlState.normal)
        } else {
            cell.requestButton.backgroundColor = UIColor.green
            cell.requestButton.setTitle("Request", for: UIControlState.normal)
        }
        
        return cell 
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        let userLocationCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        userLocation = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)
        
        //print(userLocation)
        query?.center = userLocation
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
