//
//  NewListingViewController.swift
//  Go!
//
//  Created by Jordan Donato on 5/21/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Firebase

class PostViewController: UIViewController {

    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var ref : FIRDatabaseReference?
    var postDict = [String : String]()
    
    @IBAction func cancelPressed(_ sender: Any) {
        
        // create alert before canceling
        amountTextField.text = ""
        descriptionTextView.text = ""
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        
        //todo check for null fields and create alert with activity bar
        postDict["Username"] = FIRAuth.auth()?.currentUser?.displayName
        postDict["ProfileURL"] = FIRAuth.auth()?.currentUser?.providerData[0].photoURL?.absoluteString
        postDict["Description"] = descriptionTextView.text
        postDict["Amount"] = amountTextField.text
        
        ref?.child("Listings").childByAutoId().setValue(postDict)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
