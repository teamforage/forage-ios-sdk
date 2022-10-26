//
//  ForageBalanceRequest.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import Foundation

internal struct ForageBalanceRequest {
    let authorization: String
    let paymentReference: String
    let cardNumberToken: String
    let merchantID: String
    let xKey: String
}
