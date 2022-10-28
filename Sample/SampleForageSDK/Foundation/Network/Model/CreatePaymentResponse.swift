//
//  CreatePaymentResponse.swift
//  SampleForageSDK
//
//  Created by Symphony on 26/10/22.
//

import Foundation

struct CreatePaymentResponse: Codable {
    let fundingType: FundingType
    let paymentMethodIdentifier: String
    let paymentIdentifier: String
    let merchantAccount: String
    let amount: String
    let description: String
    
    private enum CodingKeys : String, CodingKey {
        case fundingType = "funding_type"
        case paymentMethodIdentifier = "payment_method"
        case paymentIdentifier = "ref"
        case merchantAccount = "merchant"
        case amount
        case description
    }
}
