//
//  MenuItemManager.swift
//  Go!
//
//  Created by Jordan Donato on 7/20/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import Foundation
import UIKit

struct MenuItemManager {
	
	var Filter : [String]
	
	var FilterImages : [UIImage]
	
	var MenuItems = [MenuItem]()
	var FilterIndex : Int
	
	init() {
		Filter = [
			"Post",
			"Nearby",
			"Friends",
			//"Direct",
			"Requested",
			"My Listings",
			"To Do"
		]
		
		FilterImages = [
			UIImage(named: "Plus"),
			UIImage(named: "NearMe"),
			UIImage(named: "Group"),
			//UIImage(named: "DataTransfer"),
			UIImage(named: "Invite"),
			UIImage(named: "Sheets"),
			UIImage(named: "Running")
			] as! [UIImage]
		
		FilterIndex = 1
		
		setMenuItems()
	}
	
	mutating fileprivate func setMenuItems()  {
		for i in 0..<Filter.count {
			let menuItem = MenuItem(name: Filter[i], image: FilterImages[i])
			MenuItems.append(menuItem)
		}
	}
	
	mutating func setFilterIndex(index : Int) {
		self.FilterIndex = index
	}
}
