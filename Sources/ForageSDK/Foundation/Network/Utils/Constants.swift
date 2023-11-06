//
//  Constants.swift
//
//
//  Created by Danny Leiser on 9/28/23.
//

import Foundation

enum CommonErrors {
    static let INCOMPLETE_PIN_ERROR = ForageError.create(
        httpStatusCode: 400,
        code: "user_error",
        message: "Invalid EBT Card PIN entered. Please enter your 4-digit PIN."
    )
    static let UNKNOWN_SERVER_ERROR = ForageError.create(
        httpStatusCode: 500,
        code: "unknown_server_error",
        message: "Unknown error. This is a problem on Forage’s end."
    )
}
