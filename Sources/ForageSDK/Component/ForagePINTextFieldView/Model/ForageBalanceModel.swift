//
//  ForageBalanceModel.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import Foundation

public struct ForageBalanceModel: Codable {
    public let snap: String
    public let nonSnap: String
    
    private enum CodingKeys : String, CodingKey {
        case snap
        case nonSnap = "non_snap"
    }
}
