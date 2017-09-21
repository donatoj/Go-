//
//  CardItemViewController.swift
//  PageControl
//
//  Created by Rodrigo Martins on 08/09/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

protocol CardDelegate {
    func removeCard(_ listing: Listing)
}

class CardItemViewController: UIViewController {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var timePassed: UILabel!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var btnRemove: UIButton!
    
    var listing: Listing!
    var delegate: CardDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        name.text = listing.userName
        
        amount.text = "$ " + listing.amount
        amount.textColor = UIColor.green
        
        timePassed.text = listing.timeAgoSinceDate()
        timePassed.textColor = UIColor.red
        
        descriptionText.text = listing.description
        
        photo.image = listing.profilePhoto
        photo.layer.cornerRadius = photo.frame.size.width / 3
        photo.clipsToBounds = true
        
        btnRemove.layer.cornerRadius = btnRemove.frame.size.height / 2
    }
    
    func animateImage(){
        guard self.photo != nil else {
            return
        }
        UIView.transition(with: self.photo, duration: 1.0, options: .transitionFlipFromLeft, animations: nil)
    }
    
    @IBAction func doRemove(_ sender: Any) {
        self.delegate.removeCard(self.listing)
    }
    
}
