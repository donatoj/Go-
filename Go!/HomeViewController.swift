//
//  HomeViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/17/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
	
	// MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var gripperView: UIView!
	@IBOutlet weak var heightConstraint: NSLayoutConstraint!
	@IBOutlet weak var bottomCollectionViewSeparator: UIView!
	@IBOutlet weak var searchContainer: UIView!
	
	// MARK: - Members
	var listingManager = ListingManager.sharedInstance
	var menuItemsManager = MenuItemManager()
	var currentUserId : String?
	var searchController : UISearchController!
	
	fileprivate var drawerBottomSafeArea: CGFloat = 0.0 {
		didSet {
			self.loadViewIfNeeded()
			
			// We'll configure our UI to respect the safe area. In our small demo app, we just want to adjust the contentInset for the tableview.
			tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: drawerBottomSafeArea, right: 0.0)
		}
	}
	
	// MARK: - ViewController LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Home View did load")
        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
		
		gripperView.layer.cornerRadius = 2.5
		
		listingManager.homeViewDelegate = self
        listingManager.registerObservers()
		
        showSearchBar()
		
		currentUserId = Auth.auth().currentUser?.uid
	
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("Home View Did Appear")
        
        listingManager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("Home View Did disappear")
        //listingManager.removeAllObservers()
        listingManager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("***********MEMORY WARNING*************")
    }
	
	deinit {
		print("HomeViewController Deinitialized")
	}
	
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		
		if let button = sender as? UIButton {
			let listingItem = listingManager.currentListings[button.tag]
			if (button.accessibilityIdentifier?.contains("requestButton"))! {
				print("sender is request button")
				if let key = listingItem.key {
					let nextScene = segue.destination as! RequestsTableViewController
					nextScene.key = key
				}
			} else if (button.accessibilityIdentifier?.contains("usernameButton"))!{
				print("sender is ui button")
				let nextScene = segue.destination as! ProfileViewController
				if let user = listingItem.user {
					if let uid = user.uid {
						nextScene.uid = uid
					}
				}
			}
		}
		
		if segue.destination is ListingDetailTableViewController {
			let vc = segue.destination as? ListingDetailTableViewController
			let cell = sender as! ListingTableViewCell
			vc?.listing = cell.listing
		}
	}
	
	// MARK: - Private functions
	
	fileprivate func showSearchBar() {
		searchController = UISearchController(searchResultsController:  nil)
		searchController.searchResultsUpdater = self
		searchController.delegate = self
		searchController.searchBar.delegate = self
		searchController.dimsBackgroundDuringPresentation = true
		searchController.searchBar.searchBarStyle = UISearchBarStyle.minimal
		searchContainer.addSubview(searchController.searchBar)
		
		definesPresentationContext = true
	}
    
    @objc func onRequestPressed(_ sender: UIButton) {
        let listingItem = listingManager.currentListings[sender.tag]
		
		if listingItem.user?.uid != currentUserId {
			if let key = listingItem.key, let requested = listingItem.requested {
				listingManager.updateRequests(forKey: key, updateChild: !requested)
			}
		}
    }
	
	@objc func menuPressed(_ sender: UIButton) {
		print("menu button pressed " + sender.tag.description)
		if sender.tag != 0 {
			menuItemsManager.setFilterIndex(index: sender.tag)
			updateListings()
		} else { // Post button
			definesPresentationContext = true
			let vc = (storyboard?.instantiateViewController(withIdentifier: "Post"))!
			vc.modalTransitionStyle = .coverVertical
			vc.modalPresentationStyle = .overCurrentContext
			present(vc, animated: false, completion: nil)
			pulleyViewController?.setDrawerPosition(position: .open, animated: true)
		}
		collectionView.reloadData()
	}
	// MARK: - Contextual actions
	func contextualDeleteAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
		let listing = listingManager.currentListings[indexPath.row]
		let action = UIContextualAction(style: .destructive,
										title: "Delete") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
											if let key = listing.key {
												self.listingManager.removeListing(forKey: key)
												completionHandler(true)
											} else {
												completionHandler(false)
											}
		}
		action.backgroundColor = UIColor.red
		return action
	}
	
	func contextualEditAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
		let listing = listingManager.currentListings[indexPath.row]
		let action = UIContextualAction(style: .normal,
										title: "Edit") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
											
											
											// Fill in
											
											completionHandler(true)
		}
		action.backgroundColor = UIColor.blue
		return action
	}

	
	func contextualRequestAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
		let listing = listingManager.currentListings[indexPath.row]
		let title = listing.requested! ? "Cancel Request" : "Request"
		let action = UIContextualAction(style: .normal,
										title: title) { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
											
											if listing.user?.uid != self.currentUserId {
												if let key = listing.key, let requested = listing.requested {
													self.listingManager.updateRequests(forKey: key, updateChild: !requested)
													completionHandler(true)
												} else {
													completionHandler(false)
												}
											} else {
												completionHandler(false)
											}
		}
		
		if let requested = listing.requested {
			action.backgroundColor = requested ? UIColor.red : UIColor.seafoam
		}
		
		return action
	}
	
	func contextualCompleteAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
		let listing = listingManager.currentListings[indexPath.row]
		let action = UIContextualAction(style: .destructive,
										title: "Complete") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
											
											
											// Fill in
											
											completionHandler(true)
		}
		action.backgroundColor = UIColor.seafoam
		return action
	}
	
	func contextualCancelAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
		let listing = listingManager.currentListings[indexPath.row]
		let action = UIContextualAction(style: .destructive,
										title: "Cancel") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
											
											// Fill in
											
											
											completionHandler(true)
		}
		action.backgroundColor = UIColor.red
		return action
	}
}
// MARK: - CollectionView extensions
extension HomeViewController: UICollectionViewDelegate {

}

