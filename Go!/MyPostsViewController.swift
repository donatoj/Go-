//
//  MyPostsViewController.swift
//  Go!
//
//  Created by Jordan Donato on 9/20/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
//import PageControl

class MyUser {
    
    var id: Int?
    var name: String?
    var email: String?
    var following: Int = 0
    var followers: Int = 0
    var boy: Bool = false
    
    init(id: Int, name: String, email: String, following: Int, followers: Int, boy: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.following = following
        self.followers = followers
        self.boy = boy
    }
}

class MyPostsViewController: UIViewController {

    var pageController: PageControlViewController!
    var data: [Listing] = []
    var dataController: [UIViewController] = []
    
    @IBOutlet weak var containerView: UIView!
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8) //view only black coloured transparent
//        
//        self.data = [
//            MyUser(id: 1, name: "Rodrigo Martins", email: "policante.martins@gmail.com", following: 1000, followers: 2000, boy: true),
//            MyUser(id: 2, name: "Michael Roy", email: "michael.roy@mail.com", following: 31, followers: 501, boy: true),
//            MyUser(id: 3, name: "Frank Donald", email: "frank.donald@mail.com", following: 154, followers: 921, boy: true),
//            MyUser(id: 4, name: "Tom", email: "tom@mail.com", following: 12, followers: 65, boy: true),
//            MyUser(id: 5, name: "Jerry", email: "jerry@mail.com", following: 720, followers: 682, boy: false),
//            MyUser(id: 6, name: "Piterson", email: "piterson@mail.com", following: 605, followers: 240, boy: true),
//            MyUser(id: 7, name: "Kessy", email: "kessy@mail.com", following: 120, followers: 804, boy: false),
//            MyUser(id: 8, name: "Juh", email: "juh@mail.com", following: 942, followers: 2510, boy: false)
//        ]
        
        self.data = Array(ListingsDataSource.sharedInstance.selfListings.values)
        
        for us in self.data {
            let vc = CardItemViewController()
            vc.listing = us
            vc.delegate = self as CardDelegate
            self.dataController.append(vc)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PageControlViewController {
            self.pageController = controller
            self.pageController.delegate = self as PageControlDelegate
            self.pageController.dataSource = self as PageControlDataSource
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
                break
            }
        }
        self.pageController.updateData()
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
