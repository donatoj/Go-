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
    @IBOutlet weak var segmentControl: UISegmentedControl!
	
	// MARK: - Members
	var listingManager = ListingManager.sharedInstance
    var searchController : UISearchController!
	
	var currentUserId : String?
	
	// MARK: - Actions
    @IBAction func OnSegmentValueChanged(_ sender: Any) {
        updateListings()
    }
	
	// MARK: - ViewController LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
		
		listingManager.homeViewDelegate = self
        listingManager.registerObservers()
		
        showSearchBar()
		
		currentUserId = Auth.auth().currentUser?.uid
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("View Did Appear")
        
        listingManager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("View Did disappear")
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
				let nextScene = segue.destination as! RequestsTableViewController
				nextScene.key = listingItem.key
			} else if (button.accessibilityIdentifier?.contains("usernameButton"))!{
				print("sender is ui button")
				let nextScene = segue.destination as! ProfileViewController
				nextScene.uid = listingItem.uid
			}
		}
	}
	
	// MARK: - Private functions
	
	fileprivate func showSearchBar() {
		searchController = UISearchController(searchResultsController:  nil)
		
		searchController.searchResultsUpdater = self
		searchController.delegate = self
		searchController.searchBar.delegate = self
		
		searchController.hidesNavigationBarDuringPresentation = true
		searchController.dimsBackgroundDuringPresentation = true
		
		if #available(iOS 11.0, *) {
			if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
				
				if let backgroundview = textfield.subviews.first {
					
					// Background color
					backgroundview.backgroundColor = UIColor.white
					
					// Rounded corner
					backgroundview.layer.cornerRadius = 10;
					backgroundview.clipsToBounds = true;
					
				}
			}
			
			navigationItem.searchController = searchController
			navigationItem.searchController?.isActive = true
		} else {
			tableView.tableHeaderView = searchController.searchBar
		}
		
		definesPresentationContext = true
	}
    
    @objc func onRequestPressed(_ sender: UIButton) {
        let listingItem = listingManager.currentListings[sender.tag]
		
		if listingItem.uid != currentUserId {
			listingManager.updateRequests(forKey: listingItem.key, updateChild: !listingItem.requested)
		} else {
			performSegue(withIdentifier: "showRequests", sender: sender)
		}
    }
}

// MARK: - TableView extensions

extension HomeViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return listingManager.currentListings.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PostTableViewCell
        
        let listingItem = listingManager.currentListings[indexPath.section]
        
        // check for only items not from user
        cell.userNameButton.setTitle(listingItem.userName, for: UIControlState.normal)
        cell.userNameButton.tag = indexPath.section
        
        cell.descriptionLabel.text = listingItem.listingDescription
        
        cell.profileImageView.image = listingItem.profilePhoto
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = true;
        
        cell.timeAgo.text = listingItem.timeAgoSinceDate(true)
        cell.distance.text = listingItem.getDistanceFromListing(userLocation: listingManager.userLocation)
        
        cell.requestButton.setTitle("$" + listingItem.amount, for: UIControlState.normal)
        cell.requestButton.layer.borderWidth = 1
        cell.requestButton.layer.cornerRadius = 8
        cell.requestButton.clipsToBounds = true
        cell.requestButton.tag = indexPath.section
        cell.requestButton.addTarget(self, action: #selector(onRequestPressed(_:)), for: .touchUpInside)
		
		if listingItem.uid == currentUserId {
			cell.requestButton.setTitle("View Requests", for: UIControlState.normal)
			cell.requestButton.backgroundColor = UIColor.white
			cell.requestButton.layer.borderColor = UIColor.blue.cgColor
			cell.requestButton.setTitleColor(UIColor.blue, for: .normal)
		} else {
			if listingItem.requested {
				if segmentControl.selectedSegmentIndex == 3 {
					cell.requestButton.backgroundColor = UIColor.red
					cell.requestButton.layer.borderColor = UIColor.red.cgColor
				} else {
					cell.requestButton.backgroundColor = UIColor.seafoam
					cell.requestButton.layer.borderColor = UIColor.seafoam.cgColor
				}
				cell.requestButton.setTitleColor(UIColor.white, for: .normal)
			} else {
				cell.requestButton.backgroundColor = UIColor.white
				cell.requestButton.layer.borderColor = UIColor.seafoam.cgColor
				cell.requestButton.setTitleColor(UIColor.seafoam, for: .normal)
			}
		}
		
        cell.layer.cornerRadius = 10
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell
    }
}

extension HomeViewController : UITableViewDelegate {
	
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let lastElement = listingManager.currentListings.count - 1
        if indexPath.section == lastElement  {
            
            listingManager.updateListingLimit()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerview = UIView()
        headerview.backgroundColor = UIColor.clear
        return headerview
        
    }
}

// MARK: - Search extensions

extension HomeViewController : UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        print("update search results")
    }
}

// MARK: - Pully extension

extension HomeViewController: PulleyDrawerViewControllerDelegate {
	
	func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat
	{
		print("collapsed height drawer height " + bottomSafeArea.description)
		// For devices with a bottom safe area, we want to make our drawer taller. Your implementation may not want to do that. In that case, disregard the bottomSafeArea value.
		return 168.0 + bottomSafeArea
	}
	
	func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat
	{
		print("partial reviewl height drawer height " + bottomSafeArea.description)
		// For devices with a bottom safe area, we want to make our drawer taller. Your implementation may not want to do that. In that case, disregard the bottomSafeArea value.
		return 364.0 + bottomSafeArea
	}
	
	func supportedDrawerPositions() -> [PulleyPosition] {
		return PulleyPosition.all // You can specify the drawer positions you support. This is the same as: [.open, .partiallyRevealed, .collapsed, .closed]
	}
}

// MARK: - ListingManager extension
extension HomeViewController: ListingManagerDelegate {
	func updateListings() {
		print("Update listings")
		listingManager.updateCurrentListings(withIndex: segmentControl.selectedSegmentIndex)
		tableView.reloadData()
	}
	func startLoading() {
		
	}
	func stopLoading() {
		
	}
}
