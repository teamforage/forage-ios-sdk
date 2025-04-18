//
//  ServiceError.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 23/10/22.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import Foundation

enum ServiceError: String, Error {
    case parametersNil = "Parameters were nil."
    case encodingFailed = "Parameters encoding failed."
    case missingURL = "URL is nil."
    case notPossibleRetrieve = "Could not retrieve data."
    case parseError = "Parse error."
    case emptyError = "Empty error model."
}
