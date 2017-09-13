//
//  RequestsTableViewController.swift
//  Go!
//
//  Created by Jordan Donato on 8/24/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class RequestsTableViewController: UITableViewController {
    
    var key = String()
    
    var ref : DatabaseReference?
    
    var requestingUsers = [String]()
    var requestingUserPhotos = [UIImage]()
    var requestingUserIDs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get reference to database
        ref = Database.database().reference()
        
        ref?.child(Keys.Requests.rawValue).child(key).observe(.childAdded, with: { (snapshot) in
            
            let userID = snapshot.key
        
            self.ref?.child(Keys.Users.rawValue).child(userID).observeSingleEvent(of: .value, with: { (usersSnapshot) in
                print(usersSnapshot)
                if let values = usersSnapshot.value as? [String : String] {
                    let username = values[Keys.Username.rawValue]!
                    let profileURL = values[Keys.ProfileURL.rawValue]!
       
                    let url = URL(string: profileURL)
                    let data = try? Data(contentsOf: url!)
                    let photo = UIImage(data: data!)
                    
                    self.requestingUsers.append(username)
                    self.requestingUserPhotos.append(photo!)
                    self.requestingUserIDs.append(userID)
                    
                    self.tableView.reloadData()
                }
                
            })
        })
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 111

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func OnApproveButtonPressed(_ sender: UIButton) {
        
        let requestingUID = requestingUserIDs[sender.tag]
        
        print("approve button " + requestingUID + " pressed")
        
        let activeUsers = ["Poster": (Auth.auth().currentUser?.uid)!, "Approved": requestingUID]
        
        let childUpdates = ["/\(requestingUID)/\(key)" : activeUsers,
                            "/\((Auth.auth().currentUser?.uid)!)/\(key)" : activeUsers]
        ref?.child(Keys.Active.rawValue).updateChildValues(childUpdates)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return requestingUsers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath) as! RequestTableViewCell

        // Configure the cell...
        cell.userNameButton.setTitle(requestingUsers[indexPath.row], for: .normal)
        cell.userNameButton.uid = requestingUserIDs[indexPath.row]
        
        cell.approveButton.tag = indexPath.row
        cell.approveButton.addTarget(self, action: #selector(OnApproveButtonPressed(_:)), for: .touchUpInside)
        cell.profileImageView.image = requestingUserPhotos[indexPath.row]
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = true;
        
        return cell
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
        
        if let userNameButton = sender as? UserNameButton {
            print("sender is ui button")
            let nextScene = segue.destination as! ProfileViewController
            nextScene.uid = userNameButton.uid
        }
        else {
            print("sender is not a ui button")
        }
    }
    

}
