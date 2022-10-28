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
    
    var paymentMethodReference: String = ""
    var cardNumberToken: String = ""
    var merchantID: String = ""
    var bearerToken: String = ""
    var paymentReference: [FundingType : String] = [:]
}
