//
//  ExpressApplePay.swift
//  Sample
//
//  Created by Zohaib Kambrani on 23/01/2023.
//

import Foundation
import PassKit

public class ExpressPayShippingAddress{
    var name:String?
    var address:String?
    var email:String?
    var phone:String?
    
    init(name:String?, address:String?, email:String?, phone:String?) {
        self.name  = name
        self.address  = address
        self.email  = email
        self.phone  = phone
    }

}

fileprivate var _onAuthentication:((PKPayment) -> Void)?
fileprivate var _onTransactionSuccess:(([String:Any]?) -> Void)?
fileprivate var _onTransactionFailure:(([String:Any]) -> Void)?
fileprivate var _onError:(([String]) -> Void)!

fileprivate var _payer:ExpressPayPayer!
fileprivate var _order:ExpressPaySaleOrder!

public class ExpressApplePay{
    public init() {
        
    }
    
    private let request = PKPaymentRequest()
    private var purchaseItems:[PKPaymentSummaryItem] = []
    
    private var applePayMerchantID:String?
    private var shippingAddress:ExpressPayShippingAddress?
    private var supportedPaymentNetworks:[PKPaymentNetwork] = []
    private var merchantCapability:PKMerchantCapability = PKMerchantCapability.capability3DS
    
    
    
    private func start(target:UIViewController, onError:@escaping ((Any) -> Void), onPresent:(() ->Void)?){
        _onError = onError
        
        if isApplePaySupported(){
            let validation = validate()
            if validation.valid{
                
                let request = preparePayment(request:PKPaymentRequest())
                
                if let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request){
                    applePayController.delegate = prepareDelegate(target: target, expressApplePay: self)
                    target.present(applePayController, animated: true, completion: onPresent)
                }else{
                    _onError?(["Error initializing 'PKPaymentAuthorizationViewController(paymentRequest:)'"])
                }
                
            }else{
                _onError?(validation.validationErrors)
            }

            return
        }
        
        
        if supportedPaymentNetworks.isEmpty{
            _onError?(["Cannot start apple pay, device may not supported or user/merchant is restricted from authorizing payments"])
        }else{
            _onError?(["Cannot start apple pay with your defined supported payment networks"])
        }
    }
    
    func isApplePaySupported() -> Bool{
        if supportedPaymentNetworks.isEmpty{
            return PKPaymentAuthorizationViewController.canMakePayments()
        }
        
        return PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedPaymentNetworks)
    }
    
    private func preparePayment(request:PKPaymentRequest) -> PKPaymentRequest{
        request.merchantIdentifier = applePayMerchantID!
        request.merchantCapabilities = merchantCapability
        
        request.countryCode = _order.country
        request.currencyCode = _order.currency
        
        request.paymentSummaryItems = purchaseItems
        if purchaseItems.isEmpty{
            let label = (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? _order.description
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: _order.amount), type: .final)
            ]
        }
        
        request.supportedNetworks = supportedPaymentNetworks
        if supportedPaymentNetworks.isEmpty{
            request.supportedNetworks = PKPaymentRequest.availableNetworks()
        }
        
        return request
    }
    
    private func prepareDelegate(target:UIViewController, expressApplePay:ExpressApplePay) -> ExpressApplePayDelegate{
        let delegate = ExpressApplePayDelegate()
        // Required to PKPaymentAuthorizationViewControllerDelegate to work (should be implemented by UIViewController)
        // * done due to provide the very coding efforts to customer to start applepay in thier application *
        delegate.view.isHidden = true
        target.addChild(delegate)
        
        return delegate
    }
}


// Payment Properties Setters
extension ExpressApplePay{
    
    public func initialize(target:UIViewController, onError:@escaping ((Any) -> Void), onPresent:(() ->Void)?){
        start(target: target, onError: onError, onPresent: onPresent)
    }
    
    public func on(authentication:@escaping ((PKPayment) -> Void)) -> ExpressApplePay{
        _onAuthentication = authentication
        return self
    }
    
    public func on(transactionSuccess:@escaping (([String:Any]?) -> Void)) -> ExpressApplePay{
        _onTransactionSuccess = transactionSuccess
        return self
    }
    
    public func on(transactionFailure:@escaping (([String:Any]) -> Void)) -> ExpressApplePay{
        _onTransactionFailure = transactionFailure
        return self
    }
    
    public func set(applePayMerchantID:String) -> ExpressApplePay{
        self.applePayMerchantID = applePayMerchantID
        return self
    }
    
    public func set(payer:ExpressPayPayer) -> ExpressApplePay{
        _payer = payer
        return self
    }
    
    public func set(order:ExpressPaySaleOrder) -> ExpressApplePay{
        _order = order
        return self
    }
    
    public func set(shippingAddress:ExpressPayShippingAddress) -> ExpressApplePay{
        self.shippingAddress = shippingAddress
        return self
    }
    
    public func set(merchantCapability:PKMerchantCapability) -> ExpressApplePay{
        self.merchantCapability = merchantCapability
        return self
    }
    
    public func addSupported(paymentNetworks:[PKPaymentNetwork]) -> ExpressApplePay{
        self.supportedPaymentNetworks = paymentNetworks
        return self
    }
    
