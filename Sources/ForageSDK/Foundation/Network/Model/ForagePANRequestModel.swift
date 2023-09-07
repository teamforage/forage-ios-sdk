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
    let merchantID: String
    let panNumber: String
    let type: String
    let customerID: String
    let reusable: Bool?
}
