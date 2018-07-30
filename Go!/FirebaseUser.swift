//
//  FirebaseUser.swift
//  Go!
//
//  Created by Jordan Donato on 7/29/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FirebaseUser {
	
	var uid: String?
	var userName: String?
	var profilePhoto: UIImage?
	var photoURL: String?
	
	var followers: [String]?
	var following: [String]?
	
	fileprivate var ref : DatabaseReference?
	
	init(uid: String, completion: @escaping (FirebaseUser) -> Void) {
		self.uid = uid
		print("init user " + uid)
		ref = Database.database().reference()
		
		// **** WARNING: DELAYED INIT *******
		ref?.child(Keys.Users.rawValue).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
			print("begin init user " + uid)
			if let values = snapshot.value as? [String : Any] {
				self.userName = values[Keys.Username.rawValue] as? String
				self.photoURL = values[Keys.ProfileURL.rawValue] as? String
				self.followers = values[Keys.Followers.rawValue] as? [String]
				self.following = values[Keys.Following.rawValue] as? [String]
				
				let url = URL(string: (self.photoURL)!)
				let data = try? Data(contentsOf: url!)
				if let data = data {
					self.profilePhoto = UIImage(data: data)
				} else {
					self.profilePhoto = UIImage(named: "Profile")
				}
				print("done init user " + uid)
			}
			completion(self)
		})
	}
	
	deinit {
		ref?.child(Keys.Users.rawValue).child(uid!).removeAllObservers()
	}
}
