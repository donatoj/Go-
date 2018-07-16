//
//  ViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/9/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import FirebaseDatabase

class LoginViewController: UIViewController {
	
	// MARK: - Members
    var ref: DatabaseReference!
	
	// MARK: - ViewController LifeCycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ref = Database.database().reference()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

        if (FBSDKAccessToken.current() != nil && Auth.auth().currentUser != nil) {
            // User is logged in, do work such as go to next view controller.
            
            print("user already signed in fb")
            performSegue(withIdentifier: "showMain", sender: self)
        } else {
            print("access token is nil")
            showFBLoginButton()
        }
        
    }
    
    deinit {
        print("LoginViewController Deinitialized")
    }
    
}
// MARK: - Facebook Extension
extension LoginViewController : FBSDKLoginButtonDelegate {
    
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
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print("login error \(error.localizedDescription)")
        } else {
            print("login successful")
            
            let handlePermissionsOrCancelled : String
            
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            
            Auth.auth().signIn(with: credential, completion: { (user : User?, error :Error?) in
                
                if error != nil {
                    if let error = error {
                        print("firebase credential error \(error.localizedDescription)  ")
                        
                    }
                } else {
                    
                    print("user name \(String(describing: user!.displayName))")
                    print("user email \(String(describing: user!.email))")
                    
                    var userDict = [String : String]()
                    userDict["Username"] = user?.displayName
                    userDict["ProfileURL"] = user?.providerData[0].photoURL?.absoluteString
                    
                    self.ref?.child("Users").child((user?.uid)!).updateChildValues(userDict)
                    
                    self.performSegue(withIdentifier: "showMain", sender: self)
                }
            })
        }
    }
    
}

