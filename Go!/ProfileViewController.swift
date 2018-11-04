//
//  ProfileViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/25/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import FirebaseDatabase

class ProfileViewController: UIViewController, UITableViewDelegate {
	
	// MARK: - Outlets
	@IBOutlet weak var profileTableView: UITableView!
	
	// MARK: - Members
    var user : FirebaseUser?
    var uid: String = ""
	var followButton : UIButton?
	
	// MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		profileTableView.rowHeight = UITableView.automaticDimension
		profileTableView.estimatedRowHeight = 100
		
        setUserData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        print("ProfileViewController Deinitialized")
    }
	
	// MARK: - Private Methods
	fileprivate func updateFollowButton(_ following : Bool) {
		
		if following {
			
			followButton?.setTitle("Following", for: UIControl.State.normal)
			followButton?.setTitleColor(UIColor.white, for: UIControl.State.normal)
			followButton?.backgroundColor = UIColor.green
			
		} else {
			
			followButton?.setTitle("Follow", for: UIControl.State.normal)
			followButton?.setTitleColor(UIColor.green, for: UIControl.State.normal)
			followButton?.backgroundColor = UIColor.white
			
		}
	}
	
	fileprivate func setUserData() {
		if uid == "" {
			uid = (ListingManager.sharedInstance.currentUser?.uid)!
		}
		
		if uid != ListingManager.sharedInstance.currentUser?.uid
		{
			ListingManager.sharedInstance.getFollowingStatus(uid: uid) { (following) in
				self.updateFollowButton(following)
			}
		}
		
		FirebaseUser(uid: uid, completion: { (firebaseUser) in
			self.user = firebaseUser
			self.profileTableView.reloadData()
		})
		
	}
	
	// MARK: - Actions
	@objc func onExitPressed(_ sender: Any) {
		presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
	@objc func onFollowButtonPressed(_ sender: Any) {
		ListingManager.sharedInstance.getFollowingStatus(uid: (self.user?.uid)!) { (following) in
			ListingManager.sharedInstance.followUser(following: following, uid: (self.user?.uid)!)
			self.updateFollowButton(!following)
		}
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

// MARK: - Table View extensions
extension ProfileViewController : UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		if indexPath.row == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! ProfileTableViewCell
			
			cell.profileImageView.image = self.user?.profilePhoto
			cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
			cell.profileImageView.clipsToBounds = true;
			
			cell.profileUserName.text = self.user?.userName
			
			self.followButton = cell.followButton
			if self.user?.uid == ListingManager.sharedInstance.currentUser?.uid {
				showFBLoginButton(atCell: cell)
				cell.followButton.isHidden = true
				
			} else {
				cell.followButton.isHidden = false
			}
			cell.followButton.addTarget(self, action: #selector(onFollowButtonPressed(_:)), for: .touchUpInside)
			cell.exitButton.addTarget(self, action: #selector(onExitPressed(_:)), for: .touchUpInside)
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "reviewCell", for: indexPath) as! ReviewTableViewCell
			
			// FIXME: fill in reviews
			
			return cell
		}
	}
}

// MARK: - Facebook login extension
extension ProfileViewController : FBSDKLoginButtonDelegate {
    
	func showFBLoginButton(atCell : ProfileTableViewCell) {
        let loginButton = FBSDKLoginButton()
        loginButton.center = atCell.followButton.center
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.delegate = self
        atCell.addSubview(loginButton)
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
        print("user did log out of facebook")
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print("login error \(error.localizedDescription)")
        } else {
            print("login successful")
            
            // handle permissions or cancelled
            
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
			
			Auth.auth().signInAndRetrieveData(with: credential) { (authDataResult, error) in
				if error != nil {
					if let error = error {
						print("firebase credential error \(error.localizedDescription)  ")
					}
				} else {
					
					print("user name \(String(describing: authDataResult?.user.displayName))")
					print("user email \(String(describing: authDataResult?.user.email))")
					
					self.presentingViewController?.dismiss(animated: true, completion: nil)
				}
			}
        }
    }
}
