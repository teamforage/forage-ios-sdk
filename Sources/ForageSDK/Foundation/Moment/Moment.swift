//
//  Moment.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import Foundation

/// A Forage-hosted page that the SDK opens for the customer to complete a task.
public struct Moment {
    let name: String
    let path: String
    let params: [String: String]

    /// Collects the customer's EBT Card PIN for a payment.
    ///
    /// - Parameter paymentRef: The reference of the `Payment` to collect the PIN for.
    public static func paymentCollectPin(paymentRef: String) -> Moment {
        Moment(name: "payment_collect_pin", path: "/payment/collect-pin", params: ["paymentRef": paymentRef])
    }
}

public enum MomentResult: Equatable {
    case completed
    case dismissed
}

extension Environment {
    var customCheckoutOrigin: String {
        switch self {
        case .prod: return "https://custom-checkout.joinforage.app"
        case .local: return "http://custom-checkout.joinforage.localhost"
        case .dev, .staging, .sandbox, .cert: return "https://custom-checkout.\(rawValue).joinforage.app"
        }
    }
}

/// Builds the URL of a moment's page.
///
/// - Parameters:
///   - moment: The moment to open.
///   - environment: The environment of the session token.
///   - baseURLOverride: Only for local development. Replaces the origin from `environment`
///   when it's `dev` or `local`, and is ignored for every other environment.
/// - Returns: The moment's URL, or `nil` if it can't be built.
func momentURL(for moment: Moment, environment: Environment, baseURLOverride: URL? = nil) -> URL? {
    let canOverride = environment == .dev || environment == .local
    let origin = (canOverride ? baseURLOverride?.absoluteString : nil) ?? environment.customCheckoutOrigin
    guard var components = URLComponents(string: origin) else { return nil }
    components.path = moment.path
    components.queryItems = moment.params
        .sorted { $0.key < $1.key }
        .map { URLQueryItem(name: $0.key, value: $0.value) }
    return components.url
}
