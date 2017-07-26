//
//  ProfileViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/25/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
        
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let user = FIRAuth.auth()?.currentUser
        userNameLabel.text = user?.displayName
        
        let url = user?.photoURL
        let data = try? Data(contentsOf: url!)
        profileImageView.image = UIImage(data: data!)
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
        profileImageView.clipsToBounds = true;
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

}
