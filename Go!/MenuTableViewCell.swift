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
	
	func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>
		(dataSourceDelegate: D, forRow row: Int) {
		collectionView.delegate = dataSourceDelegate
		collectionView.dataSource = dataSourceDelegate
		collectionView.tag = row
		collectionView.reloadData()
		print("collectionview delegate set for row " + row.description)
	}
}


