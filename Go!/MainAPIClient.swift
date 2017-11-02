//
//  MainAPIClient.swift
//  RocketRides
//
//  Created by Romain Huet on 5/26/16.
//  Copyright © 2016 Romain Huet. All rights reserved.
//

import Alamofire
import Stripe
import FirebaseDatabase
import FirebaseAuth

class MainAPIClient: NSObject, STPEphemeralKeyProvider {

    static let shared = MainAPIClient()

    var baseURLString = "https://us-central1-goapp-1039a.cloudfunctions.net"

    // MARK: STPEphemeralKeyProvider

    enum CustomerKeyError: Error {
        case missingBaseURL
        case invalidResponse
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        
        let ref = Database.database().reference()
        
        
        
        let endpoint = "/createEphemeralKeys"
        print("Create customer key with api " + apiVersion )
        guard
            !baseURLString.isEmpty,
            let baseURL = URL(string: baseURLString),
            let url = URL(string: endpoint, relativeTo: baseURL) else {
                print("completion customer key error")
                completion(nil, CustomerKeyError.missingBaseURL)
                return
        }
        print("current user id " + (Auth.auth().currentUser?.uid)!)
        ref.child("Stripe").child((Auth.auth().currentUser?.uid)!).queryOrderedByKey().queryEqual(toValue: "customerId").observeSingleEvent(of: .childAdded) { (snapshot) in
            print("customer id " + snapshot.value.debugDescription)
            if let customerId = snapshot.value as? String {
            
                print("creating alamofire request with customerId " + customerId)
                let parameters: [String: Any] = ["api_version": apiVersion, "customerId": customerId]
                
                Alamofire.request(url, method: .post, parameters: parameters).responseJSON { (response) in
                    guard let json = response.result.value as? [AnyHashable: Any] else {
                        print("completion invalid response " + url.absoluteString + " api " + apiVersion)
                        completion(nil, CustomerKeyError.invalidResponse)
                        return
                    }
                    print("request complete " + json.debugDescription)
                    completion(json, nil)
                }
            }
        }
        
        
    }

}
