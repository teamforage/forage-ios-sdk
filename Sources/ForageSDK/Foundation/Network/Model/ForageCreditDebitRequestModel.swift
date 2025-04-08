//
//  ForageCreditDebitRequestModel.swift
//  ForageSDK
//
//  Created by Jerimiah Gazlay
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

/// `ForageCreditDebitRequestModel` used for compose request to tokenize Ebt Card
struct ForageCreditDebitRequestModel: Codable {
    let authorization: String
    let merchantID: String
    let name: String
    let number: String
    let expMonth: Int
    let expYear: Int
    let securityCode: String
    let zipCode: String
    let type: String
    let customerID: String
    let isHSAFSA: Bool
    let reusable: Bool?
}
