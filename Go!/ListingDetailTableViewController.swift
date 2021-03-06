//
//  ListingDetailTableViewController.swift
//  Go!
//
//  Created by Jordan Donato on 7/28/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import UIKit
import Firebase

class ListingDetailTableViewController: UITableViewController {

	// MARK: - Outlets
	@IBOutlet weak var gripperView: UIView!
	@IBOutlet weak var userImageView: UIImageView!
	@IBOutlet weak var userButton: UIButton!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var exitButton: UIButton!
	@IBOutlet weak var timeAgoLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	
	@IBOutlet weak var completeButton: UIButton!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var requestButton: UIButton!
	@IBOutlet weak var requestsCollectionView: UICollectionView!
	
	@IBOutlet weak var descriptionLabel: UILabel!
	
	@IBOutlet weak var approvedUserButton: UIButton!
	@IBOutlet weak var fulfilledLabel: UILabel!
	// MARK: - Members
	var listing : Listing! = nil
	var currentUser : String?
	
	// MARK: - Actions
	@IBAction func onExitPressed(_ sender: UIButton) {
		//		if let drawer = self.parent as? PulleyViewController
		//		{
		//			let drawerContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController")
		//
		//			drawer.setDrawerContentViewController(controller: drawerContent, animated: true)
		//		}
		
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func onRequestPressed(_ sender: Any) {
		
		if listing?.user?.uid != currentUser {
			if let key = listing?.key, let requested = listing?.requested {
				ListingManager.sharedInstance.updateRequests(forKey: key, updateChild: !requested)
				dismiss(animated: true, completion: nil)
			}
		}
	}
	
	@IBAction func onCompletePressed(_ sender: Any) {
		
	}

	@IBAction func onCancelPressed(_ sender: Any) {
		
	}
	
	@IBAction func onApprovedUserPressed(_ sender: Any) {
	}
	
	
	// MARK: - ViewController Lifecycle
	override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
		
		ListingManager.sharedInstance.listingDetailDelegate = self
		currentUser = Auth.auth().currentUser?.uid
		
		initializeUI()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		if listing.user?.uid == currentUser {
			ListingManager.sharedInstance.registerRequestsObserver(forKey: listing.key!)
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		if listing.user?.uid == currentUser {
			ListingManager.sharedInstance.removeRequestsObserver(forKey: listing.key!)
		}
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - Private methods
	
	fileprivate func initializeUI() {
		self.tableView.tableFooterView = UIView()
		gripperView.layer.cornerRadius = 2.5
		
		userImageView.image = listing.user?.profilePhoto
		userImageView.layer.cornerRadius = userImageView.frame.size.width / 2;
		userImageView.clipsToBounds = true;
		
		userButton.setTitle(listing.user?.userName, for: .normal)
		descriptionLabel.text = listing.listingDescription
		
		if let amount = listing.amount {
			amountLabel.text = "$" + amount
		}
		
		timeAgoLabel.text = listing.timeAgoSinceDate(true)
		distanceLabel.text = listing.user?.uid  != currentUser ? listing.getDistanceFromListing(userLocation: ListingManager.sharedInstance.userLocation) : ""
		
		if let active = listing.active {
			if !active {
				if listing.user?.uid != currentUser {
					if listing.requested! {
						requestButton.setTitle("Cancel Request", for: .normal)
						requestButton.backgroundColor = UIColor.red
						
					} else {
						requestButton.setTitle("Request", for: .normal)
						requestButton.backgroundColor = UIColor.seafoam
					}
					
					showRequestButton(show: true)
					requestsCollectionView.isHidden = true
				} else {
					showRequestButton(show: false)
					requestsCollectionView.isHidden = false
				}
				
				showCompletionButtons(show: false)
				showApprovedUserButton(show: false, photo: nil)
				fulfilledLabel.isHidden = true
			} else {
				
				if let approvedUser = listing.approvedUser {
					if approvedUser == currentUser {
						print("Approved user is the current user")
						showCompletionButtons(show: true)
						fulfilledLabel.isHidden = true
						
					} else {
						print("approved user is not the current user")
						showCompletionButtons(show: false)
						fulfilledLabel.isHidden = false
						
						FirebaseUser(uid: approvedUser, completion: { (firebaseUser) in
							self.approvedUserButton.setBackgroundImage(firebaseUser.profilePhoto, for: .normal)
							self.showApprovedUserButton(show: true, photo: firebaseUser.profilePhoto)
						})
					}
				}
				requestsCollectionView.isHidden = true
				showRequestButton(show: false)				
			}
		}
	}
	
	fileprivate func showCompletionButtons(show: Bool) {
		completeButton.layer.cornerRadius = 10
		completeButton.clipsToBounds = true
		cancelButton.layer.cornerRadius = 10
		cancelButton.clipsToBounds = true
		
		completeButton.isHidden = !show
		completeButton.isEnabled = show
		cancelButton.isHidden = !show
		cancelButton.isEnabled = show
	}
	
	fileprivate func showApprovedUserButton(show: Bool, photo: UIImage?) {
		if let photo = photo {
			self.approvedUserButton.setBackgroundImage(photo, for: .normal)
			self.approvedUserButton.layer.cornerRadius = self.approvedUserButton.frame.size.width / 2;
			self.approvedUserButton.clipsToBounds = true;
		}

		self.approvedUserButton.isHidden = !show
		self.approvedUserButton.isEnabled = show
		print("finished setting approved user photo")
	}
	
	fileprivate func showRequestButton(show: Bool) {
		requestButton.layer.cornerRadius = 10
		requestButton.clipsToBounds = true
		
		requestButton.isHidden = !show
	}
	
	@objc fileprivate func onUserButtonPressed(_ sender: UIButton) {
		let userId = ListingManager.sharedInstance.requestingUserIDs[sender.tag]
		print("user selected " + userId)
		
		ListingManager.sharedInstance.updateApproved(listing: listing, forUserId: userId)
		dismiss(animated: true, completion: nil)
	}

    // MARK: - Table view data source
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 1
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 3
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
		
		if let button = sender as? UIButton {
			if (button.accessibilityIdentifier?.contains("usernameButton"))!{
				print("sender is ui button")
				let nextScene = segue.destination as! ProfileViewController
				if let uid = listing.user?.uid {
					nextScene.uid = uid
				}
			} else if (button.accessibilityIdentifier?.contains("completeButton"))! {
				let nextScene = segue.destination as! ReviewViewController
				nextScene.listing = listing
			}
		}
    }
	

}
// MARK: - Collection View Extension
extension ListingDetailTableViewController : UICollectionViewDelegate {
	
}

extension ListingDetailTableViewController : UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return ListingManager.sharedInstance.requestingUsers.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RequestsCollectionViewCell
		
		//cell.userLabel.text = ListingManager.sharedInstance.requestingUsers[indexPath.row]
		
		cell.userButton.setBackgroundImage(ListingManager.sharedInstance.requestingUserPhotos[indexPath.row], for: UIControl.State.normal)
		cell.userButton.layer.cornerRadius = cell.userButton.frame.size.width / 2;
		cell.userButton.clipsToBounds = true;
		cell.userButton.addTarget(self, action: #selector(onUserButtonPressed(_:)), for: UIControl.Event.touchUpInside)
		cell.userButton.tag = indexPath.row
		
		return cell
	}
}

// MARK: - Listing Manager Delegate extension
extension ListingDetailTableViewController : ListingManagerDelegate {
	func didUpdateRequests() {
		requestsCollectionView.reloadData()
	}
}
