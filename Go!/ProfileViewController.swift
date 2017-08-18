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

class ProfileViewController: UIViewController, FBSDKLoginButtonDelegate {
        
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    var ref : DatabaseReference?
    var databaseHandle : DatabaseHandle?
    
    var uid: String = ""
    
    var following : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUserData()
    }
    
    @IBAction func onFollowButtonPressed(_ sender: Any) {
        
        let user = Auth.auth().currentUser
        
        let implementApprovalProcessFollwingMechanicsm : String
        
        if !following {
            
            following = true

            self.ref?.child("Following").child((user?.uid)!).updateChildValues([uid : true])
            self.ref?.child("Followers").child(uid).updateChildValues([(user?.uid)! : true])
        } else {
            
            following = false
            
            self.ref?.child("Following").child((user?.uid)!).child(uid).removeValue()
            self.ref?.child("Followers").child(uid).child((user?.uid)!).removeValue()
        }
        
        updateFollowButton()
    }
    
    func updateFollowButton() {
       
        if following {
            
            followButton.setTitle("Following", for: UIControlState.normal)
            followButton.setTitleColor(UIColor.white, for: UIControlState.normal)
            followButton.backgroundColor = UIColor.green
            
        } else {
            
            followButton.setTitle("Follow", for: UIControlState.normal)
            followButton.setTitleColor(UIColor.green, for: UIControlState.normal)
            followButton.backgroundColor = UIColor.white
            
        }
        
    }

    func setUserData() {
        // not from UI button
        if uid == "" || uid == Auth.auth().currentUser?.uid{
            print("UID is self")
            
            let user = Auth.auth().currentUser
            userNameLabel.text = user?.displayName
            
            let url = (user?.providerData[0].photoURL)!
            setUserProfilePhoto(url: url)
            
            // allow logout
            showFBLoginButton()
            followButton.isHidden = true
            
        } else {
            print("UID is other")
            // get reference to database
            ref = Database.database().reference()
            
            ref?.child(Keys.Users.rawValue).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let value = snapshot.value as? [String : AnyObject]
                
                self.userNameLabel.text = value?[Keys.Username.rawValue] as? String
                
                if let urlString = value?[Keys.ProfileURL.rawValue] as? String {
                    if let url = URL(string: urlString) {
                        self.setUserProfilePhoto(url: url)
                        self.followButton.isHidden = false
                    }
                }
                
            })
            
            ref?.child(Keys.Following.rawValue).child((Auth.auth().currentUser?.uid)!).queryOrderedByKey().queryEqual(toValue: uid).observeSingleEvent(of: .childAdded, with: { (followingSnapshot) in
                
                print("Friends set data update ")
                print(followingSnapshot.value.unsafelyUnwrapped)
                if followingSnapshot.value is NSNull {
                    print("not following")
                    self.following = false
                } else {
                    print("following")
                    self.following = true
                }
                self.updateFollowButton()
            })
        }
    }
    
    func setUserProfilePhoto(url : URL) {
        if let data = try? Data(contentsOf: url) {
            profileImageView.image = UIImage(data: data)
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
            profileImageView.clipsToBounds = true;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showFBLoginButton() {
        let loginButton = FBSDKLoginButton()
        loginButton.center = self.view.center
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.delegate = self
        self.view.addSubview(loginButton)
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
            Auth.auth().signIn(with: credential, completion: { (user : User?, error :Error?) in
                
                if error != nil {
                    if let error = error {
                        print("firebase credential error \(error.localizedDescription)  ")
                    }
                } else {
                    
                    print("user name \(String(describing: user!.displayName))")
                    print("user email \(String(describing: user!.email))")
                    
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
    
    deinit {
        print("ProfileViewController Deinitialized")
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
