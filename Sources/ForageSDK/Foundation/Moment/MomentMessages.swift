//
//  MomentMessages.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import Foundation

enum MomentProtocol {
    /// These need to match what the internal JS SDK expects
    static let messageHandlerName = "forageSdk"
    static let receiveFunctionName = "forageSdkReceive"
    static let sdkName = "forage-ios-sdk"
    
    static let loadDeadline: TimeInterval = 30
    static let loadTimeoutError = ForageError.create(
        code: "timeout_error",
        httpStatusCode: 504,
        message: "The moment didn't load in time. Try again later."
    )
}

enum MomentEvent: Equatable {
    case hello
    case ready
    case success
    case failure(ForageError)
    case closed

    /// Parses a message the page posted, or returns `nil` for messages that aren't valid
    /// or that this SDK doesn't know about.
    ///
    /// - Parameter body: The body of the message sent from the page's javascript (a JSON string)
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
        // ignore events we don't recognize so if we don't cause issuse if we add a new one from
        // the embedded page
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
/// The message is sent to the page as a JSON string.
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

func javaScriptStringLiteral(_ string: String) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .withoutEscapingSlashes
    guard let data = try? encoder.encode(string) else { return nil }
    return String(decoding: data, as: UTF8.self)
}
