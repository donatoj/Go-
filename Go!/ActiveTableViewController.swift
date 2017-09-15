//
//  ActiveTableViewController.swift
//  Go!
//
//  Created by Jordan Donato on 9/7/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class ActiveTableViewController: UITableViewController {
    
    var ref : DatabaseReference?
    
    var activeUsers = [String]()
    var activeUserPhotos = [UIImage]()
    var activeUserIDs = [String]()
    var activeDescriptions = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get reference to database
        ref = Database.database().reference()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111
    }

    override func viewDidAppear(_ animated: Bool) {
        
        registerActivesObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        ref?.child(Keys.Active.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
    }
    
    func registerActivesObserver() {
        
        let createActivesDataSource: String
        
        ref?.child(Keys.Active.rawValue).child((Auth.auth().currentUser?.uid)!).observe(.childAdded, with: { (snapshot) in
            
            let listingKey = snapshot.key
            print("listing key " + listingKey)
            
            if let values = snapshot.value as? [String : String] {
                print("values " + values.debugDescription)
                let approved =  values["Approved"]
                let poster = values["Poster"]
                
                print("approved " + approved! + " poster " + poster!)
                
                if (Auth.auth().currentUser?.uid)! != poster {
                    // use poster id
                    self.getUserData(userID: poster!, listingKey: listingKey)
                }
                else {
                    // use approved id
                    self.getUserData(userID: approved!, listingKey: listingKey)
                }
            }
        })
    }
    
    func getUserData(userID : String, listingKey : String) {
        print("getting user data for " + userID)
        self.ref?.child(Keys.Users.rawValue).child(userID).observeSingleEvent(of: .value, with: { (usersSnapshot) in
            print(usersSnapshot)
            if let values = usersSnapshot.value as? [String : Any] {
                let username = values[Keys.Username.rawValue]!
                let profileURL = values[Keys.ProfileURL.rawValue]!
                
                let url = URL(string: profileURL as! String)
                let data = try? Data(contentsOf: url!)
                let photo = UIImage(data: data!)
                
                self.ref?.child(Keys.Listings.rawValue).child(listingKey).child(Keys.Description.rawValue).observeSingleEvent(of: .value, with: { (description) in
                    
                    print("description " + description.value.debugDescription)
                    let description = description.value as! String
                    
                    self.activeUsers.append(username as! String)
                    self.activeUserPhotos.append(photo!)
                    self.activeUserIDs.append(userID)
                    self.activeDescriptions.append(description)
                    
                    self.tableView.reloadData()
                })
                
                
            }
            
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Active Listings"
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return activeUsers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ActiveTableViewCell

        // Configure the cell...
        
        cell.profileButton.setImage(activeUserPhotos[indexPath.row], for: UIControlState.normal)
        cell.profileButton.layer.cornerRadius = (cell.profileButton.frame.size.width) / 2;
        cell.profileButton.clipsToBounds = true;
        
        let boldText  = activeUsers[indexPath.row]
        let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 15)]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
        
        let italicText = activeDescriptions[indexPath.row]
        let attrsIt = [NSFontAttributeName : UIFont.italicSystemFont(ofSize: 18)]
        let attributedItString = NSMutableAttributedString(string:italicText, attributes:attrsIt)
        
        let normalText = " is working on \n"
        let normalString = NSMutableAttributedString(string:normalText)
        normalString.append(attributedItString)
        
        attributedString.append(normalString)
        
        cell.descriptionLabel.attributedText = attributedString

        return cell
    }
 
    deinit {
        
        print("ActiveTableViewController deinitialized")
    }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
