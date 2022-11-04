//
//  ForageBalanceModel.swift
//  SampleForageSDK
//
//  Created by Symphony on 31/10/22.
//

import Foundation

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

