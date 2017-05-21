//
//  HomeViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/17/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import FirebaseDatabase

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var ref : FIRDatabaseReference?
    var databaseHandle : FIRDatabaseHandle?
    
    var listings = [[String : AnyObject]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // get reference to database
        ref = FIRDatabase.database().reference()
        
        // save all items in Listings node to dictionary array
        databaseHandle = ref?.child("Listings").observe(.value, with: { (snapshot) in
            
            let listingDict = snapshot.value as? [String : AnyObject] ?? [:]
            
            self.listings.removeAll()
            for listing in listingDict {
                
                let dict : [String : AnyObject] = [listing.key : listing.value]
                self.listings.append(dict)
            }
            
            print("Updating table view")
            self.tableView.reloadData()
        })
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return listings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let listingItem = listings[indexPath.row]
        
        for listing in listingItem.values {
            
            if let listingDict = listing as? [String : String] {
                
                cell.textLabel?.text = listingDict["Title"]
                cell.detailTextLabel?.text = listingDict["Description"]
            }
        }
        
        return cell
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
