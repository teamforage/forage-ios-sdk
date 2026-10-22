//
//  MomentMessages.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import Foundation

/// Names and messages of the moments protocol. They must match the page bridge in
/// fe-monorepo (`hosted-page/platform-messaging.ts`) and the JS and Android SDKs.
enum MomentProtocol {
    /// The name of the script message handler the page posts to.
    static let messageHandlerName = "forageSdk"

    /// The function the page defines for the SDK to send it messages.
    static let receiveFunctionName = "forageSdkReceive"

    static let sdkName = "forage-ios-sdk"

    /// How long the page has to send `input_ready` after the moment opens.
    static let loadDeadline: TimeInterval = 30

    /// Uses `timeout_error`, the same code the Android SDK uses for timeouts.
    static let loadTimeoutError = ForageError.create(
        code: "timeout_error",
        httpStatusCode: 504,
        message: "The moment didn't load in time. Try again later."
    )
}

/// A message from the moment's page.
enum MomentEvent: Equatable {
    case hello
    case ready
    case success
    case failure(ForageError)
    case closed

    /// Parses a message the page posted, or returns `nil` for messages that aren't valid
    /// or that this SDK doesn't know about.
    ///
    /// - Parameter body: The script message's body, which should be a JSON string.
    init?(body: Any) {
        guard
            let json = body as? String,
            let message = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any],
            let type = message["type"] as? String
        else { return nil }

        let payload = message["payload"]

        switch type {
        case "input_hello": self = .hello
        case "input_ready": self = .ready
        case "submit_success": self = .success
        case "submit_failure": self = .failure(MomentEvent.forageError(from: payload))
        case "moment_closed": self = .closed
        // hosts ignore event types they don't know, so pages can add new ones
        default: return nil
        }
    }

    private static func jsonString(from payload: Any?) -> String? {
        guard
            let payload = payload, !(payload is NSNull),
            let data = try? JSONSerialization.data(withJSONObject: payload, options: [.fragmentsAllowed])
        else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    private struct PageError: Decodable {
        let code: String
        let httpStatusCode: Int
        let message: String
    }

    /// A payload that isn't a `ForageError` becomes `unknown_server_error`.
    private static func forageError(from payload: Any?) -> ForageError {
        guard
            let json = jsonString(from: payload),
            let pageError = try? JSONDecoder().decode(PageError.self, from: Data(json.utf8))
        else { return CommonErrors.UNKNOWN_SERVER_ERROR }

        return ForageError.create(
            code: pageError.code,
            httpStatusCode: pageError.httpStatusCode,
            message: pageError.message
        )
    }
}

/// Builds the JavaScript that sends `initialize_iframe` to the page.
///
/// The message is passed to the page's receive function as a JSON string, the same as on Android.
func momentInitializeScript(
    merchantID: String,
    sessionToken: String,
    environment: Environment
) -> String? {
    let message: [String: Any] = [
        "name": "initialize_iframe",
        "payload": [
            "merchantId": merchantID,
            "sessionToken": sessionToken,
            "env": environment.rawValue,
            "usecase": "moment",
            "sdkName": MomentProtocol.sdkName,
            "sdkVersion": ForageSDK.version,
        ],
    ]

    guard
        let messageData = try? JSONSerialization.data(withJSONObject: message),
        let literal = javaScriptStringLiteral(String(decoding: messageData, as: UTF8.self))
    else { return nil }

    return "window.\(MomentProtocol.receiveFunctionName)(\(literal));"
}

/// Encodes a string as a JavaScript string literal, quotes included, so it can't break out of the script.
func javaScriptStringLiteral(_ string: String) -> String? {
    // JSON-encoding a one-element array gives us a correctly escaped string literal
    guard let data = try? JSONSerialization.data(withJSONObject: [string]) else { return nil }
    let array = String(decoding: data, as: UTF8.self)

    return String(array.dropFirst().dropLast())
        // JSON allows these line separators in strings, but older JavaScript engines don't
        .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
        .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
}
