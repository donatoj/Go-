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
    
    var currentListings = [Listing]()
    
    let manager = CLLocationManager()
    var userLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ListingsDataSource.sharedInstance.registerObservers(userLocation: userLocation)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("View Did Appear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("MEMORY WARNING")
    }
    
    @IBAction func OnSegmentValueChanged(_ sender: Any) {
        updateListings()
    }
    @IBAction func OnRequestButtonPressed(_ sender: Any) {
        
        let requestButton = sender as! RequestButton
        
        if requestButton.uid == Auth.auth().currentUser?.uid {
            
            // go to approval table view\
            self.performSegue(withIdentifier: "showRequests", sender: requestButton)
            
        } else {
            let requestedStateBasedOnDatabase: String
            if requestButton.requested {
                requestButton.alpha = 1
                requestButton.requested = false
                
                ListingsDataSource.sharedInstance.updateRequests(forKey: requestButton.key, updateChild: false)
            }
            else {
                requestButton.alpha = 0.5
                requestButton.requested = true
                
                ListingsDataSource.sharedInstance.updateRequests(forKey: requestButton.key, updateChild: true)
            }
        }
    }
    
    func updateListings() {
        print("Update listings")
        switch segmentControl.selectedSegmentIndex {
        case 0:
            currentListings = Array(ListingsDataSource.sharedInstance.worldListings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.distance(to: userLocation) < listing2.distance(to: userLocation)
            })
            break
        case 1:
            currentListings = Array(ListingsDataSource.sharedInstance.followingistings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.distance(to: userLocation) < listing2.distance(to: userLocation)
            })

            break
        case 2:
            currentListings = Array(ListingsDataSource.sharedInstance.selfListings.values).sorted(by: { (listing1, listing2) -> Bool in
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
            
            ListingsDataSource.sharedInstance.updateListingLimit()
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
        cell.requestButton.setTitle("$" + listingItem.amount, for: UIControlState.normal)
        
        cell.profileImageView.image = listingItem.profilePhoto
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = true;
        
        cell.timeAgo.text = listingItem.timeAgoSinceDate(true)
        cell.distance.text = listingItem.getDistanceFromListing(userLocation: userLocation)
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        if cell.requestButton.uid == Auth.auth().currentUser?.uid {
            cell.requestButton.backgroundColor = UIColor.red
            cell.requestButton.alpha = 1
        } else {
            cell.requestButton.backgroundColor = UIColor.green
        }
        
        return cell 
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        let userLocationCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        userLocation = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)
        
        //print(userLocation)
        ListingsDataSource.sharedInstance.query?.center = userLocation
        updateListings()
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
        
        if let requestButton = sender as? RequestButton {
            print("sender is request button")
            let nextScene = segue.destination as! RequestsTableViewController
            nextScene.key = requestButton.key
        }
     }
}
