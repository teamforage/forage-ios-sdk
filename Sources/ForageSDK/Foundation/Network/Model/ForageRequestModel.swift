//
//  ForageRetrieveModel.swift
//  ForageSDK
//
//  Created by Symphony on 16/11/22.
//

import Foundation

internal struct ForageRequestModel {
    let authorization: String
    let paymentMethodReference: String
    let paymentReference: String
    let cardNumberToken: String
    let merchantID: String
    let xKey: String
}
