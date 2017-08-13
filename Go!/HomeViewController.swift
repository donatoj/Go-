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
    
    var worldListings = [Listing]()
    var friendListings = [Listing]()
    var selfListings = [Listing]()
    
    var currentListings = [Listing]()
    
    var friends = [String]()
    
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
        
        databaseFriendsHandle = ref?.child("Friends").child((FIRAuth.auth()?.currentUser?.uid)!).observe(.value, with: { (friendSnapshot) in
            
            print("Friends update")
            self.friends.removeAll()
            if let friends = friendSnapshot.value as? [String : Bool] {
                
                for friend in friends.keys {
                    print(friend + "is a friend")
                    self.friends.append(friend)
                }
            }
            self.reloadListings()
            
        })
        
        // save all items in Listings node to dictionary array
        databaseListingsHandle = ref?.child("Listings").observe(.value, with: { (snapshot) in
            
            self.reloadListings()
        })
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    
    func reloadListings() {
        
        let setupQuery: String
        ref?.child("Listings").observeSingleEvent(of: .value, with: { (snapshot) in
            
            print("Reload Listings update")
            self.worldListings.removeAll()
            self.friendListings.removeAll()
            self.selfListings.removeAll()
            
            if let listingDict = snapshot.value as? [String : AnyObject] {
            
                for listing in listingDict {
                    let dict : [String : AnyObject] = [listing.key : listing.value]
                    
                    for dictValues in dict.values {
                        if let listingItem = dictValues as? [String : String] {
                            let newListing = Listing(userName: listingItem["Username"]!, uid: listingItem["UserID"]!, description: listingItem["Description"]!, amount: listingItem["Amount"]!, photoURL: listingItem["ProfileURL"]!, datePosted: listingItem["DatePosted"]!, latitude: listingItem["UserLatitude"]! as NSString, longitude: listingItem["UserLongitude"]! as NSString, key: listingItem["ListingKey"]! as String)
                            
                            if self.friends.contains(listingItem["UserID"]!) {
                                self.friendListings.append(newListing)
                            } else if FIRAuth.auth()?.currentUser?.uid == newListing.uid {
                                self.selfListings.append(newListing)
                            } else {
                                self.worldListings.append(newListing)
                            }
                        }
                    }
                }
                print("Updating table view")
                self.updateListings()
            }
        })
    }
    
    func updateListings() {
        
        switch segmentControl.selectedSegmentIndex {
        case 0:
            currentListings = worldListings
            break
        case 1:
            currentListings = friendListings
            break
        case 2:
            currentListings = selfListings
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
