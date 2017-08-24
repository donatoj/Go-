//
//  RequestTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 8/24/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit

class RequestTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameButton: UserNameButton!
    @IBOutlet weak var approveButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onApprovePressed(_ sender: Any) {
        
    }
}
