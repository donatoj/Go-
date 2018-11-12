//
//  Review.swift
//  Go!
//
//  Created by Jordan Donato on 11/4/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import Foundation
import UIKit

class Review {
	var reviewer : String?
	var reviewerImage : UIImage?
	var reviewText : String?
	var rating : Double?
	
	init(reviewer : String, reviewText : String, rating : Double) {
		
		FirebaseUser(uid: reviewer) { (fbUser) in
			self.reviewer = fbUser.userName
			self.reviewText = reviewText
			self.rating = rating
			self.reviewerImage = fbUser.profilePhoto
		}
		
	}
}
