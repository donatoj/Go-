//
//  MenuTableViewCell.swift
//  Go!
//
//  Created by Jordan Donato on 7/17/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

	@IBOutlet weak var collectionView: UICollectionView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		print("menu table view cell awake ***")
		//collectionView.register(MenuCollectionViewCell.self, forCellWithReuseIdentifier: "MenuCollectionViewCell")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}


