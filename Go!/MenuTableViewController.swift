//
//  MenuTableViewController.swift
//  Go!
//
//  Created by Jordan Donato on 9/22/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import FirebaseAuth

enum Menu: Int {
    case profile = 0
    case home
    case notifications
    case history
    case payments
    case settings
}

protocol MenuProtocol : class {
    func changeViewController(_ menu: Menu)
}

class MenuTableViewController: UITableViewController, MenuProtocol {
    
    var menus = ["Profile", "Home", "Notifications", "History", "Payments", "Settings"]
    var profileViewController: UIViewController!
    var homeViewController: UIViewController!
    var notificationsViewController: UIViewController!
    var historyViewController: UIViewController!
    var paymentsViewController: UIViewController!
    var settingsViewController: UIViewController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("menu view controller view did load")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        profileViewController.uid = (Auth.auth().currentUser?.uid)!
        profileViewController.fromMenu = true
        self.profileViewController = UINavigationController(rootViewController: profileViewController)
        
        let notificationsViewController = storyboard.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
        self.notificationsViewController = UINavigationController(rootViewController: notificationsViewController)
        
        let historyViewController = storyboard.instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
        self.historyViewController = UINavigationController(rootViewController: historyViewController)
        
        let paymentsViewController = storyboard.instantiateViewController(withIdentifier: "PaymentsViewController") as! PaymentsViewController
        self.paymentsViewController = UINavigationController(rootViewController: paymentsViewController)
        
        let settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        self.settingsViewController = UINavigationController(rootViewController: settingsViewController)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func changeViewController(_ menu: Menu) {
        switch menu {
        case .profile:
            self.slideMenuController()?.changeMainViewController(self.profileViewController, close: true)
        case .home:
            self.slideMenuController()?.changeMainViewController(self.homeViewController, close: true)
        case .notifications:
            self.slideMenuController()?.changeMainViewController(self.notificationsViewController, close: true)
        case .history:
            self.slideMenuController()?.changeMainViewController(self.historyViewController, close: true)
        case .payments:
            self.slideMenuController()?.changeMainViewController(self.paymentsViewController, close: true)
        case .settings:
            self.slideMenuController()?.changeMainViewController(self.settingsViewController, close: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print("menus count  " + menus.count.description)
        return menus.count
    }
 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("did select row " + indexPath.row.description)
        if let menu = Menu(rawValue: indexPath.row) {
            self.changeViewController(menu)
        }
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
