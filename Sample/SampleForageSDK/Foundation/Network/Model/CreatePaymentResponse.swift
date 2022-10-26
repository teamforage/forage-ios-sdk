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
    let merchantAccount: String
    let description: String
    let metadata: [String: String]
    let deliveryAddress: Address
    let isDelivery: Bool
}
