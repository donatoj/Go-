//
//  ReviewViewController.swift
//  Go!
//
//  Created by Jordan Donato on 8/26/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import UIKit
import Firebase

class ReviewViewController: UIViewController {

	// MARK: - Outlets
	@IBOutlet weak var userImageView: UIImageView!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var reviewTextView: UITextView!
	@IBOutlet weak var reviewSlider: UISlider!
	
	// MARK: - Actions
	@IBAction func onReviewSliderValueChanged(_ sender: Any) {
		
	}
	@IBAction func onSubmitPressed(_ sender: Any) {
		
		if let user = otherUser {
			ListingManager.sharedInstance.leaveReview(forUser: user, review: reviewTextView.text, rating: reviewSlider.value)
		}
		if let listing = listing {
			ListingManager.sharedInstance.addToHistory(forListing: listing)
		}

		dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Members
	var listing : Listing?
	var otherUser : String?
	
	// MARK: - ViewController LifeCycle
	override func viewDidLoad() {
        super.viewDidLoad()
		
		//Looks for single or multiple taps.
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
		
		//Uncomment the line below if you want the tap not not interfere and cancel other interactions.
		//tap.cancelsTouchesInView = false
		
		view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
		
		reviewTextView.layer.borderWidth = 1
		
		reviewSlider.minimumValueImage = "😔".emojiToImage()
		reviewSlider.maximumValueImage = "😍".emojiToImage()
		
		setUser()
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
	
	// MARK: - Private Methods
	fileprivate func setUser() {
		
		if listing?.user?.uid != Auth.auth().currentUser?.uid {
			otherUser = listing?.user?.uid
		} else {
			otherUser = listing?.approvedUser
		}
		
		FirebaseUser(uid: otherUser!, completion: { (firebaseUser) in
			self.userImageView.image = firebaseUser.profilePhoto
			self.userImageView.layer.cornerRadius = self.userImageView.frame.size.width / 2;
			self.userImageView.clipsToBounds = true;
			self.usernameLabel.text = firebaseUser.userName
		})
	}
	
	//Calls this function when the tap is recognized.
	@objc fileprivate func dismissKeyboard(_ sender: Any) {
		//Causes the view (or one of its embedded text fields) to resign the first responder status.
		view.endEditing(true)
	}
}
