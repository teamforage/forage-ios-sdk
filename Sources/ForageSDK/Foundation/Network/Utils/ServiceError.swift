//
//  ServiceError.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 23/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

internal enum ServiceError: String, Error {
    case parametersNil = "Parameters were nil."
    case encodingFailed = "Parameters encoding failed."
    case missingURL = "URL is nil."
    case notPossibleRetrieve = "Could not retrieve data."
    case parseError = "Parse error."
    case emptyError = "Empty error model."
}
