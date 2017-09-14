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
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("View Did Appear")
        ListingsDataSource.sharedInstance.registerObservers(userLocation: userLocation)
        manager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("View Did disappear")
        ListingsDataSource.sharedInstance.removeAllObservers()
        manager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("MEMORY WARNING")
    }
    
    @IBAction func OnSegmentValueChanged(_ sender: Any) {
        updateListings(segmentChanged: true)
    }

    func onRequestPressed(_ sender: UIButton) {
        
        let listingItem = currentListings[sender.tag]
        
        if listingItem.uid == Auth.auth().currentUser?.uid {
            
            let removeThisWhenSelfPostsAreDone : String
            // go to approval table view\
            self.performSegue(withIdentifier: "showRequests", sender: sender)
            
        } else {
            ListingsDataSource.sharedInstance.updateRequests(forKey: listingItem.key, updateChild: !listingItem.requested)
            updateListings(segmentChanged: false)
        }
    }

    
    func updateListings(segmentChanged : Bool) {
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
        
        let lastElement = currentListings.count - 1
        if indexPath.section == lastElement  {
            
            ListingsDataSource.sharedInstance.updateListingLimit()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerview = UIView()
        headerview.backgroundColor = UIColor.clear
        return headerview
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return currentListings.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PostTableViewCell
        
        let listingItem = currentListings[indexPath.section]
                
        // check for only items not from user
        cell.userNameButton.setTitle(listingItem.userName, for: UIControlState.normal)
        cell.userNameButton.tag = indexPath.section
        
        cell.descriptionLabel.text = listingItem.description
        
        cell.profileImageView.image = listingItem.profilePhoto
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = true;
        
        cell.timeAgo.text = listingItem.timeAgoSinceDate(true)
        cell.distance.text = listingItem.getDistanceFromListing(userLocation: userLocation)
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        cell.requestButton.setTitle("$" + listingItem.amount, for: UIControlState.normal)
        cell.requestButton.layer.borderWidth = 1
        cell.requestButton.layer.borderColor = UIColor.blue.cgColor
        cell.requestButton.layer.cornerRadius = 8
        cell.requestButton.clipsToBounds = true
        cell.requestButton.tag = indexPath.section
        cell.requestButton.addTarget(self, action: #selector(onRequestPressed(_:)), for: .touchUpInside)
        
        if listingItem.requested {
            cell.requestButton.backgroundColor = UIColor.blue
            cell.requestButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            cell.requestButton.backgroundColor = UIColor.white
            cell.requestButton.setTitleColor(UIColor.blue, for: .normal)
        }
        
        return cell 
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        let userLocationCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        userLocation = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)
        
        //print(userLocation)
        ListingsDataSource.sharedInstance.query?.center = userLocation
        updateListings(segmentChanged: false)
    }
    
    deinit {
        print("HomeViewController Deinitialized")
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
        
        if let button = sender as? UIButton {
            if (button.accessibilityIdentifier?.contains("requestButton"))! {
                print("sender is request button")
                let nextScene = segue.destination as! RequestsTableViewController
                let listingItem = currentListings[button.tag]
                nextScene.key = listingItem.key
            } else if (button.accessibilityIdentifier?.contains("usernameButton"))!{
                print("sender is ui button")
                let nextScene = segue.destination as! ProfileViewController
                let listingItem = currentListings[button.tag]
                nextScene.uid = listingItem.uid
                
            }
        }
            
     }
}
