//
//  Environment.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

func isUnitTesting() -> Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

public enum Environment: String {
    case dev
    case staging
    case sandbox
    case cert
    case prod

    /// Returns the corresponding hostname for the environment.
    public var hostname: String {
        switch self {
        case .dev: return "api.dev.joinforage.app"
        case .staging: return "api.staging.joinforage.app"
        case .sandbox: return "api.sandbox.joinforage.app"
        case .cert: return "api.cert.joinforage.app"
        case .prod: return "api.joinforage.app"
        }
    }

    /// Maps a session token to the corresponding environment.
    /// Defaults to `Environment.sandbox` if the token is invalid.
    ///
    /// - Parameter sessionToken: The session token to be converted.
    init(sessionToken: String? = "") {
        self = sessionTokenToEnv(sessionToken)
    }
}

/// Maps a session token to the corresponding environment.
/// Returns `Environment.sandbox` if the token is invalid.
///
/// - Parameter sessionToken: The session token to be converted.
/// - Returns: The corresponding `Environment` value.
private func sessionTokenToEnv(_ sessionToken: String?) -> Environment {
    guard let sessionToken = sessionToken, !sessionToken.isEmpty else {
        return Environment.sandbox
    }
    let parts = sessionToken.split(separator: "_")
    guard !parts.isEmpty else {
        return Environment.sandbox
    }
    let prefix = String(parts[0])
    return Environment(rawValue: prefix) ?? Environment.sandbox
}
