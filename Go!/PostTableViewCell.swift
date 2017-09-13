//
//  PostTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 7/26/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameButton: UIButton!
    @IBOutlet weak var timeAgo: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var requestButton: UIButton!

    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
