//
//  ForageBalanceModel.swift
//  ForageSDK
//
//  Created by Symphony on 27/10/22.
//

import UIKit

public struct ForageAddress: Codable {
    public let city: String
    public let country: String
    public let line1: String?
    public let line2: String?
    public let zipcode: String
    public let state: String
}

public enum ForageOrderStatus: String, Codable {
    case draft
    case processing
    case failed
    case succeeded
    case canceled
}

public struct ForageCaptureModel: Codable {
    public let paymentIdentifier: String
    public let merchantAccount: String
    public let fundingType: String
    public let amount: String
    public let description: String
    public let paymentMethodIdentifier: String
    public let deliveryAddress: ForageAddress
    public let isDelivery: Bool
    public let createdDate: String
    public let updatedDate: String
    public let status: ForageOrderStatus
    public let successDate: String
    
    private enum CodingKeys : String, CodingKey {
        case paymentIdentifier = "ref"
        case merchantAccount = "merchant"
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
