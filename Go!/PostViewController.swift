//
//  NewListingViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/21/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import GeoFire

class PostViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var ref : DatabaseReference?
    var geoFireRef : DatabaseReference?
    var geoFire : GeoFire?
    
    var postDict = [String : String]()
    
    let manager = CLLocationManager()
    var userLocation : CLLocationCoordinate2D!
    
    var followerKeyList = [String]()
    
    @IBAction func cancelPressed(_ sender: Any) {
        
        // create alert before canceling
        amountTextField.text = ""
        descriptionTextView.text = ""
        
        manager.stopUpdatingLocation()
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        
        if let key = ref?.child(Keys.Listings.rawValue).childByAutoId().key {
            
            
            geoFireRef = ref?.child(Keys.GeoLocations.rawValue)
            geoFire = GeoFire(firebaseRef: geoFireRef)
            geoFire?.setLocation(getUserLocation(), forKey: key)
            
            //todo check for null fields and create alert with activity bar
            postDict[Keys.Username.rawValue] = Auth.auth().currentUser?.displayName
            postDict[Keys.UserID.rawValue] = Auth.auth().currentUser?.uid
            postDict[Keys.ProfileURL.rawValue] = Auth.auth().currentUser?.providerData[0].photoURL?.absoluteString
            postDict[Keys.Description.rawValue] = descriptionTextView.text
            postDict[Keys.Amount.rawValue] = amountTextField.text
            
            postDict[Keys.DatePosted.rawValue] = Date().description
                        
            ref?.child(Keys.Listings.rawValue).child(key).updateChildValues(postDict)
            ref?.child(Keys.UserPosts.rawValue).child((Auth.auth().currentUser?.uid)!).updateChildValues([key : true])
            
            for followerKey in followerKeyList {
                ref?.child(Keys.FollowingPosts.rawValue).child(followerKey).updateChildValues([key : true])
            }
            
            
            
            manager.stopUpdatingLocation()
            
            presentingViewController?.dismiss(animated: true, completion: nil)
            
        } else {
            let keyFailed: String
        }
    }
    
    func getUserLocation() -> CLLocation {
        
        let lat = userLocation.latitude
        let long = userLocation.longitude
        let location = CLLocation(latitude: lat, longitude: long)
        
        return location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        userLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = Database.database().reference()
        
        ref?.child(Keys.Following.rawValue).child((Auth.auth().currentUser?.uid)!).queryOrderedByKey().observeSingleEvent(of: .childAdded, with: { (friendSnapshot) in
            
            print("follower snapshot " + friendSnapshot.key)
            self.followerKeyList.append(friendSnapshot.key)
            
        })
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        print("PostViewController Deinitialized")
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
