//
//  ClientSharedData.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 24/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation

class ClientSharedData {
    static let shared = ClientSharedData()

    var paymentMethodReference: String = ""
    var merchantID: String = ""
    var sessionToken: String = ""
    var paymentReference: [FundingType: String] = [:]
    // NOTE: The following line is for testing purposes only and should not be used in production.
    // Please replace this line with a real hashed customer ID value.
    var customerID: String = UUID().uuidString
    var isReusablePaymentMethod: Bool = true
}
