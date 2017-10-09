//
//  MyPostsViewController.swift
//  Go!
//
//  Created by Jordan Donato on 9/20/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Firebase

protocol MyPostsDataSource {
    
    func getSelfListings() -> [String : Listing]
}

class MyPostsViewController: UIViewController {

    var ref : DatabaseReference?
    
    var pageController: PageControlViewController!
    var data: [Listing] = []
    var dataController: [UIViewController] = []
    
    var currentListing: Listing?
    var dataSource: MyPostsDataSource!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get reference to database
        ref = Database.database().reference()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8) //view only black coloured transparent

        self.data = Array(self.dataSource.getSelfListings().values)
        
        for us in self.data {
            let vc = CardItemViewController()
            vc.listing = us
            vc.delegate = self as CardDelegate
            self.dataController.append(vc)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PageControlViewController {
            self.pageController = controller
            self.pageController.delegate = self as PageControlDelegate
            self.pageController.dataSource = self as PageControlDataSource
        }
        
        if let controller = segue.destination as? RequestsTableViewController {
            print("segueing to request table view")
            controller.key = (currentListing?.key)!
        }
    }

}

extension MyPostsViewController: CardDelegate {
    
    func removeCard(_ listing: Listing) {
        for position in 0..<self.data.count {
            let dataListing = self.data[position]
            if dataListing.uid == listing.uid {
                self.data.remove(at: position)
                self.dataController.remove(at: position)
                print("removing listing uid " + listing.key)
                self.ref?.child(Keys.Listings.rawValue).child(listing.key).removeValue()
                break
            }
        }
        self.pageController.updateData()
    }
    
    func viewRequests(_ listing: Listing) {
        self.currentListing = listing
        performSegue(withIdentifier: "showRequests", sender: self)
    }
}

extension MyPostsViewController: PageControlDelegate {
    
    func pageControl(_ pageController: PageControlViewController, atSelected viewController: UIViewController) {
        (viewController as! CardItemViewController).animateImage()
    }
    
    func pageControl(_ pageController: PageControlViewController, atUnselected viewController: UIViewController) {
        
    }
    
}

extension MyPostsViewController: PageControlDataSource {
    
    func numberOfCells(in pageController: PageControlViewController) -> Int {
        return self.dataController.count
    }
    
    func pageControl(_ pageController: PageControlViewController, cellAtRow row: Int) -> UIViewController! {
        return self.dataController[row]
    }
    
    func pageControl(_ pageController: PageControlViewController, sizeAtRow row: Int) -> CGSize {
        let width = pageController.view.bounds.size.width - 20
        if row == pageController.currentPosition {
            return CGSize(width: width, height: 500)
        }
        return CGSize(width: width, height: 500)
    }
    
}
