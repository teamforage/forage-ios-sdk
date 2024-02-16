//
//  PaymentMethodModel.swift
//
//
//  Created by Danny Leiser on 1/26/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

public struct RawBalanceModel: Codable {
    public let ref: String
    public let balance: BalanceModel?
    public let errors: BalanceError?
}

public struct BalanceError: Codable {
    public let message: String
    public let statusCode: Int
    public let forageCode: String
    public let details: TestDetails?
    
    private enum CodingKeys: String, CodingKey {
        case message
        case statusCode = "status_code"
        case forageCode = "forage_code"
        case details
    }
}

public struct TestDetails: Codable {
    public let cashBalance: String?
    public let snapBalance: String?
    
    private enum CodingKeys: String, CodingKey {
        case cashBalance = "cash_balance"
        case snapBalance = "snap_balance"
    }
}

public struct BalanceModel: Codable {
    public let snap: String
    public let cash: String
    public let updated: String

    private enum CodingKeys: String, CodingKey {
        case cash = "non_snap"
        case snap
        case updated
    }
}

public struct ForageCard: Codable {
    public let last4: String
    public let created: String
    public let state: String?
    public let token: String

    private enum CodingKeys: String, CodingKey {
        case last4 = "last_4"
        case token
        case state
        case created
    }
}

/// `PaymentMethodModel` used to represent a tokenized EBT Card
public struct PaymentMethodModel: Codable {
    public let paymentMethodIdentifier: String
    public let type: String
    public let balance: BalanceModel?
    public let card: ForageCard
    public let customerID: String?
    public let reusable: Bool?

    private enum CodingKeys: String, CodingKey {
        case paymentMethodIdentifier = "ref"
        case type
        case card
        case balance
        case customerID = "customer_id"
        case reusable
    }
}
