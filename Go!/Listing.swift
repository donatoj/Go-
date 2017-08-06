//
//  Listing.swift
//  Go!
//
//  Created by Jordan Donato on 8/5/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import Foundation
import UIKit

struct Listing {
    
    let userName: String
    let description: String
    let amount: String
    let photoURL: String
    
    let profilePhoto: UIImage?
    
    init(userName: String, description: String, amount: String, photoURL: String) {
        
        self.userName = userName
        self.description = description
        self.amount = amount
        self.photoURL = photoURL
        
        let url = URL(string: photoURL)
        let data = try? Data(contentsOf: url!)
        self.profilePhoto = UIImage(data: data!)
    }
}