extension HomeViewController: UICollectionViewDataSource {

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return menuItemsManager.MenuItems.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCollectionViewCell", for: indexPath) as! MenuCollectionViewCell
		
		cell.label.text = menuItemsManager.MenuItems[indexPath.row].name
		cell.button.layer.borderColor = UIColor.seafoam.cgColor
		cell.button.layer.borderWidth = 3
		cell.button.layer.cornerRadius = cell.button.frame.size.width / 2;
		cell.button.clipsToBounds = true
		cell.button.tag = indexPath.row
		cell.button.addTarget(self, action: #selector(menuPressed(_:)), for: UIControlEvents.touchUpInside)
		
		let origImage = menuItemsManager.FilterImages[indexPath.row]
		let tintedImage = origImage.withRenderingMode(.alwaysTemplate)
		if indexPath.row == menuItemsManager.FilterIndex {
			cell.button.setImage(tintedImage, for: UIControlState.normal)
			cell.button.tintColor = UIColor.white
			cell.button.backgroundColor = UIColor.seafoam
		} else {
			cell.button.setImage(tintedImage, for: UIControlState.normal)
			cell.button.tintColor = UIColor.seafoam
			cell.button.backgroundColor = UIColor.white
		}

		return cell
	}
}

// MARK: - TableView extensions

extension HomeViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return listingManager.currentListings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "ListingTableViewCell", for: indexPath) as! ListingTableViewCell
		
        let listingItem = listingManager.currentListings[indexPath.row]
        cell.listing = listingItem
        // check for only items not from user
		cell.userNameButton.setTitle(listingItem.user?.userName, for: UIControlState.normal)
        cell.userNameButton.tag = indexPath.row
        
        cell.descriptionLabel.text = listingItem.listingDescription
        
		cell.profileImageView.image = listingItem.user?.profilePhoto
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = true;
        
        cell.timeAgo.text = listingItem.timeAgoSinceDate(true)
		cell.distance.text = listingItem.user?.uid != currentUserId ? listingItem.getDistanceFromListing(userLocation: listingManager.userLocation) : ""
		
		if let amount = listingItem.amount {
			cell.requestButton.setTitle("$" + amount, for: UIControlState.normal)
			cell.requestButton.layer.borderWidth = 1
			cell.requestButton.layer.cornerRadius = 8
			cell.requestButton.clipsToBounds = true
			cell.requestButton.tag = indexPath.row
			cell.requestButton.addTarget(self, action: #selector(onRequestPressed(_:)), for: .touchUpInside)
		}
		
		if listingItem.user?.uid == currentUserId {
			cell.requestButton.backgroundColor = UIColor.blue
			cell.requestButton.layer.borderColor = UIColor.white.cgColor
			cell.requestButton.setTitleColor(UIColor.white, for: .normal)
			cell.requestButton.isEnabled = false
		} else {
			if let requested = listingItem.requested {
				if requested {
					cell.requestButton.backgroundColor = UIColor.seafoam
					cell.requestButton.layer.borderColor = UIColor.seafoam.cgColor
					cell.requestButton.setTitleColor(UIColor.white, for: .normal)
				} else {
					cell.requestButton.backgroundColor = UIColor.white
					cell.requestButton.layer.borderColor = UIColor.seafoam.cgColor
					cell.requestButton.setTitleColor(UIColor.seafoam, for: .normal)
				}
			}
		}
		
        //cell.layer.cornerRadius = 10
        cell.selectionStyle = UITableViewCellSelectionStyle.default
        
        return cell
    }
}

