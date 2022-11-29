//
//  ForageTestsModel.swift
//  ForageSDK
//
//  Created by Symphony on 29/11/22.
//

import UIKit

// MARK: Tokenize card

public struct ForageCard: Codable {
    public let last4: String
    public let token: String
    
    private enum CodingKeys : String, CodingKey {
        case last4 = "last_4"
        case token
    }
}

public struct ForagePANModel: Codable {
    public let paymentMethodIdentifier: String
    public let type: String
    public let card: ForageCard
    
    private enum CodingKeys : String, CodingKey {
        case paymentMethodIdentifier = "ref"
        case type
        case card
    }
}

// MARK: Balance

public struct ForageBalanceModel: Codable {
    public let snap: String
    public let nonSnap: String
    public let updated: String
    
    private enum CodingKeys : String, CodingKey {
        case snap
        case nonSnap = "non_snap"
        case updated
    }
}

// MARK: Capture payment

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
