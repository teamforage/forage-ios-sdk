//
//  ClientSharedData.swift
//  SampleForageSDK
//
//  Created by Symphony on 24/10/22.
//

import Foundation

class ClientSharedData {
    static let shared = ClientSharedData()
    
    var paymentReference: String = ""
    var cardNumberToken: String = ""
    var merchantID: String = ""
    var bearerToken: String = ""
}
