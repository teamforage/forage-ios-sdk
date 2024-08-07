//
//  LDManager.swift
//
//
//  Created by Danny Leiser on 5/11/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation
import LaunchDarkly

protocol LDClientProtocol {
    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double
}

extension LDClient: LDClientProtocol {
    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double {
        doubleVariation(forKey: key, defaultValue: defaultValue)
    }
}

protocol LDManagerProtocol {
    func getVaultType(ldClient: LDClientProtocol?, genRandomDouble: () -> Double) -> VaultType
}

/**
 LD Public Keys
 */
private enum LDMobileKey: String {
    case sandbox = "mob-22024b85-05b7-4e24-b290-a071310dfc3d"
    case cert = "mob-d2261a08-784b-4300-a45f-ce0e46324d66"
    case prod = "mob-5c3dfa7a-fa6d-4cdf-93e8-d28ef8080696"
    case staging = "mob-a9903698-759b-48e2-86e1-c551e2b69118"
    case dev = "mob-03e025cb-5b4e-4d97-8685-39a22316d601"
}

/**
 Vault Types
 */
enum VaultType: String {
    case basisTheory = "basis_theory"
    case forage
}

/**
 Flag Types
 */
enum FlagType: String {
    case rosettaTrafficPercentage = "rosetta-traffic-percentage"
}

/**
 LaunchDarkly prefix
 */
private let LAUNCH_DARKLY_PREFIX = "LaunchDarkly"

/**
 Contexts
 */
private enum ContextKey: String {
    case iosSdk = "ios-sdk-service"
}

private enum ContextKind: String {
    case service
}

/// `LDManager` is responsible for managing interactions with the LaunchDarkly service.
///
/// - Note: This class is a singleton and should be accessed via `LDManager.shared`.
class LDManager: LDManagerProtocol {
    // MARK: - Properties

    static let shared = LDManager()
    private var logger: ForageLogger?

    // MARK: - Initialization

    private init() {}

    /// Initializes the LaunchDarkly client with a given environment and optional logger.
    ///
    /// - Parameters:
    ///   - environment: The `EnvironmentTarget` to be used for initialization.
    ///   - logger: An optional `ForageLogger` for logging purposes.
    ///   - startLdClient: A closure to start the LaunchDarkly client. Defaults to `LDClient.start`.
    func initialize(
        _ environment: Environment,
        logger: ForageLogger? = nil,
        startLdClient: (LDConfig, LDContext?, (() -> Void)?) -> Void = LDClient.start
    ) {
        self.logger = logger?.setPrefix(LAUNCH_DARKLY_PREFIX)

        let ldConfig = createLDConfig(for: environment)

        guard let ldContext = createLDContext() else {
            self.logger?.error("Failed to create LaunchDarkly context", error: nil, attributes: nil)
            return
        }

        startLdClient(ldConfig, ldContext) { [weak self] in
            self?.logger?.info("Initialized LaunchDarkly client", attributes: nil)
        }
    }

    /// Determines the type of vault to be used based on the "vault-primary-traffic-percentage" feature flag.
    /// Defaults to Forage if something goes wrong (ex: LDClient not initialized, LaunchDarkly is down).
    ///
    /// - Parameters:
    ///   - ldClient: An optional `LDClientProtocol` object used to fetch feature flags. Defaults to `getDefaultLDClient()`.
    ///   - genRandomDouble: A closure that returns a random double between 0 and 100. Defaults to `generateRandomDouble`.
    ///
    /// - Returns: The determined `VaultType`.
    func getVaultType(
        ldClient: LDClientProtocol?,
        genRandomDouble: () -> Double
    ) -> VaultType {
        logger = logger?.setPrefix(LAUNCH_DARKLY_PREFIX)

        guard let ld = ldClient else {
            logger?.error("Defaulting to Forage. LDClient.get() was called before init()!",
                          error: nil,
                          attributes: nil)
            return .forage
        }

        // Fetch the vault percentage from LaunchDarkly
        let rosettaPercentage = ld.doubleVariationWrapper(
            forKey: FlagType.rosettaTrafficPercentage.rawValue,
            defaultValue: 100.0
        )

        logger?.info("Evaluated \(FlagType.rosettaTrafficPercentage) = \(rosettaPercentage)%",
                     attributes: nil)

        let randomNum = genRandomDouble()
        let vaultType: VaultType = (randomNum <= rosettaPercentage) ? .forage : .basisTheory

        logVaultType(vaultType)

        return vaultType
    }

    private func createLDConfig(for environment: Environment) -> LDConfig {
        LDConfig(mobileKey: getLDMobileKey(environment).rawValue, autoEnvAttributes: .enabled)
    }

    private func createLDContext() -> LDContext? {
        var ldContextBuilder = LDContextBuilder(key: ContextKey.iosSdk.rawValue)
        ldContextBuilder.kind(ContextKind.service.rawValue)
        guard case let .success(context) = ldContextBuilder.build() else {
            return nil
        }
        return context
    }

    private func logVaultType(_ vaultType: VaultType? = nil) {
        guard let vaultType = vaultType else {
            // this shouldn't happen, but we log here in case something went really wrong
            logger?.error("Vault type was not set!", error: nil, attributes: nil)
            return
        }

        _ = logger?
            .addContext(ForageLogContext(
                vaultType: vaultType
            ))
            .notice("Using \(vaultType.rawValue)", attributes: nil)
    }

    static func getDefaultLDClient() -> LDClientProtocol? {
        LDClient.get()
    }

    static func generateRandomDouble() -> Double {
        Double.random(in: 0...100)
    }

    private func getLDMobileKey(_ environment: Environment) -> LDMobileKey {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }
}
