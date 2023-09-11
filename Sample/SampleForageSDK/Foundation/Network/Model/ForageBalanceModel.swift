//
//  ForageBalanceModel.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 31/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

public struct ForageBalance: Codable {
    public let balance: ForageBalanceModel
}

public struct ForageBalanceModel: Codable {
    public let snap: String
    public let nonSnap: String
    public let updated: String
    
    private enum CodingKeys : String, CodingKey {
        case snap
        case nonSnap = "non_snap"
        case updated
    }
}
