//
//  ListingManager.swift
//  Go!
//
//  Created by Jordan Donato on 7/15/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Firebase
import GeoFire

// MARK: - Protocol methods
@objc protocol ListingManagerDelegate {
	@objc optional func didUpdateListings(_ currentListings: [Listing])
	@objc optional func updateListings()
	@objc optional func startLoading()
	@objc optional func stopLoading()
}

// MARK: - Singleton
class ListingManager : NSObject {
	
	static let sharedInstance = ListingManager()
	
	// MARK: - Delegates
	var homeViewDelegate : ListingManagerDelegate?
	var mapViewDelegate : ListingManagerDelegate?
	
	// MARK: - Firebase Refs
	fileprivate var ref : DatabaseReference?
	fileprivate var geoFireRef : DatabaseReference?
	fileprivate var geoFire : GeoFire?
	fileprivate var query : GFCircleQuery?
	fileprivate var geoQueryHandle : DatabaseHandle?
	
	// MARK: - Listings
	var worldListings = [String : Listing]()
	var followingistings = [String : Listing]()
	var selfListings = [String : Listing]()
	var requestListings = [String : Listing]()
	var activeListings = [String: Listing]()
	var currentListings = [Listing]()
	
	// MARK: - Limits
	var listingLimit = 5
	fileprivate let distanceLimit = 2000.0
	
	// MARK: - Location
	fileprivate let locationManager = CLLocationManager()
	var userLocation = CLLocation()
	
	// MARK: - Initialization
	override private init() {
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
	}
	
	// MARK: - Private Methods
	
