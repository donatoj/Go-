//
//  MapViewController.swift
//  Go!
//
//  Created by Jordan Donato on 7/14/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth

class MapViewController: UIViewController, MKMapViewDelegate {
	// MARK: - Outlets
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var profileButton: UIButton!
	
	// MARK: - Members
	let locationManager = CLLocationManager()
	var userLocation = CLLocation()
	var listingManager = ListingManager.sharedInstance
	
	// MARK: - ViewController LifeCycle
	override func viewDidLoad() {
        super.viewDidLoad()
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
        // Do any additional setup after loading the view.
		
		listingManager.mapViewDelegate = self
		
		setProfilePhoto()
    }
	
	override func viewDidAppear(_ animated: Bool) {

	}
	
	override func viewDidDisappear(_ animated: Bool) {
		locationManager.stopUpdatingLocation()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	// MARK: - Private methods
	fileprivate func setMapViewRegion(forLocation: CLLocationCoordinate2D)  {
		let latDelta: CLLocationDegrees = 0.05
		let longDelta: CLLocationDegrees = 0.05
		
		let span: MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
		let region: MKCoordinateRegion = MKCoordinateRegionMake(forLocation, span)
		
		mapView.setRegion(region, animated: true)
	}
	
	fileprivate func setProfilePhoto() {
		let user = Auth.auth().currentUser
		let url = user?.providerData[0].photoURL
		if let data = try? Data(contentsOf: url!) {
			profileButton.setImage(UIImage(data: data), for: UIControlState.normal)
		} else {
			profileButton.setImage(UIImage(named: "Profile"), for: UIControlState.normal)
		}
		profileButton.layer.borderWidth = 2
		profileButton.layer.borderColor = UIColor.seafoam.cgColor
		profileButton.layer.cornerRadius = profileButton.frame.size.width / 2
		profileButton.clipsToBounds = true
	}
}

// MARK: - Location extension
extension MapViewController : CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let location = locations[0]
		let userLocationCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
		userLocation = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)
	}
}

// MARK: - ListingManager extension
extension MapViewController : ListingManagerDelegate {
	func didUpdateListings(_ currentListings: [Listing]) {
		print("Did update listings")
		let allAnnotations = self.mapView.annotations
		self.mapView.removeAnnotations(allAnnotations)
		
		for listing in currentListings {
			let annotation = MKPointAnnotation()
			
			if let amount = listing.amount {
				annotation.title = "$" + amount
				annotation.subtitle = listing.listingDescription
			}
			
			if let coordinate = listing.location?.coordinate {
				annotation.coordinate = coordinate
				mapView.addAnnotation(annotation)
			}
		}
		
		if let coordinate = currentListings.first?.location?.coordinate {
			setMapViewRegion(forLocation: coordinate)
		}
	}
}
