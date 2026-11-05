//
//  MomentErrors.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import Foundation

enum MomentErrors {
    static let MOMENT_ALREADY_OPEN = ForageError.create(
        code: "user_error",
        httpStatusCode: 400,
        message: "A moment is already open. Wait for it to finish before opening another."
    )
    static let INVALID_MOMENT_PARAMS = ForageError.create(
        code: "user_error",
        httpStatusCode: 400,
        message: "Invalid moment params provided. Every param must be a non-empty string."
    )
}
