//
//  PostTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 7/26/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Firebase

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameButton: UIButton!
    @IBOutlet weak var timeAgo: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var requestButton: RequestButton!
    
    var requested : Bool = false
    var ref : DatabaseReference?
    
    @IBAction func OnRequestButtonPressed(_ sender: Any) {
        
        if requestButton.uid == Auth.auth().currentUser?.uid {
            
            // go to approval table view
        } else {
            if requested {
                requestButton.alpha = 1
                requestButton.setTitle("Request", for: UIControlState.normal)
                requested = false
            }
            else {
                requestButton.alpha = 0.5
                requestButton.setTitle("Requested", for: UIControlState.normal)
                requested = true
                
                let request : [String : Bool] = [(Auth.auth().currentUser?.uid)! : false]
                
                ref?.child("Requests").child(requestButton.key).updateChildValues(request)
            }
        }
        

    }
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
        ref = Database.database().reference()
        
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
