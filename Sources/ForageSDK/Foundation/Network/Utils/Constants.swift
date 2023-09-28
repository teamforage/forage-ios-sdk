//
//  File.swift
//  
//
//  Created by Danny Leiser on 9/28/23.
//

import Foundation

struct CommonErrors {
    static let INCOMPLETE_PIN_ERROR = ForageError(errors: [
        ForageErrorObj(
            httpStatusCode: 400,
            code: "user_error",
            message: "Invalid EBT Card PIN entered. Please enter your 4-digit PIN."
        )
    ])
}
