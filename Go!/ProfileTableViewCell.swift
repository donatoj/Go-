//
//  ProfileTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 9/16/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

	@IBOutlet weak var profileImageView: UIImageView!
	@IBOutlet weak var profileUserName: UILabel!
	@IBOutlet weak var bioLabel: UILabel!
	@IBOutlet weak var jobsLabel: UILabel!
	@IBOutlet weak var hiredLabel: UILabel!
	@IBOutlet weak var ratingLabel: UILabel!
	@IBOutlet weak var reviewsLabel: UILabel!
	
	@IBOutlet weak var followButton: UIButton!
	@IBAction func onFollowPressed(_ sender: Any) {
	}
	
	@IBOutlet weak var exitButton: UIButton!
	@IBAction func onExitPressed(_ sender: Any) {
	}
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
