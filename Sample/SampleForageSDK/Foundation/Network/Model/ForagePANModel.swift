//
//  ForagePANModel.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 31/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

public struct ForageCard: Codable {
    public let last4: String
    public let token: String

    private enum CodingKeys: String, CodingKey {
        case last4 = "last_4"
        case token
    }
}

public struct ForagePANModel: Codable {
    public let paymentMethodIdentifier: String
    public let type: String
    public let card: ForageCard
    public let customerID: String

    private enum CodingKeys: String, CodingKey {
        case paymentMethodIdentifier = "ref"
        case type
        case card
        case customerID = "customer_id"
    }
}
