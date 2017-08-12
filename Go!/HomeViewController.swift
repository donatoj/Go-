//
//  HomeViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/17/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import FirebaseDatabase
import CoreLocation

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var ref : FIRDatabaseReference?
    var databaseHandle : FIRDatabaseHandle?
    
    var listings = [Listing]()
    
    let manager = CLLocationManager()
    var userLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
        
        // get reference to database
        ref = FIRDatabase.database().reference()
        
        // save all items in Listings node to dictionary array
        databaseHandle = ref?.child("Listings").observe(.value, with: { (snapshot) in
            
            let listingDict = snapshot.value as? [String : AnyObject] ?? [:]
            
            self.listings.removeAll()
            for listing in listingDict {
                let dict : [String : AnyObject] = [listing.key : listing.value]
                
                for dictValues in dict.values {
                    if let listingItem = dictValues as? [String : String] {
                        let newListing = Listing(userName: listingItem["Username"]!, description: listingItem["Description"]!, amount: listingItem["Amount"]!, photoURL: listingItem["ProfileURL"]!, datePosted: listingItem["DatePosted"]!, latitude: listingItem["UserLatitude"]! as NSString, longitude: listingItem["UserLongitude"]! as NSString)
                        self.listings.append(newListing)
                    }
                }
            }
            
            print("Updating table view")
            self.tableView.reloadData()
        })
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
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
        
        return listings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PostTableViewCell
        
        let listingItem = listings[indexPath.row]
                
        // check for only items not from user
        cell.userNameButton.setTitle(listingItem.userName, for: UIControlState.normal)
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
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
