//
//  ForageXKeyModel.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 24/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

/// `ForageXKeyModel` used for compose X-key request
struct ForageXKeyModel: Codable {
    let alias: String
    let bt_alias: String
}
