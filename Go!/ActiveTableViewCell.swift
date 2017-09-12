//
//  ActiveTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 9/7/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit

class ActiveTableViewCell: UITableViewCell {

    
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onProfileButtonPressed(_ sender: Any) {
    }
}
