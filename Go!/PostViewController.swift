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

class PostViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var ref : FIRDatabaseReference?
    var postDict = [String : String]()
    
    let manager = CLLocationManager()
    var userLocation : CLLocationCoordinate2D!
    
    @IBAction func cancelPressed(_ sender: Any) {
        
        // create alert before canceling
        amountTextField.text = ""
        descriptionTextView.text = ""
        
        manager.stopUpdatingLocation()
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        
        //todo check for null fields and create alert with activity bar
        postDict["Username"] = FIRAuth.auth()?.currentUser?.displayName
        postDict["UserID"] = FIRAuth.auth()?.currentUser?.uid
        postDict["ProfileURL"] = FIRAuth.auth()?.currentUser?.providerData[0].photoURL?.absoluteString
        postDict["Description"] = descriptionTextView.text
        postDict["Amount"] = amountTextField.text
        
        postDict["DatePosted"] = Date().description
        postDict["UserLatitude"] = userLocation.latitude.description
        postDict["UserLongitude"] = userLocation.longitude.description
        
        let key = ref?.child("Listings").childByAutoId().key
        postDict["ListingKey"] = key
        
        ref?.child("Listings").child(key!).setValue(postDict)
        
        manager.stopUpdatingLocation()
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        userLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        
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
