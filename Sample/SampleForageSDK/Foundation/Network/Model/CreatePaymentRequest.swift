//
//  CreatePaymentRequest.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

struct CreatePaymentRequest {
    let amount: Double
    let fundingType: String
    let paymentMethodIdentifier: String
    let merchantID: String
    let description: String
    let metadata: [String: String]
    let deliveryAddress: Address
    let isDelivery: Bool
    let customerID: String
}
