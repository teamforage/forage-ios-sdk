//
//  ForageBalanceModel.swift
//  SampleForageSDK
//
//  Created by Symphony on 31/10/22.
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

internal enum BalanceStatus: String, Codable {
    case sentToProxy = "sent_to_proxy"
    case completed = "completed"
}

internal struct MessageResponse: Codable {
    let contentId: String
    let messageType: String
    let status: BalanceStatus
    let failed: Bool
    let errors: [String]
    
    private enum CodingKeys : String, CodingKey {
        case contentId = "content_id"
        case messageType = "message_type"
        case status
        case failed
        case errors
    }
}
