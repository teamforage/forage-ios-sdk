//
//  Environment.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-23.
//

import Foundation

internal func isUnitTesting() -> Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

public enum Environment: String {
    case dev = "dev"
    case staging = "staging"
    case sandbox = "sandbox"
    case cert = "cert"
    case prod = "prod"
    
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
}

/// Maps a session token to the corresponding environment.
/// Returns `Environment.sandbox` if the token is invalid.
///
/// - Parameter sessionToken: The session token to be converted.
/// - Returns: The corresponding `Environment` value.
public func sessionTokenToEnv(_ sessionToken: String?) -> Environment {
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
