//
//  File.swift
//  
//
//  Created by Danny Leiser on 1/26/23.
//

import Foundation

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
    
    private enum CodingKeys : String, CodingKey {
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
    
    private enum CodingKeys : String, CodingKey {
        case paymentMethodIdentifier = "ref"
        case type
        case card
        case balance
        case customerID = "customer_id"
        case reusable
    }
}
