//
//  ForageCaptureModel.swift
//  SampleForageSDK
//
//  Created by Symphony on 31/10/22.
//

import UIKit

public enum ForageOrderStatus: String, Codable {
    case draft
    case processing
    case failed
    case succeeded
    case canceled
}

public struct ForageCaptureModel: Codable {
    public let paymentIdentifier: String
    public let merchantID: String
    public let fundingType: String
    public let amount: String
    public let description: String
    public let paymentMethodIdentifier: String
    public let deliveryAddress: Address
    public let isDelivery: Bool
    public let createdDate: String
    public let updatedDate: String
    public let status: ForageOrderStatus
    public let successDate: String
    
    private enum CodingKeys : String, CodingKey {
        case paymentIdentifier = "ref"
        case merchantID = "merchant"
        case fundingType = "funding_type"
        case amount
        case description
        case paymentMethodIdentifier = "payment_method"
        case deliveryAddress = "delivery_address"
        case isDelivery = "is_delivery"
        case createdDate = "created"
        case updatedDate = "updated"
        case status
        case successDate = "success_date"
    }
}
