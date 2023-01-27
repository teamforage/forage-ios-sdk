//
//  File.swift
//  
//
//  Created by Danny Leiser on 1/26/23.
//

import Foundation

public struct Balance: Codable {
    let snap: Double
    let nonSnap: Double
    
    private enum CodingKeys: String, CodingKey {
        case nonSnap = "non_snap"
        case snap
    }
}

public struct ForageCard: Codable {
    public let last4: String
    public let created: String
    public let state: String?
    public let token: String
    
    private enum CodingKeys : String, CodingKey {
        case last4 = "last_4"
        case token
        case state
        case created
    }
}

/// `ForagePANRequestModel` used for compose request to tokenize Ebt Card
public struct ForagePANResponseModel: Codable {
    public let paymentMethodIdentifier: String
    public let type: String
    public let balance: Balance?
    public let card: ForageCard
    
    private enum CodingKeys : String, CodingKey {
        case paymentMethodIdentifier = "ref"
        case type
        case card
        case balance
    }
}
