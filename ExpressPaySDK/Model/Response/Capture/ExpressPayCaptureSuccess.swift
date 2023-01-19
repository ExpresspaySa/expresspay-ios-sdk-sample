//
//  ExpressPayCaptureSuccess.swift
//  ExpressPaySDK
//
//  Created by ExpressPay(zik) on 08.03.2021.
//

import Foundation

/// The CAPTURE success result of the *ExpressPayCaptureResult*.
/// 
/// See *ExpressPayCaptureResponse*
public struct ExpressPayCaptureSuccess: DetailsExpressPayResultProtocol {
    public let transactionDate: Date
    
    public let descriptor: String?
    
    public let orderAmount: Double
    
    public let orderCurrency: String
    
    public let action: ExpressPayAction
    
    public let result: ExpressPayResult
    
    public let status: ExpressPayStatus
    
    public let orderId: String
    
    public let transactionId: String
}

extension ExpressPayCaptureSuccess: Decodable {
    enum CodingKeys: String, CodingKey {
        case descriptor
        case transactionDate = "trans_date"
        case orderAmount = "amount"
        case orderCurrency = "currency"
        case action
        case result
        case status
        case orderId = "order_id"
        case transactionId = "trans_id"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        orderCurrency = try container.decode(String.self, forKey: .orderCurrency)
        action = try container.decode(ExpressPayAction.self, forKey: .action)
        result = try container.decode(ExpressPayResult.self, forKey: .result)
        status = try container.decode(ExpressPayStatus.self, forKey: .status)
        orderId = try container.decode(String.self, forKey: .orderId)
        transactionId = try container.decode(String.self, forKey: .transactionId)
        
        transactionDate = ExpressPayDateFormatter.date(from: try container.decode(String.self, forKey: .transactionDate)) ?? Date()
        orderAmount = Double(try container.decode(String.self, forKey: .orderAmount)) ?? 0
        
        descriptor = try container.decodeIfPresent(String.self, forKey: .descriptor)
    }
}
