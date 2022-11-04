//
//  ForageCaptureRequest.swift
//  ForageSDK
//
//  Created by Symphony on 31/10/22.
//

import Foundation

internal struct ForageCaptureRequest {
    let authorization: String
    let paymentReference: String
    let cardNumberToken: String
    let merchantID: String
    let xKey: String
}
