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

class ProfileViewController: UIViewController, FBSDKLoginButtonDelegate {
        
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let user = FIRAuth.auth()?.currentUser
        userNameLabel.text = user?.displayName
        
        let url = user?.providerData[0].photoURL
        let data = try? Data(contentsOf: url!)
        profileImageView.image = UIImage(data: data!)
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
        profileImageView.clipsToBounds = true;
        
        showFBLoginButton()
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
