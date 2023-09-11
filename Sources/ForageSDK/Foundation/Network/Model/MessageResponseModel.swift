//
//  MessageResponseModel.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 10/11/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

internal struct ForageSQSError: Codable {
    let statusCode: Int
    let forageCode: String
    let message: String
    let details: ForageErrorDetails?
    
    private enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case forageCode = "forage_code"
        case message
        case details
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contentId = try container.decode(String.self, forKey: .contentId)
        messageType = try container.decode(String.self, forKey: .messageType)
        status = try container.decode(String.self, forKey: .status)
        failed = try container.decode(Bool.self, forKey: .failed)

        do {
            errors = try container.decode([ForageSQSError].self, forKey: .errors)
        } catch {
            errors = []  // If the 'errors' field isn't an array, set it to an empty array
        }
    }
}
