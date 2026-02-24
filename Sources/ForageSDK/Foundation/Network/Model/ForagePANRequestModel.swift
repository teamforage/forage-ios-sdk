//
//  ForagePANRequestModel.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 20/10/22.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import Foundation

/// `ForagePANRequestModel` used for compose request to tokenize Ebt Card
struct ForagePANRequestModel: Codable {
    let authorization: String
    let merchantID: String
    let panNumber: String
    let type: String
    let customerID: String
    let reusable: Bool?
}
