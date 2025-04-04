//
//  PaymentMethodModel.swift
//
//
//  Created by Danny Leiser on 1/26/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

struct RawBalanceResponseModel: Codable {
    let ref: String?
    let balance: BalanceModel?
    let error: VaultError?
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

/// `ForageEBTCard` used to represent a tokenized EBT card
public struct ForageEBTCard: Codable {
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

/// `PaymentMethodModel` used to represent a tokenized payment method
public struct PaymentMethodModel<TCard: Codable>: Codable {
    public let paymentMethodIdentifier: String
    public let type: String
    public let balance: BalanceModel?
    public let card: TCard
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
