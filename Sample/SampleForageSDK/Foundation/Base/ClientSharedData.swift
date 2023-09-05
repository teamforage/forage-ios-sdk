//
//  ClientSharedData.swift
//  SampleForageSDK
//
//  Created by Symphony on 24/10/22.
//

import Foundation
import ForageSDK

class ClientSharedData {
    static let shared = ClientSharedData()
    
    var environment: EnvironmentTarget = .sandbox
    var paymentMethodReference: String = ""
    var merchantID: String = ""
    var sessionToken: String = ""
    var paymentReference: [FundingType : String] = [:]
    // NOTE: The following line is for testing purposes only and should not be used in production.
    // Please replace this line with a real hashed customer ID value.
    var customerID: String = UUID.init().uuidString
    var isReusablePaymentMethod: Bool = true
}
