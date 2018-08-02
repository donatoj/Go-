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
	@objc optional func didUpdateRequests()
}

// MARK: - Singleton
class ListingManager : NSObject {
	
	static let sharedInstance = ListingManager()
	
	// MARK: - Delegates
	var homeViewDelegate : ListingManagerDelegate?
	var mapViewDelegate : ListingManagerDelegate?
	var listingDetailDelegate : ListingManagerDelegate?
	
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
	
	// MARK: - Requests
	var requestingUsers = [String]()
	var requestingUserPhotos = [UIImage]()
	var requestingUserIDs = [String]()
	
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
	fileprivate func getNewListing(forKey : String, withSnapshotValue: [String : Any], location : CLLocation?, completion: @escaping (Listing) -> Void)
		{
		
		let requests = withSnapshotValue["Requests"] as? [String: Bool]
		let requested = requests?[(Auth.auth().currentUser?.uid)!] != nil
		
		Listing(uid: withSnapshotValue[Keys.UserID.rawValue]! as! String,
							 description: withSnapshotValue[Keys.Description.rawValue]! as! String,
							 amount: withSnapshotValue[Keys.Amount.rawValue]! as! String,
							 datePosted: withSnapshotValue[Keys.DatePosted.rawValue]! as! String,
							 latitude: location?.coordinate.latitude,
							 longitude: location?.coordinate.longitude,
							 key: forKey,
							 requested: requested,
							 active: withSnapshotValue[Keys.Active.rawValue] as! Bool,
							 approvedUser: withSnapshotValue[Keys.Approved.rawValue] as! String?,
							 completion: { (listing) in
							
								completion(listing)
							}
		)
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
			setCurrentListings(requestListings)
			break
		case 4:
			setCurrentListings(selfListings)
			break
		case 5:
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
	
	func registerRequestsObserver(forKey : String) {
		
		ref?.child(Keys.Listings.rawValue).child(forKey).child(Keys.Requests.rawValue).observe(.childAdded, with: { (snapshot) in
			
			let userID = snapshot.key
			print("requesting user " + userID)
			
			self.ref?.child(Keys.Users.rawValue).child(userID).observeSingleEvent(of: .value, with: { (usersSnapshot) in
				print(usersSnapshot)
				if let values = usersSnapshot.value as? [String : Any] {
					print("update table data with snapshot value " + values.debugDescription)
					let username = values[Keys.Username.rawValue]!
					self.requestingUsers.append(username as! String)
					self.requestingUserIDs.append(userID)
					
					let profileURL = values[Keys.ProfileURL.rawValue]!
					let url = URL(string: profileURL as! String)
					let data = try? Data(contentsOf: url!)
					if let data = data {
						self.requestingUserPhotos.append(UIImage(data: data)!)
					} else {
						self.requestingUserPhotos.append(UIImage(named: "Profile")!)
					}
					
					self.listingDetailDelegate?.didUpdateRequests?()
				}
			})
		})
	}
	
	func removeRequestsObserver(forKey : String) {
		ref?.child(Keys.Requests.rawValue).child(forKey).removeAllObservers()
		self.requestingUsers.removeAll()
		self.requestingUserPhotos.removeAll()
		self.requestingUserIDs.removeAll()
	}
	
	func updateApproved(listing : Listing, forUserId : String) {
		print("approve button " + forUserId + " pressed")
		self.selfListings[listing.key!]?.active = true
		self.selfListings[listing.key!]?.approvedUser = forUserId
		
		var childUpdates = [String : Any]()
		if let key = listing.key {
			childUpdates["/\(Keys.Active.rawValue)/\(forUserId)/\(key)"] = false
			childUpdates["/\(Keys.Listings.rawValue)/\(key)/\(Keys.Active.rawValue)"] = true
			childUpdates["/\(Keys.Listings.rawValue)/\(key)/\(Keys.Approved.rawValue)"] = forUserId
			
			// remove from geolocation, requests, and following
			childUpdates["/\(Keys.GeoLocations.rawValue)/\(key)"] = NSNull()
			
			self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: key).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
				var listingItem = listingSnapshot.value as! [String : Any?]
				let requests = listingItem[Keys.Requests.rawValue] as! [String : Any?]
				let followers = listingItem[Keys.Followers.rawValue] as! [String : Any?]
				
				for request in requests {
					childUpdates["/\(Keys.Requests.rawValue)/\(request.key)/\(key)"] = NSNull()
				}
				
				for follower in followers {
					childUpdates["/\(Keys.FollowingPosts.rawValue)/\(follower.key)/\(key)"] = NSNull()
				}
				
				self.ref?.updateChildValues(childUpdates)
			})
		}
	}
	
	func removeListing(forKey: String) {
		ref?.child(Keys.Listings.rawValue).child(forKey).removeValue()
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
					
					if listingItem[Keys.UserID.rawValue] as? String != Auth.auth().currentUser?.uid	{
							self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location, completion: { (listing) in
								
								self.worldListings[listingKey] = listing
								print("World listing updated")
							})
					}
				}
			})
		})
	}
	
	fileprivate func registerGeoQueryKeyExit() {
		
		query?.observe(.keyExited, with: { (key, location) in
			
			print("key exited " + key)
			self.worldListings.removeValue(forKey: key)
			self.homeViewDelegate?.updateListings?()
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
						self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location, completion: { (listing) in
							
							self.selfListings[listingKey] = listing
							self.homeViewDelegate?.updateListings?()
							print("Self listing updated")
						})
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
			
			// Remove from Geolocations
			childUpdates["/\(Keys.GeoLocations.rawValue)/\(listingSnapshot.key)"] = NSNull()
			
			if let listingValue = listingSnapshot.value as? [String : Any] {
				
				// Remove from User Posts
				childUpdates["/\(Keys.UserPosts.rawValue)/\(listingValue[Keys.UserID.rawValue]! as! String)/\(listingSnapshot.key)"] = NSNull()
				self.selfListings.removeValue(forKey: listingSnapshot.key)
				
				// Remove from Requests
				if let requests = listingValue[Keys.Requests.rawValue] as? [String : Any]
				{
					for id in requests.keys {
						childUpdates["/\(Keys.Requests.rawValue)/\(id)/\(listingSnapshot.key)"] = NSNull()
					}
				}
				
				// Remove from Active
				
				// Remove from followers
				self.ref?.child(Keys.Users.rawValue).child(listingValue[Keys.UserID.rawValue]! as! String).child(Keys.Followers.rawValue).observeSingleEvent(of: .value, with: { (followerSnapshot) in
					if let followers = followerSnapshot.value as? [String : Bool] {
						for followerKey in followers.keys {
							print("found follower post to remove from " + followerKey)
							childUpdates["/\(Keys.FollowingPosts.rawValue)/\(followerKey)/\(listingSnapshot.key)"] = NSNull()
						}
					}
					self.ref?.updateChildValues(childUpdates)
					self.homeViewDelegate?.updateListings?()
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
						if listingItem[Keys.Active.rawValue] as! Bool == false {
							self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!, completion: { (listing) in
								
								self.followingistings[listingKey] = listing
								self.homeViewDelegate?.updateListings?()
								
								// add follower to listing
								var follower = [String : Any]()
								follower["/\(Keys.Listings.rawValue)/\(listingKey)/\(Keys.Followers.rawValue)/\((Auth.auth().currentUser?.uid)!)"] = true
								self.ref?.updateChildValues(follower)
							})
						} else {
							self.ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).child(listingKey).removeValue()
						}
					}
				})
			})
		})
	}
	
	fileprivate func registerFollowingPostRemoved() {
		
		ref?.child(Keys.FollowingPosts.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childRemoved, with: { (followerPostSnapshot) in
			print("Following post removed " + followerPostSnapshot.key)
			self.followingistings.removeValue(forKey: followerPostSnapshot.key)
			self.homeViewDelegate?.updateListings?()
			
			// remove follower to listing
			var follower = [String : Any]()
			follower["/\(Keys.Listings.rawValue)/\(followerPostSnapshot.key)/\(Keys.Followers.rawValue)/\((Auth.auth().currentUser?.uid)!)"] = NSNull()
			self.ref?.updateChildValues(follower)
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
						self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: location!, completion: {(listing) in
							print("request added " + listingKey)
							self.requestListings[listingKey] = listing
							self.homeViewDelegate?.updateListings?()
						})
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
			self.homeViewDelegate?.updateListings?()
		})
	}
	
	fileprivate func registerActiveAdded() {
		ref?.child(Keys.Active.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (snapshot) in
			
			let listingKey = snapshot.key
			print("listing key " + listingKey)
			
			self.ref?.child(Keys.Listings.rawValue).queryOrderedByKey().queryEqual(toValue: listingKey).observeSingleEvent(of: .childAdded, with: { (listingSnapshot) in
				
				if let listingItem = listingSnapshot.value as? [String : Any] {
					self.getNewListing(forKey: listingKey, withSnapshotValue: listingItem, location: nil, completion: { (listing) in
						print("active added " + listingKey)
						self.activeListings[listingKey] = listing
						self.homeViewDelegate?.updateListings?()
					})
				}
			})
		})
	}
	
	fileprivate func registerActiveRemoved() {
		ref?.child(Keys.Active.rawValue).child((Auth.auth().currentUser?.uid)!).observe(DataEventType.childRemoved, with: { (requestSnapshot) in
			print("active removed " + requestSnapshot.key)
			let listingKey = requestSnapshot.key
			self.activeListings.removeValue(forKey: listingKey)
			self.homeViewDelegate?.updateListings?()
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
