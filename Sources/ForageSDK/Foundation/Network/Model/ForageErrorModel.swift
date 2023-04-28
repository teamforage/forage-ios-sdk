//
//  ForageServiceError.swift
//  ForageSDK
//
//  Created by Symphony on 24/11/22.
//

import Foundation

internal struct ForageServiceError: Error, Codable {
    let path: String
    let errors: [ForageApiError]
}

internal struct ForageApiError: Codable {
    let code: String
    let message: String
    let source: ForageErrorSource?
}

internal struct ForageErrorSource: Codable {
    let resource: String
    let ref: String
}

public struct ForageError: Error, Codable {
    public let errors: [ForageErrorObj]
}

public struct ForageErrorObj: Codable {
    public let httpStatusCode: Int
    public let code: String
    public let message: String
}
