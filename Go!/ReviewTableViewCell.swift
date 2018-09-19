//
//  ReviewTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 9/16/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import UIKit

class ReviewTableViewCell: UITableViewCell {

	@IBOutlet weak var reviewerImageView: UIImageView!
	@IBOutlet weak var reviewerUserName: UILabel!
	@IBOutlet weak var reviewerRating: UILabel!
	@IBOutlet weak var reviewLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
