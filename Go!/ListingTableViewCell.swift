//
//  PostTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 7/26/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit

class ListingTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameButton: UIButton!
    @IBOutlet weak var timeAgo: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var requestButton: UIButton!
	
	var listing : Listing?

    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
//    override var frame: CGRect {
//        get {
//            return super.frame
//        }
//        set (newFrame) {
//            var frame = newFrame
//            frame.origin.x += 10
//            frame.size.width -= 20
//            super.frame = frame
//        }
//    }

}
