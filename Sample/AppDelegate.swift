//
//  AppDelegate.swift
//  Sample
//
//  Created by ExpressPay(zik) on 10.03.2021.
//

import UIKit
import ExpressPaySDK

/*

 // Express Pay
// -----------------
ClientKey b5abdab4-5c46-11ed-a7be-8e03e789c25f
ClientPass: f922737e44c04144f8abb092f1f31049
PaymentUrl: https://api.expresspay.sa/post
 
*/

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // https://github.com/yassram/YRPayment
        let expressPayCredential = ExpressPayCredential(
            clientKey: "58e9490c-842c-11ed-a834-7663276044b1",
            clientPass: "699780707e6b2351a8337883a2a3d4ac",
            paymentUrl: "https://api.expresspay.sa/post"
        )
        
        ExpressPaySDK.config(expressPayCredential)
        
        return true
    }
}