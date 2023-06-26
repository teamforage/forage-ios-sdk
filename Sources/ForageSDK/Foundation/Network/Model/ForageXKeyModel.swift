//
//  ForageXKeyModel.swift
//  ForageSDK
//
//  Created by Symphony on 24/10/22.
//

import Foundation

/// `ForageXKeyModel` used for compose X-key request
internal struct ForageXKeyModel: Codable {
    let alias: String
    let bt_alias: String
}
