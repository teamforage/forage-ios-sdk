//
//  ForagePANRequestModel.swift
//  ForageSDK
//
//  Created by Symphony on 20/10/22.
//

import Foundation

/// `ForagePANRequestModel` used for compose request to tokenize Ebt Card
internal struct ForagePANRequestModel: Codable {
    let authorization: String
    let merchantAccount: String
    let panNumber: String
    let type: String
    let reusable: Bool
    let userID: String
}
