//
//  ForageRequestModel.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 16/11/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

/// `ForageRequestModel` used for compose ForageSDK requests
internal struct ForageRequestModel: Codable {
    let authorization: String
    let paymentMethodReference: String
    let paymentReference: String
    let cardNumberToken: String
    let merchantID: String
    let xKey: [String: String]
}