	// Get a new listing
	fileprivate func getNewListing(forKey : String, withSnapshotValue: [String : Any], location : CLLocation) -> Listing? {
		
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
	
	fileprivate func setCurrentListings(_ withListings: [String : Listing]) {
		currentListings = Array(withListings.values).sorted(by: { (listing1, listing2) -> Bool in
			return listing1.timeAgoSinceDate() < listing2.timeAgoSinceDate()
		})
		self.mapViewDelegate?.didUpdateListings?(currentListings)
	}
	
	// MARK: - Public Methods
	
	func startUpdatingLocation() {
		locationManager.startUpdatingLocation()
	}
	
	func stopUpdatingLocation() {
		locationManager.stopUpdatingLocation()
	}
	
	func updateCurrentListings(withIndex : Int) {
		switch withIndex {
		case 1:
			setCurrentListings(worldListings)
			break
		case 2:
			setCurrentListings(followingistings)
			break
		case 3:
			let needDirectListings : String
			currentListings.removeAll()
			break
		case 4:
			setCurrentListings(requestListings)
			break
		case 5:
			setCurrentListings(selfListings)
			break
		case 6:
			setCurrentListings(activeListings)
			break
		default:
			break
		}
	}
	
	func updateListingLimit() {
		
		if worldListings.count >= listingLimit {
			listingLimit = worldListings.count + 5
			print("Will Display Cell last element index path row ")
			self.homeViewDelegate?.startLoading?()
		}
	}
	
	func updateRequests(forKey : String, updateChild : Bool) {
		
		var request = [String : Any]()
		
		request["/\(Keys.Listings.rawValue)/\(forKey)/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)"] = updateChild ? false : NSNull()
		request["/\(Keys.Requests.rawValue)/\((Auth.auth().currentUser?.uid)!)/\(forKey)"] = updateChild ? false : NSNull()
		
		ref?.updateChildValues(request, withCompletionBlock: { (error, ref) in
			self.worldListings[forKey]?.requested = updateChild
			self.followingistings[forKey]?.requested = updateChild
			self.requestListings[forKey]?.requested = updateChild
			self.homeViewDelegate?.updateListings?()
		})
	}
	
	func registerObservers()  {
		
		// get reference to database
		ref = Database.database().reference()
		
		geoFireRef = ref?.child(Keys.GeoLocations.rawValue)
		geoFire = GeoFire(firebaseRef: geoFireRef!)
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
		
		registerActiveAdded()
		registerActiveRemoved()
		
	}
	
	func removeAllObservers() {
		
		query?.removeAllObservers()
		
		ref?.child(Keys.UserPosts.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
		ref?.child(Keys.Listings.rawValue).removeAllObservers()
		ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
		ref?.child(Keys.Users.rawValue).child((Auth.auth().currentUser?.uid)!).child(Keys.Following.rawValue).removeAllObservers()
		ref?.child(Keys.Requests.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
	}
	
	
	// MARK: - FireBase Listeners
	fileprivate func registerGeoQueryKeyEntered() {
		
		geoQueryHandle = query?.observe(.keyEntered, with: { (key, location) in
			
			print("key entered " + key + " location " + (location.description))
			
			self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: key).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
				
				let listingKey = listingSnapshot.key
				if let listingItem = listingSnapshot.value as? [String : Any] {
					
					if listingItem[Keys.UserID.rawValue] as? String != Auth.auth().currentUser?.uid {
						let newListing = self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location)
						self.worldListings[listingKey] = newListing
						print("World listing updated")
						
					}
				}
			})
		})
	}
	
	fileprivate func registerGeoQueryKeyExit() {
		
		query?.observe(.keyExited, with: { (key, location) in
			
			print("key exited " + key)
			self.worldListings.removeValue(forKey: key)
		})
	}
	
	fileprivate func registerGeoQueryObserveReady() {
		var updated = false
		query?.observeReady({
			
			print("Query observe Ready")
			
			if self.worldListings.count < self.listingLimit {
				
				if (self.query?.radius.isLessThanOrEqualTo(self.distanceLimit))! {
					updated = false
					self.query?.radius += 5
					print("update radius " + (self.query?.radius.description)!)
				} else if !updated{
					self.homeViewDelegate?.stopLoading?()
					self.homeViewDelegate?.updateListings?()
					updated = true
					print("stoploading 1")
				}
				
			} else if !updated {
				self.homeViewDelegate?.stopLoading?()
				self.homeViewDelegate?.updateListings?()
				updated = true
				print("stop loading 2")
			}
		})
	}
	
	fileprivate func registerUserPostAdded() {
		
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
	
	fileprivate func registerUserPostRemoved() {
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
	
	fileprivate func registerFollowingPostAdded() {
		
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
	
	fileprivate func registerFollowingPostRemoved() {
		
		ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childRemoved, with: { (followerPostSnapshot) in
			print("Following post removed " + followerPostSnapshot.key)
			self.followingistings.removeValue(forKey: followerPostSnapshot.key)
		})
	}
	
	fileprivate func registerFollowingAdded() {
		
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
	
	fileprivate func registerFollowingRemoved() {
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
	
	fileprivate func registerRequestsAdded() {
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
	
	fileprivate func registerRequestsRemoved() {
		
		ref?.child(Keys.Requests.rawValue).child((Auth.auth().currentUser?.uid)!).observe(DataEventType.childRemoved, with: { (requestSnapshot) in
			print("request removed " + requestSnapshot.key)
			let listingKey = requestSnapshot.key
			self.requestListings.removeValue(forKey: listingKey)
		})
	}
	
	fileprivate func registerActiveAdded() {
		ref?.child(Keys.Active.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (snapshot) in
			
			let listingKey = snapshot.key
			print("listing key " + listingKey)
			
			self.geoFire?.getLocationForKey(listingKey, withCallback: { (location, error) in
				self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
					
					if let listingItem = listingSnapshot.value as? [String : Any] {
						let newListing = self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!)
						print("request added " + listingKey)
						self.activeListings[listingKey] = newListing
					}
					
				})
				
			})
			
		})
	}
	
	fileprivate func registerActiveRemoved() {
		ref?.child(Keys.Active.rawValue).child((Auth.auth().currentUser?.uid)!).observe(DataEventType.childRemoved, with: { (requestSnapshot) in
			print("request removed " + requestSnapshot.key)
			let listingKey = requestSnapshot.key
			self.activeListings.removeValue(forKey: listingKey)
		})
	}
}

// MARK: - Core Location extension
extension ListingManager : CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let location = locations[0]
		let userLocationCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
		userLocation = CLLocation(latitude: userLocationCoordinate.latitude, longitude: userLocationCoordinate.longitude)

		//print(userLocation)
		query?.center = userLocation
	}
}
