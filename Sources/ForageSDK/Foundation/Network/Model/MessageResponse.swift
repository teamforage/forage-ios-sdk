//
//  MessageResponseModel.swift
//  ForageSDK
//
//  Created by Symphony on 10/11/22.
//

import Foundation

internal enum BalanceStatus: String, Codable {
    case sentToProxy = "sent_to_proxy"
    case completed = "completed"
}

internal struct MessageResponseModel: Codable {
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
