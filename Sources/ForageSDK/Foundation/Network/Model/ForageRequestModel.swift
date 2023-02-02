//
//  ForageRetrieveModel.swift
//  ForageSDK
//
//  Created by Symphony on 16/11/22.
//

import Foundation

/// `ForageRequestModel` used for compose ForageSDK requests
internal struct ForageRequestModel: Codable {
    let authorization: String
    let paymentMethodReference: String
    let paymentReference: String
    let cardNumberToken: String
    let merchantID: String
    let xKey: String
}