extension HomeViewController : UITableViewDelegate {
	
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let lastElement = listingManager.currentListings.count - 1
        if indexPath.row == lastElement  {
            
            listingManager.updateListingLimit()
        }
    }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		definesPresentationContext = true
		let vc = (storyboard?.instantiateViewController(withIdentifier: "ListingDetailTableViewController"))!
		vc.modalTransitionStyle = .coverVertical
		vc.modalPresentationStyle = .overCurrentContext
		(vc as! ListingDetailTableViewController).listing = listingManager.currentListings[indexPath.row]
		present(vc, animated: true, completion: nil)
		if pulleyViewController?.drawerPosition == PulleyPosition.open {
			pulleyViewController?.setDrawerPosition(position: .partiallyRevealed, animated: true)
		}
		
//		if let drawer = self.parent as? PulleyViewController
//		{
//			let drawerContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ListingDetailTableViewController")
//			(drawerContent as! ListingDetailTableViewController).listing = listingManager.currentListings[indexPath.row]
//			drawer.setDrawerContentViewController(controller: drawerContent, animated: true)
//		}
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		
		var swipeConfig : UISwipeActionsConfiguration?
		let listing = listingManager.currentListings[indexPath.row]
		
		if let active = listing.active {
			if !active {
				if listing.user?.uid != currentUserId {
					let requestAction = self.contextualRequestAction(forRowAtIndexPath: indexPath)
					swipeConfig = UISwipeActionsConfiguration(actions: [requestAction])
				} else {
					let editAction = self.contextualEditAction(forRowAtIndexPath: indexPath)
					let deleteAction = self.contextualDeleteAction(forRowAtIndexPath: indexPath)
					swipeConfig = UISwipeActionsConfiguration(actions: [deleteAction])
				}
			} else {
				let completeAction = self.contextualCompleteAction(forRowAtIndexPath: indexPath)
				let cancelAction = self.contextualCancelAction(forRowAtIndexPath: indexPath)
				swipeConfig?.performsFirstActionWithFullSwipe = false
				swipeConfig = UISwipeActionsConfiguration(actions: [completeAction,cancelAction])
			}
		}
		
		return swipeConfig
	}
}

// MARK: - Search extensions

extension HomeViewController : UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        print("update search results")
    }
	
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		pulleyViewController?.setDrawerPosition(position: .open, animated: true)
	}
}

// MARK: - Pully extension

extension HomeViewController: PulleyDrawerViewControllerDelegate {
	
	func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat
	{
		// For devices with a bottom safe area, we want to make our drawer taller. Your implementation may not want to do that. In that case, disregard the bottomSafeArea value.
		return 150 + bottomSafeArea
	}
	
	func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat
	{
		// For devices with a bottom safe area, we want to make our drawer taller. Your implementation may not want to do that. In that case, disregard the bottomSafeArea value.
		return 350.0 + bottomSafeArea
	}
	
	func supportedDrawerPositions() -> [PulleyPosition] {
		return PulleyPosition.all // You can specify the drawer positions you support. This is the same as: [.open, .partiallyRevealed, .collapsed, .closed]
	}
	
	func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
		drawerBottomSafeArea = bottomSafeArea

		tableView.isScrollEnabled = drawer.drawerPosition == .open || drawer.currentDisplayMode == .leftSide
		
		if drawer.drawerPosition != .open
		{
			searchController.searchBar.resignFirstResponder()
		}
		
		if drawer.drawerPosition == .collapsed
		{
			heightConstraint.constant = 150 + bottomSafeArea
			bottomCollectionViewSeparator.isHidden = true
		}
		else
		{
			bottomCollectionViewSeparator.isHidden = false
			heightConstraint.constant = 150
		}
	}
}

// MARK: - ListingManager extension
extension HomeViewController: ListingManagerDelegate {
	func updateListings() {
		print("Update listings")
		listingManager.updateCurrentListings(withIndex: menuItemsManager.FilterIndex)
		tableView.reloadData()
	}
	func startLoading() {
		
	}
	func stopLoading() {
		
	}
}
