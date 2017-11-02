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
    var otherUserIDs = [String]()
    var activeAmounts = [String]()
    var listingKeys = [String]()
    
    var listingSelected: String?
    var posterSelected: String?
    var approvedSelected: String?
    var otherId: String?

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
        tableView.tableFooterView = UIView()
        
        self.navigationItem.title = "Active Listings"
    }

    override func viewDidAppear(_ animated: Bool) {
        print("View did appear")
        clearData()
        registerActivesObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("View did disappear")
        ref?.child(Keys.Active.rawValue).child((Auth.auth().currentUser?.uid)!).removeAllObservers()
    }
    
    func registerActivesObserver() {
        
        let deactivateDeleteButtonInUserPostWhenActive: String
        
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
                    self.getUserData(userID: poster!, otherID: approved!,listingKey: listingKey)
                }
                else {
                    // use approved id
                    self.getUserData(userID: approved!, otherID: poster!, listingKey: listingKey)
                }
            }
            
        })
    }
    
    func getUserData(userID : String, otherID : String, listingKey : String) {
        print("getting user data for " + userID)
        self.ref?.child(Keys.Users.rawValue).child(userID).observeSingleEvent(of: .value, with: { (usersSnapshot) in
            print(usersSnapshot)
            if let values = usersSnapshot.value as? [String : Any] {
                let username = values[Keys.Username.rawValue]!
                let profileURL = values[Keys.ProfileURL.rawValue]!
                
                let url = URL(string: profileURL as! String)
                let data = try? Data(contentsOf: url!)
                let photo = UIImage(data: data!)
                
                self.ref?.child(Keys.Listings.rawValue).child(listingKey).child(Keys.Amount.rawValue).observeSingleEvent(of: .value, with: { (amount) in
                    
                    print("description " + amount.value.debugDescription + " listing key " + listingKey)
                    let amount = amount.value as! String
                    
                    self.activeUsers.append(username as! String)
                    self.activeUserPhotos.append(photo!)
                    self.activeUserIDs.append(userID)
                    self.otherUserIDs.append(otherID)
                    self.activeAmounts.append(amount)
                    self.listingKeys.append(listingKey)
                    
                    self.tableView.reloadData()
                })
                
                
            }
            
        })
    }
    
    func clearData() {
        
        self.activeUsers.removeAll()
        self.activeUserPhotos.removeAll()
        self.activeUserIDs.removeAll()
        self.activeAmounts.removeAll()
        self.listingKeys.removeAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return "Active Listings"
//    }
//
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 40
//    }
//
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerview = UIView()
//        headerview.backgroundColor = UIColor(hue: 155/360, saturation: 1, brightness: 0.98, alpha: 1)
//
//        let headerLabel = UILabel(frame: CGRect(x: 10, y: 7.5, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
//        headerLabel.font = UIFont(name: "Verdana", size: 20)
//        headerLabel.textColor = UIColor.white
//        headerLabel.text = self.tableView(self.tableView, titleForHeaderInSection: section)
//        headerLabel.sizeToFit()
//        headerview.addSubview(headerLabel)
//
//        return headerview
//    }

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
        
        cell.userNameLabel.text = activeUsers[indexPath.row]
        cell.amountLabel.text = "$" + activeAmounts[indexPath.row]
        cell.amountLabel.textColor = UIColor(hue: 155/360, saturation: 1, brightness: 0.98, alpha: 1)
        
        cell.listingKey = listingKeys[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentCell = tableView.cellForRow(at: indexPath) as! ActiveTableViewCell
        listingSelected = listingKeys[indexPath.row]
        approvedSelected = activeUserIDs[indexPath.row]
        otherId = otherUserIDs[indexPath.row]
        
        print("selected cell approved selected " + approvedSelected!)
        performSegue(withIdentifier: "showActiveDetail", sender: self)
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? ActiveDetailViewController {
            vc.listingKey = listingSelected
            vc.approvedId = approvedSelected
            vc.posterId = otherId
            
            print("listing key " + listingSelected! + " approved id " + approvedSelected!)
        }
    }
 

}
