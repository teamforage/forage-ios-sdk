//
//  JSONParameterEncoder.swift
//  ForageSDK
//
//  Created by Symphony on 24/11/22.
//

import Foundation

struct ForageServiceError: Error, Codable {
    let path: String
    let errors: [ForageError]
}

struct ForageError: Codable {
    let code: String
    let message: String
    let source: [String : String]?
}

struct ForageErrorSource: Codable {
    let resource: String
    let ref: String
}
