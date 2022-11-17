//
//  ForagePANRequestModel.swift
//  ForageSDK
//
//  Created by Symphony on 20/10/22.
//

import Foundation

internal struct ForagePANRequestModel {
    let authorization: String
    let merchantAccount: String
    let panNumber: String
    let type: String
    let reusable: Bool
}
