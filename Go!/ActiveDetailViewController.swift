//
//  ActiveDetailViewController.swift
//  Go!
//
//  Created by Jordan Donato on 9/11/17.
//  Copyright © 2017 Go!. All rights reserved.
//

import UIKit
import Stripe
import Firebase

class ActiveDetailViewController: UIViewController {
    
    var ref : DatabaseReference?
    
    var listingKey: String!
    var posterId: String!
    var approvedId: String!
    
    var approvedAccountId: String?
    var posterCustomerId: String?
    

    private var customerContext: STPCustomerContext!
    private var paymentContext: STPPaymentContext!
    
    @IBOutlet weak var paymentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = Database.database().reference()
        
        customerContext = STPCustomerContext(keyProvider: MainAPIClient.shared)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        
        paymentContext.delegate = self
        paymentContext.hostViewController = self
        let fixHardCodedAmount : String
        print("***ACtive detail view did load \(approvedId)")
        ref?.child("Stripe").child(approvedId).child("accountId").observeSingleEvent(of: .value) { (snapshot) in
            print("approved acct id \(snapshot.value)")
            self.approvedAccountId = snapshot.value as? String
        }
        
        ref?.child("Stripe").child(posterId).child("customerId").observeSingleEvent(of: .value) { (snapshot) in
            print("poster acct id \(snapshot.value)")
            self.posterCustomerId = snapshot.value as? String
        }
        
        ref?.child(Keys.Listings.rawValue).child(listingKey).child(Keys.Amount.rawValue).observeSingleEvent(of: .value) { (snapshot) in
            print("payment amount \(snapshot.value)")
            self.paymentContext.paymentAmount = Int(snapshot.value as! String)! * 100
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCompleteButtonPressed(_ sender: UIButton) {
        paymentContext.requestPayment()
        
    }

    @IBAction func onPaymentButtonPressed(_ sender: Any) {
        presentPaymentMethodsViewController()
    }
    
    private func presentPaymentMethodsViewController() {
        guard !STPPaymentConfiguration.shared().publishableKey.isEmpty else {
            // Present error immediately because publishable key needs to be set
            let message = "Please assign a value to `publishableKey` before continuing. See `AppDelegate.swift`."
            print(message)
            //present(UIAlertController(message: message), animated: true)
            return
        }
        
        guard !MainAPIClient.shared.baseURLString.isEmpty else {
            // Present error immediately because base url needs to be set
            let message = "Please assign a value to `MainAPIClient.shared.baseURLString` before continuing. See `AppDelegate.swift`."
            //present(UIAlertController(message: message), animated: true)
            print(message)
            return
        }
        
        // Present the Stripe payment methods view controller to enter payment details
        paymentContext.presentPaymentMethodsViewController()
    }
    
    private func reloadPaymentButtonContent() {
        guard let selectedPaymentMethod = paymentContext.selectedPaymentMethod else {
            // Show default image, text, and color
            paymentButton.setImage(#imageLiteral(resourceName: "Payment"), for: .normal)
            paymentButton.setTitle("Payment", for: .normal)
            paymentButton.setTitleColor(.riderGrayColor, for: .normal)
            return
        }
        
        // Show selected payment method image, label, and darker color
        paymentButton.setImage(selectedPaymentMethod.image, for: .normal)
        paymentButton.setTitle(selectedPaymentMethod.label, for: .normal)
        paymentButton.setTitleColor(.riderDarkBlueColor, for: .normal)
    }
    
    private func createCharge(source : String, amount : Int) {
        var values = [String : Any]()
        values["customerId"] = posterCustomerId
        values["source"] = source
        values["amount"] = amount
        values["accountId"] = approvedAccountId!
        print("posting charges " + approvedAccountId!)
        ref?.child("Stripe").child(posterId).child("Charges").childByAutoId().setValue(values)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    deinit {
        print("ActiveDetailViewController Deinitialized")
    }
}

extension ActiveDetailViewController: STPPaymentContextDelegate {
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        if let customerKeyError = error as? MainAPIClient.CustomerKeyError {
            switch customerKeyError {
            case .missingBaseURL:
                // Fail silently until base url string is set
                print("[ERROR]: Please assign a value to `MainAPIClient.shared.baseURLString` before continuing. See `AppDelegate.swift`.")
            case .invalidResponse:
                // Use customer key specific error message
                print("[ERROR]: Missing or malformed response when attempting to `MainAPIClient.shared.createCustomerKey`. Please check internet connection and backend response formatting.");
                
                //                present(UIAlertController(message: "Could not retrieve customer information", retryHandler: { (action) in
                //                    // Retry payment context loading
                //                    paymentContext.retryLoading()
                //                }), animated: true)
            }
        }
        else {
            // Use generic error message
            print("[ERROR]: Unrecognized error while loading payment context: \(error)");
            
            //            present(UIAlertController(message: "Could not retrieve payment information", retryHandler: { (action) in
            //                // Retry payment context loading
            //                paymentContext.retryLoading()
            //            }), animated: true)
        }
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("payment context did change")
        // Reload related components
        reloadPaymentButtonContent()
        //        reloadRequestRideButton()
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        // Create charge using payment result
        let source = paymentResult.source.stripeID
        print("payment context did create payment result with id " + source)
        self.createCharge(source: source, amount: self.paymentContext.paymentAmount)
//        {
//            [weak self] (ride, error) in
//            guard let strongSelf = self else {
//                // View controller was deallocated
//                return
//            }
//
//            guard error == nil else {
//                // Error while requesting ride
//                completion(error)
//                return
//            }
//
//            // Save ride info to display after payment finished
//            strongSelf.rideRequestState = .active(ride!)
//            completion(nil)
//        }
        completion(nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        print("payment context did finish with status \(status)")
        dismiss(animated: true, completion: nil)
        //        switch status {
        //        case .success:
        //            // Animate active ride
        //            animateActiveRide()
        //        case .error:
        //            // Present error to user
        //            if let requestRideError = error as? MainAPIClient.RequestRideError {
        //                switch requestRideError {
        //                case .missingBaseURL:
        //                    // Fail silently until base url string is set
        //                    print("[ERROR]: Please assign a value to `MainAPIClient.shared.baseURLString` before continuing. See `AppDelegate.swift`.")
        //                case .invalidResponse:
        //                    // Missing response from backend
        //                    print("[ERROR]: Missing or malformed response when attempting to `MainAPIClient.shared.requestRide`. Please check internet connection and backend response formatting.");
        //                    present(UIAlertController(message: "Could not request ride"), animated: true)
        //                }
        //            }
        //            else {
        //                // Use generic error message
        //                print("[ERROR]: Unrecognized error while finishing payment: \(String(describing: error))");
        //                present(UIAlertController(message: "Could not request ride"), animated: true)
        //            }
        //
        //            // Reset ride request state
        //            rideRequestState = .none
        //        case .userCancellation:
        //            // Reset ride request state
        //            rideRequestState = .none
        //        }
    }
}
