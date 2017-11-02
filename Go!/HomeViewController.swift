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

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
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
    
    var currentListings = [Listing]()
    
    let manager = CLLocationManager()
    var userLocation = CLLocation()
    
    var searchController : UISearchController!
    
    var myPostsViewController : MyPostsViewController!
    
    @IBAction func OnSegmentValueChanged(_ sender: Any) {
        updateListings(segmentChanged: true)
    }
    
    fileprivate func showSearchBar() {
        searchController = UISearchController(searchResultsController:  nil)
        
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = true
        
        if #available(iOS 11.0, *) {
            if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
                
                if let backgroundview = textfield.subviews.first {
                    
                    // Background color
                    backgroundview.backgroundColor = UIColor.white
                    
                    // Rounded corner
                    backgroundview.layer.cornerRadius = 10;
                    backgroundview.clipsToBounds = true;
                    
                }
            }
            
            navigationItem.searchController = searchController
            navigationItem.searchController?.isActive = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        definesPresentationContext = true
    }
    
    fileprivate func setupMenu() {
        // Define the menus
        let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as! UISideMenuNavigationController
        //let menuRightNavigationController = storyboard!.instantiateViewController(withIdentifier: "RightMenuNavigationController") as! UISideMenuNavigationController
        // UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration
        // of it here like setting its viewControllers. If you're using storyboards, you'll want to do something like:
        // let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as! UISideMenuNavigationController
        SideMenuManager.default.menuLeftNavigationController = menuLeftNavigationController
        //SideMenuManager.default.menuRightNavigationController = menuRightNavigationController
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.default.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.default.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
        SideMenuManager.default.menuPushStyle = .preserve
        SideMenuManager.default.menuFadeStatusBar = false
        SideMenuManager.default.menuBlurEffectStyle = UIBlurEffectStyle.dark
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        
        showSearchBar()
        setupMenu()
        
        registerObservers(userLocation: userLocation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("View Did Appear")
        
        manager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("View Did disappear")
        //removeAllObservers()
        manager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("***********MEMORY WARNING*************")
    }

    func updateListings(segmentChanged : Bool) {
        print("Update listings")

        switch segmentControl.selectedSegmentIndex {
        case 0:
            currentListings = Array(worldListings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.timeAgoSinceDate() < listing2.timeAgoSinceDate()
            })
            
            break
        case 1:
            currentListings = Array(followingistings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.timeAgoSinceDate() < listing2.timeAgoSinceDate()            })
            
            break
        case 2:
            let needDirectListings : String
            currentListings.removeAll()
            break
        case 3:
            currentListings = Array(requestListings.values).sorted(by: { (listing1, listing2) -> Bool in
                return listing1.timeAgoSinceDate() < listing2.timeAgoSinceDate()            })
            
        default:
            break
        }
        tableView.reloadData()
    }
    
    @objc func onRequestPressed(_ sender: UIButton) {
        let listingItem = currentListings[sender.tag]
        updateRequests(forKey: listingItem.key, updateChild: !listingItem.requested)
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
            let listingItem = currentListings[button.tag]
            if (button.accessibilityIdentifier?.contains("requestButton"))! {
                print("sender is request button")
                let nextScene = segue.destination as! RequestsTableViewController
                nextScene.key = listingItem.key
            } else if (button.accessibilityIdentifier?.contains("usernameButton"))!{
                print("sender is ui button")
                let nextScene = segue.destination as! ProfileViewController
                nextScene.uid = listingItem.uid
            }
        }
        
        if segue.destination is UISideMenuNavigationController {
            print("going to menu view controller")
        } else if let controller = segue.destination as? UINavigationController {
            print("going to my posts view controller")
            myPostsViewController = controller.viewControllers.first as! MyPostsViewController
            myPostsViewController.dataSource = self as MyPostsDataSource
        }
    }
    

}

extension HomeViewController : UITableViewDataSource {
    
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
        
        cell.requestButton.setTitle("$" + listingItem.amount, for: UIControlState.normal)
        cell.requestButton.layer.borderWidth = 1
        cell.requestButton.layer.cornerRadius = 8
        cell.requestButton.clipsToBounds = true
        cell.requestButton.tag = indexPath.section
        cell.requestButton.addTarget(self, action: #selector(onRequestPressed(_:)), for: .touchUpInside)
        
        if listingItem.requested {
            if segmentControl.selectedSegmentIndex == 3 {
                cell.requestButton.backgroundColor = UIColor.red
                cell.requestButton.layer.borderColor = UIColor.red.cgColor
            } else {
                cell.requestButton.backgroundColor = UIColor.seafoam
                cell.requestButton.layer.borderColor = UIColor.seafoam.cgColor
            }
            cell.requestButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            cell.requestButton.backgroundColor = UIColor.white
            cell.requestButton.layer.borderColor = UIColor.seafoam.cgColor
            cell.requestButton.setTitleColor(UIColor.seafoam, for: .normal)
        }
        
        cell.layer.cornerRadius = 10
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell
    }
    
}

extension HomeViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let lastElement = currentListings.count - 1
        if indexPath.section == lastElement  {
            
            updateListingLimit()
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
}

extension HomeViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        let userLocationCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        userLocation = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)
        
        //print(userLocation)
        query?.center = userLocation
    }
}

extension HomeViewController : UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        print("update search results")
    }
}

// Database functions
extension HomeViewController {
    
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
                    self.updateListings(segmentChanged: false)
                    print("stoploading 1")
                }
                
            } else {
                let stopLoading: String
                self.updateListings(segmentChanged: false)
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
    
    func registerUserPostRemoved() {
        let removeActiveListingsIfapplicable : String
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
                        }
                    }
                    self.ref?.updateChildValues(childUpdates)
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
        registerUserPostRemoved()
        
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
        ref?.child(Keys.Requests.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
    }
    
    func updateListingLimit() {
        
        if worldListings.count >= listingLimit {
            listingLimit = worldListings.count + 5
            print("Will Display Cell last element index path row ")
            let startLoading: String
        }
    }
    
    func updateRequests(forKey : String, updateChild : Bool) {
        
        var request = [String : Any]()

        if updateChild {
            request["/\(Keys.Listings.rawValue)/\(forKey)/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)"] = false
            request["/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)/\(forKey)"] = false
            
            ref?.updateChildValues(request, withCompletionBlock: { (error, ref) in
                self.worldListings[forKey]?.requested = true
                self.followingistings[forKey]?.requested = true
                self.requestListings[forKey]?.requested = true
                self.updateListings(segmentChanged: false)
            })
        } else {
            request["/\(Keys.Listings.rawValue)/\(forKey)/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)"] = NSNull()
            request["/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)/\(forKey)"] = NSNull()
            
            ref?.updateChildValues(request, withCompletionBlock: { (error, ref) in
                
                self.worldListings[forKey]?.requested = false
                self.followingistings[forKey]?.requested = false
                self.requestListings[forKey]?.requested = false
                self.updateListings(segmentChanged: false)
            })
        }
    }
}

extension HomeViewController : MyPostsDataSource {
    func getSelfListings() -> [String : Listing] {
        return selfListings
    }
}
