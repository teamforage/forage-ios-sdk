//
//  ForageErrorModel.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 24/11/22.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import Foundation

struct ForageServiceError: Error, Codable {
    let path: String
    let errors: [ForageApiError]
}

struct ForageApiError: Codable {
    let code: String
    let message: String
    let source: ForageErrorSource?
}

struct ForageErrorSource: Codable {
    let resource: String
    let ref: String
}

/// Represents an error that occurs when a request to submit a `ForageElement` to the Forage API fails.
public struct ForageError: Error, Codable, Equatable {
    public static func ==(lhs: ForageError, rhs: ForageError) -> Bool {
        lhs.code == rhs.code && lhs.httpStatusCode == rhs.httpStatusCode && lhs.message == rhs.message && lhs.details == rhs.details
    }

    /// A short string that helps identify the cause of the error.
    /// [Learn more about SDK error codes](https://docs.joinforage.app/reference/errors#code-and-message-pairs-1)
    ///
    /// Example: 'ebt_error_55' signifies that a user entered an invalid EBT Card PIN
    public let code: String

    /// The HTTP status that the Forage API returns in response to the request.
    public let httpStatusCode: Int

    /// A developer-facing description of the error.
    public let message: String

    /// Additional details about the error, included for your convenience.
    /// Not nil when details are available, e.g. when the error code is [ebt_error_51](https://docs.joinforage.app/reference/errors#ebt_error_51)
    public let details: ForageErrorDetails?

    /// An array of error objects returned from the Forage API.
    @available(*, deprecated, message: "Access forageError.code directly instead of unpacking the .errors list")
    public let errors: [ForageErrorObj]

    /// Creates a `ForageError` instance with a single `ForageErrorObj` object
    static func create(
        code: String,
        httpStatusCode: Int,
        message: String,
        details: ForageErrorDetails? = nil
    ) -> ForageError {
        let firstErrorObj = ForageErrorObj(
            httpStatusCode: httpStatusCode,
            code: code,
            message: message,
            details: details
        )
        return ForageError(
            code: firstErrorObj.code,
            httpStatusCode: firstErrorObj.httpStatusCode,
            message: firstErrorObj.message,
            details: firstErrorObj.details,
            errors: [firstErrorObj]
        )
    }
}

/// Contains additional details about a Forage API error.
///
public enum ForageErrorDetails: Codable, Equatable {
    /// Use this to display the SNAP and EBT Cash balances when an [ebt_error_51](https://docs.joinforage.app/reference/errors#ebt_error_51) error occurs
    case ebtError51(snapBalance: String?, cashBalance: String?)

    /// Received a malformed details object from the Forage API
    case invalid
    
    public init(ebtError51 details: EbtError51Details) {
        self = .ebtError51(snapBalance: details.snapBalance, cashBalance: details.cashBalance)
    }


    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let details = try? container.decode(EbtError51Details.self) {
            self.init(ebtError51: details)
            return
        }

        self = .invalid
    }
}

public struct EbtError51Details: Codable {
    public let snapBalance: String?

    public let cashBalance: String?

    private enum CodingKeys: String, CodingKey {
        case snapBalance = "snap_balance"
        case cashBalance = "cash_balance"
    }
}

// Forage API errors received from the vault
// resembles the shape of an SQSError
struct VaultError: Codable {
    public let message: String
    public let statusCode: Int
    public let forageCode: String
    public let details: EbtError51Details?

    private enum CodingKeys: String, CodingKey {
        case message
        case statusCode = "status_code"
        case forageCode = "forage_code"
        case details
    }
}

/// Represents a detailed error object returned by the Forage API.
/// Provides additional context about the HTTP status, error code, and developer-facing message.
/// [Learn more about SDK errors](https://docs.joinforage.app/reference/errors#sdk-errors)
@available(*, deprecated, renamed: "ForageError")
public struct ForageErrorObj: Codable {
    /// The HTTP status that the Forage API returns in response to the request.
    public let httpStatusCode: Int

    /// A short string that helps identify the cause of the error.
    /// [Learn more about SDK error codes](https://docs.joinforage.app/reference/errors#code-and-message-pairs-1)
    ///
    /// Example: 'ebt_error_55' signifies that a user entered an invalid EBT Card PIN
    public let code: String

    /// A developer-facing description of the error.
    public let message: String

    /// Additional details about the error, included for your convenience.
    /// Not nil when details are available, e.g. when the error code is [ebt_error_51](https://docs.joinforage.app/reference/errors#ebt_error_51)
    public let details: ForageErrorDetails?

    init(httpStatusCode: Int, code: String, message: String, details: ForageErrorDetails? = nil) {
        self.httpStatusCode = httpStatusCode
        self.code = code
        self.message = message
        self.details = details
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        httpStatusCode = try container.decode(Int.self, forKey: .httpStatusCode)
        code = try container.decode(String.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)

        if code == "ebt_error_51" {
            details = try? container.decode(ForageErrorDetails.self, forKey: .details)
        } else {
            details = nil
        }
    }
}
