//
//  CreatePaymentResponse.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

struct CreatePaymentResponse: Codable {
    let fundingType: FundingType
    let paymentMethodIdentifier: String
    let paymentIdentifier: String
    let merchantID: String
    let amount: String
    let description: String

    private enum CodingKeys: String, CodingKey {
        case fundingType = "funding_type"
        case paymentMethodIdentifier = "payment_method"
        case paymentIdentifier = "ref"
        case merchantID = "merchant"
        case amount
        case description
    }
}
