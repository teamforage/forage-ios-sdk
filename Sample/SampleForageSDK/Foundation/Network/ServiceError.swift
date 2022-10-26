//
//  ServiceError.swift
//  SampleForageSDK
//
//  Created by Symphony on 26/10/22.
//

import Foundation

internal enum ServiceError: String, Error {
    case parametersNil = "Parameters were nil."
    case encodingFailed = "Parameters encoding failed."
    case missingURL = "URL is nil."
    case notPossibleRetrieve = "Could not retrieve data."
    case parseError = "Parse error."
}
