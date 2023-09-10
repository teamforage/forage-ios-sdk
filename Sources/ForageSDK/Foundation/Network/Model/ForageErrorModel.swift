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

/// Represents an error that occurs when a request to submit a `ForageElement` to the Forage API fails.
public struct ForageError: Error, Codable {
    /// An array of error objects returned from the Forage API.
    public let errors: [ForageErrorObj]
}

/// Contains additional details about a Forage API error.
/// 
public enum ForageErrorDetails: Codable {
    /// Used for displaying SNAP and EBT Cash balances when an insufficient funds error occurs.
    ///
    /// - Important: Typically used when the error code is [ebt_error_51](https://docs.joinforage.app/reference/errors#ebt_error_51)
    case insufficientFunds(snapBalance: String?, cashBalance: String?)
    
    /// Received a malformed details object from the Forage API
    case invalid
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let details = try? container.decode(InsufficientFundsDetails.self) {
            self = .insufficientFunds(snapBalance: details.snapBalance, cashBalance: details.cashBalance)
            return
        }
        
        self = .invalid
    }
}

public struct InsufficientFundsDetails: Codable {
    public let snapBalance: String?
    
    public let cashBalance: String?
    
    private enum CodingKeys : String, CodingKey {
        case snapBalance = "snap_balance"
        case cashBalance = "cash_balance"
    }
}

/// Represents a detailed error object returned by the Forage API.
/// Provides additional context about the HTTP status, error code, and developer-facing message.
/// [Learn more about SDK errors](https://docs.joinforage.app/reference/errors#sdk-errors)
public struct ForageErrorObj: Codable {
    /// The HTTP status that the Forage API returns in response to the request.
    public let httpStatusCode: Int
    
    /// A short string explaining why the request failed. The error code string corresponds to the HTTP status code.
    /// [Learn more about SDK error codes](https://docs.joinforage.app/reference/errors#code-and-message-pairs-1)
    public let code: String
    
    /// A developer-facing message about the error, not to be displayed to customers.
    public let message: String
    
    /// Additional details about the error, included for your convenience.
    /// Not nil when details are available, e.g. when the error code is [ebt_error_51](https://docs.joinforage.app/reference/errors#ebt_error_51)
    public let details: ForageErrorDetails?
    
    internal init(httpStatusCode: Int, code: String, message: String, details: ForageErrorDetails? = nil) {
        self.httpStatusCode = httpStatusCode
        self.code = code
        self.message = message
        self.details = details
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.httpStatusCode = try container.decode(Int.self, forKey: .httpStatusCode)
        self.code = try container.decode(String.self, forKey: .code)
        self.message = try container.decode(String.self, forKey: .message)
        
        if self.code == "ebt_error_51" {
            self.details = try? container.decode(ForageErrorDetails.self, forKey: .details)
        } else {
            self.details = nil
        }
    }
}