    public func addPurchaseItem(label:String, amount:Double, type:PKPaymentSummaryItemType) -> ExpressApplePay{
        purchaseItems.append(PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amount), type: type))
        return self
    }
}


// Payment Properties Validator
private extension ExpressApplePay{
    func validate() -> (valid:Bool, validationErrors:[String] ){
        var errors:[String] = []
        var valid = true
        
        
        if _onTransactionSuccess == nil{
            valid = valid && false
            errors.append("onTransactionFailure not set, try to call function 'ExpressApplePay.on(transactionSuccess:)'")
        }
        
        if _onTransactionFailure == nil{
            valid = valid && false
            errors.append("onTransactionFailure not set, try to call function 'ExpressApplePay.on(transactionFailure:)'")
        }
        
        if applePayMerchantID == nil || applePayMerchantID!.isEmpty{
            valid = valid && false
            errors.append("Missing or invalid apple pay 'merchant identifier'")
        }
        
        if !(_order.amount > 1){
            valid = valid && false
            errors.append("Missing or invalid amount should be greater than 1.00")
        }
        
        if _order.currency.isEmpty{
            valid = valid && false
            errors.append("Missing or invalid currency code (example: 'SAR' for Saudi Riyal)")
        }
        
        if _order.country.isEmpty{
            valid = valid && false
            errors.append("Missing or invalid country code (example:'SA' for SaudiArabia)")
        }
        
        return (valid, errors)
    }
}


fileprivate class ExpressApplePayDelegate : UIViewController, PKPaymentAuthorizationViewControllerDelegate{
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        _onAuthentication?(payment)
        startPurchase(payment: payment) { (success, response) in
            let result = PKPaymentAuthorizationResult(
                status: success ? .success : .failure,
                errors: nil
            )
            
            if #available(iOS 16.0, *) {
                result.orderDetails = nil
            } else {
                
            }
            
            if success{
                _onTransactionSuccess?(response)
            }else{
                _onTransactionFailure?(response)
            }
            completion(result)
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}



// Initiate Purchase
fileprivate func startPurchase(payment:PKPayment, completion:@escaping ((Bool,[String:Any])->Void)){
    
    let requestHash = ExpressPayHashUtil.hashVirtualPurchaseOrder(
        number: _order.id,
        amount:  _order.formatedAmountString(),
        currency: _order.currency,
        description: _order.description
    )
    
    if let _requestHash = requestHash, let applePayVirtualPurchaseData = ApplePayVirtualPurchase(payment: payment, payer: _payer).getData(){
        
        
        let merchant_key = ExpressPaySDK.shared.credentials.clientKey

        let sessionRequestObject = VirtualPurchaseSession(
            hash: _requestHash,
            method: "applepay",
            merchant_key: merchant_key,
            success_url: "https://pay.expresspay.sa",
            cancel_url: "https://pay.expresspay.sa",
            order: _order,
            customer: _payer
        )
        
        createSession(sessionRequest: sessionRequestObject) { token in
            if let token_ = token{
                
                var request = URLRequest(url: URL(string: "https://pay.expresspay.sa/processing/purchase/virtual")!)
                request.httpMethod = "POST"
                request.httpBody = applePayVirtualPurchaseData
                request.allHTTPHeaderFields = [
                    "X-User-Agent": "ios.com.expresspay.sdk",
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "Token": token_,
                ]
                
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    DispatchQueue.main.async {
                        let resp = ExpressPayDataResponse(data: data, response: response, error: error)
                        if resp.httpOK(), let json = resp.json(){
                            completion(json["result"] as? String == "success", json)
                            return
                        }
                        
                        completion(false, ["error" : "Error while create expresspay auth session token for '../purchase'"])
                    }
                }.resume()
                
            }else{
                completion(false, ["error" : "Error while create expresspay auth session token for '../purchase'"])
            }
        }
    }else{
        completion(false, ["error" : "Invalid request data"])
    }

}




// Initiate Purchase
fileprivate func createSession(sessionRequest:VirtualPurchaseSession, completion:@escaping ((String?)->Void)){
    
    var request = URLRequest(url: URL(string: "https://pay.expresspay.sa/api/v1/session")!)
    request.httpMethod = "POST"
    request.httpBody = sessionRequest.data()
    request.allHTTPHeaderFields = [
        "X-User-Agent": "ios.com.expresspay.sdk",
        "Accept": "application/json",
        "Content-Type": "application/json",
    ]
    
    
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        DispatchQueue.main.async {
            let resp = ExpressPayDataResponse(data: data, response: response, error: error)
            if resp.httpOK(), let redirect_url = resp.json()?["redirect_url"] as? String,
               let url = URL(string: redirect_url){
                completion(url.lastPathComponent)
                return
            }
            
            completion(nil)
        }
    }.resume()

}


extension PKPaymentMethodType{
    func name() -> String{
        switch(self){
        case .unknown: return "unknown"
        case .debit: return "debit"
        case .credit: return "credit"
        case .prepaid: return "prepaid"
        case .store: return "store"
        case .eMoney: return "eMoney"
        default: return "unknown"
        }
    }
}