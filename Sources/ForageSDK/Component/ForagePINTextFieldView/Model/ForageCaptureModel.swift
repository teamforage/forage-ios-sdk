//
//  ForageBalanceModel.swift
//  ForageSDK
//
//  Created by Symphony on 27/10/22.
//

import Foundation

public struct ForageCaptureModel: Codable {
    public let fundingType: String
    public let paymentMethodIdentifier: String
    public let paymentIdentifier: String
    public let merchantAccount: String
    public let amount: String
    public let description: String
    
    private enum CodingKeys : String, CodingKey {
        case fundingType = "funding_type"
        case paymentMethodIdentifier = "payment_method"
        case paymentIdentifier = "ref"
        case merchantAccount = "merchant"
        case amount
        case description
    }
}
