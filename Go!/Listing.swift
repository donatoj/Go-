//
//  Listing.swift
//  Go!
//
//  Created by Jordan Donato on 8/5/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class Listing : NSObject {
    // MARK: - Members
	var user: FirebaseUser?
	var key: String?
	var listingDescription: String?
	var amount: String?
    var datePosted: String?
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    var requested: Bool?
	var active: Bool?
	var approvedUser: String?
	var location: CLLocation?
    
	// MARK: - Initialization
    
	init(uid: String, description: String, amount: String, datePosted: String, latitude: CLLocationDegrees?, longitude: CLLocationDegrees?, key: String, requested: Bool, active: Bool, approvedUser: String?, completion: @escaping (Listing) -> Void) {
		super.init()
		
		self.listingDescription = description
		self.amount = amount
		self.datePosted = datePosted
		self.latitude = latitude
		self.longitude = longitude
		self.key = key
		self.requested = requested
		self.active = active
		self.approvedUser = approvedUser
		
		if let latitude = latitude, let longitude = longitude {
			self.location = CLLocation(latitude: latitude, longitude: longitude)
		}
		
		self.user = FirebaseUser(uid: uid, completion: { (firebaseUser) in
			completion(self)
		})
    }
	
	// MARK: - Methods
    
    func distance(to location: CLLocation) -> CLLocationDistance {
        return location.distance(from: location)
    }
    
    func getDistanceFromListing(userLocation : CLLocation) -> String {
		guard let latitude = self.latitude, let longitude = self.longitude else {return ""}
		
        let listingCoordinates = CLLocation(latitude: latitude, longitude: longitude)
        let distanceInMeters = listingCoordinates.distance(from: userLocation)
        let distanceInMiles = distanceInMeters/1609.344
        let truncatedDistance = Double(round(100 * distanceInMiles)/100)
        
        return truncatedDistance.description + " mi away"
        
    }
    
    func timeAgoSinceDate() -> Int? {
		guard let datePosted = self.datePosted else {return nil}
		
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        let date = dateFormatter.date(from: datePosted)
        let earliest = now < date! ? now : date
        let latest = (earliest == now) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest!,  to: latest!)
        
        return components.second
    }

    func timeAgoSinceDate(_ numericDates:Bool = false) -> String {
		guard let datePosted = self.datePosted else {return ""}
		
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        let date = dateFormatter.date(from: datePosted)
        let earliest = now < date! ? now : date
        let latest = (earliest == now) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest!,  to: latest!)
        
        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!) hours ago"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!) minutes ago"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!) seconds ago"
        } else {
            return "Just now"
        }
        
    }
}
