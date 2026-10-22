//
//  Moment.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import Foundation

/// A Forage-hosted page that the SDK opens to complete one task with the customer,
/// like entering their EBT Card PIN. Open one with ``ForageSDK/createMoment(_:presentingFrom:completion:)``.
public enum Moment {
    /// Collects the customer's EBT Card PIN for a payment.
    ///
    /// - Parameter paymentRef: The reference of the `Payment` to collect the PIN for.
    case paymentCollectPin(paymentRef: String)

    /// The moment's name in the moments protocol, shared with the JS and Android SDKs.
    var name: String {
        switch self {
        case .paymentCollectPin: return "payment_collect_pin"
        }
    }

    /// The path of the moment's page on its service.
    var path: String {
        switch self {
        case .paymentCollectPin: return "/payment/collect-pin"
        }
    }

    /// The moment's params, which go in its URL. Never put secrets here.
    var params: [String: String] {
        switch self {
        case let .paymentCollectPin(paymentRef): return ["paymentRef": paymentRef]
        }
    }
}

/// How a moment ended, when it didn't fail.
public enum MomentResult: Equatable {
    /// The customer completed the moment.
    case completed

    /// The customer closed the moment without completing it.
    case dismissed
}

extension Environment {
    /// The origin of custom-checkout, the service that hosts moments.
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
    // only Forage's internal environments can use the override, so it does nothing for
    // sandbox and prod tokens however a merchant reaches it
    let canOverride = environment == .dev || environment == .local
    let origin = (canOverride ? baseURLOverride?.absoluteString : nil) ?? environment.customCheckoutOrigin
    guard var components = URLComponents(string: origin) else { return nil }
    components.path = moment.path
    components.queryItems = moment.params
        .sorted { $0.key < $1.key }
        .map { URLQueryItem(name: $0.key, value: $0.value) }
    return components.url
}
