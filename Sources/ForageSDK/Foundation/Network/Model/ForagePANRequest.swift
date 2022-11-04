//
//  ForagePANRequest.swift
//  ForageSDK
//
//  Created by Symphony on 20/10/22.
//

import Foundation

internal struct ForagePANRequest {
    let authorization: String
    let merchantAccount: String
    let panNumber: String
    let type: String
    let reusable: Bool
}
