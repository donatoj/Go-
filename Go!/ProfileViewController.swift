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
    
    var ref : FIRDatabaseReference?
    var databaseHandle : FIRDatabaseHandle?
    
    var uid: String = ""
    
    var following : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUserData()
    }
    
    @IBAction func onFollowButtonPressed(_ sender: Any) {
        
        let user = FIRAuth.auth()?.currentUser
        
        if !following {
            
            following = true
            
            var followDict = [String : Bool]()
            followDict[uid] = true
            
            self.ref?.child("Friends").child((user?.uid)!).updateChildValues(followDict)
        } else {
            
            following = false
            
            self.ref?.child("Friends").child((user?.uid)!).child(uid).removeValue()
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
        if uid == "" || uid == FIRAuth.auth()?.currentUser?.uid{
            print("UID is self")
            
            let user = FIRAuth.auth()?.currentUser
            userNameLabel.text = user?.displayName
            
            let url = (user?.providerData[0].photoURL)!
            setUserProfilePhoto(url: url)
            
            // allow logout
            showFBLoginButton()
            followButton.isHidden = true
            
        } else {
            print("UID is other")
            // get reference to database
            ref = FIRDatabase.database().reference()
            
            ref?.child("Users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let value = snapshot.value as? [String : AnyObject]
                
                self.userNameLabel.text = value?["Username"] as? String
                
                if let urlString = value?["ProfileURL"] as? String {
                    if let url = URL(string: urlString) {
                        self.setUserProfilePhoto(url: url)
                        self.followButton.isHidden = false
                    }
                }
                
            })
            
            ref?.child("Friends").child((FIRAuth.auth()?.currentUser?.uid)!).child(uid).observeSingleEvent(of: .value, with: { (friendSnapshot) in
                
                print("Friends set data update ")
                print(friendSnapshot.value.unsafelyUnwrapped)
                if friendSnapshot.value is NSNull {
                    print("following")
                    self.following = false
                } else {
                    print("not following")
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
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            
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
            
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential, completion: { (user : FIRUser?, error :Error?) in
                
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
