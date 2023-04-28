//
//  MessageResponseModel.swift
//  ForageSDK
//
//  Created by Symphony on 10/11/22.
//

import Foundation

internal struct ForageSQSError: Codable {
    let statusCode: Int
    let forageCode: String
    let message: String
    
    private enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case forageCode = "forage_code"
        case message
    }
}

/// `MessageResponseModel` used for handling message for polling request
internal struct MessageResponseModel: Codable {
    let contentId: String
    let messageType: String
    let status: String
    let failed: Bool
    let errors: [ForageSQSError]
    
    private enum CodingKeys : String, CodingKey {
        case contentId = "content_id"
        case messageType = "message_type"
        case status
        case failed
        case errors
    }
}
