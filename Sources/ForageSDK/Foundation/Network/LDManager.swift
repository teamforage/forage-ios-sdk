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
    func jsonVariationWrapper(forKey key: String, defaultValue: LDValue) -> LDValue
}

extension LDClient: LDClientProtocol {
    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double {
        doubleVariation(forKey: key, defaultValue: defaultValue)
    }

    func jsonVariationWrapper(forKey key: String, defaultValue: LDValue) -> LDValue {
        jsonVariation(forKey: key, defaultValue: defaultValue)
    }
}

extension LDValue {
    /// Converts the original LDValue returned from the polling feature flag to an Array of Ints.
    func convertToIntArray() -> [Int] {
        let intervalArrayAsLDValue = extractArray(pollingFlagObj: self)
        let intervalArrayAsArray = convertToArray(pollingArray: intervalArrayAsLDValue)
        return convertArrayValsToInts(arrayOfInts: intervalArrayAsArray)
    }

    /// Inspects the original LDValue returned from the polling feature flag and extracts the value mapped to INTERVALS
    ///
    /// - Parameters:
    ///   - pollingFlagObj: The `LDValue` representing a JSON object.
    func extractArray(pollingFlagObj: LDValue) -> LDValue {
        let defaultLDValueArray = LDValue(arrayLiteral: [])
        switch pollingFlagObj {
        case let .object(dictValue):
            for (key, value) in dictValue {
                if key == INTERVALS {
                    return value
                }
            }
            return defaultLDValueArray
        default:
            return defaultLDValueArray
        }
    }

    /// Converts the LDValue to an Array.
    ///
    /// - Parameters:
    ///   - pollingArray: The `LDValue` representing an Array.
    func convertToArray(pollingArray: LDValue) -> [LDValue] {
        switch pollingArray {
        case let .array(intervalVals):
            return intervalVals
        default:
            return []
        }
    }

    /// Converts an Array of LDValue to an Array of Ints.
    ///
    /// - Parameters:
    ///   - arrayOfInts: The `LDValue` representing an Array of Ints.
    func convertArrayValsToInts(arrayOfInts: [LDValue]) -> [Int] {
        arrayOfInts.map { timeInMs in
            switch timeInMs {
            case let .number(valAsNum):
                return Int(valAsNum)
            default:
                return 1000
            }
        }
    }
}

protocol LDManagerProtocol {
    func getVaultType(ldClient: LDClientProtocol?, genRandomDouble: () -> Double, fromCache: Bool) -> VaultType
    func getPollingIntervals(ldClient: LDClientProtocol?) -> [Int]
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
public enum VaultType: String {
    case vgsVaultType = "vgs"
    case btVaultType = "basis_theory"
}

/**
 Flag Types
 */
private enum FlagType: String {
    case vaultPrimaryTrafficPercentage = "vault-primary-traffic-percentage"
    case isoPollingWaitIntervals = "iso-polling-wait-intervals"
}

/**
 Key value used to grab the dictionary returned by the "iso-polling-wait-intervals" flag
 */
private let INTERVALS = "intervals"

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

    private(set) var vaultType: VaultType?

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
    /// Defaults to VGS if something goes wrong (ex: LDClient not initialized, LaunchDarkly is down).
    ///
    /// - Parameters:
    ///   - ldClient: An optional `LDClientProtocol` object used to fetch feature flags. Defaults to `getDefaultLDClient()`.
    ///   - genRandomDouble: A closure that returns a random double between 0 and 100. Defaults to `generateRandomDouble`.
    ///   - fromCache: A Boolean flag indicating whether to return the cached vault type if available. Defaults to `true`.
    ///
    /// - Returns: The determined `VaultType`.
    func getVaultType(
        ldClient: LDClientProtocol?,
        genRandomDouble: () -> Double,
        fromCache: Bool
    ) -> VaultType {
        logger = logger?.setPrefix(LAUNCH_DARKLY_PREFIX)

        if fromCache, let existingVaultType = vaultType {
            return existingVaultType
        }

        guard let ld = ldClient else {
            logger?.error("Defaulting to VGS. LDClient.get() was called before init()!",
                          error: nil,
                          attributes: nil)
            return .vgsVaultType
        }

        // Fetch the vault percentage from LaunchDarkly
        let vaultPercentage = ld.doubleVariationWrapper(
            forKey: FlagType.vaultPrimaryTrafficPercentage.rawValue,
            defaultValue: 0.0
        )

        logger?.info("Evaluated \(FlagType.vaultPrimaryTrafficPercentage) = \(vaultPercentage)%",
                     attributes: nil)

        let randomNum = genRandomDouble()
        vaultType = (randomNum < vaultPercentage) ? .btVaultType : .vgsVaultType

        logVaultType(vaultType)

        return vaultType ?? .vgsVaultType
    }

    /// Determines on what interval we will poll for SQS messages based on "iso-polling-wait-intervals" feature flag.
    /// Defaults to the empty array if something goes wrong and defers polling intervals to the polling class (ex: LDClient not initialized, LaunchDarkly is down).
    ///
    /// - Parameters:
    ///   - ldClient: An optional `LDClientProtocol` object used to fetch feature flags. Defaults to `getDefaultLDClient()`.
    ///
    /// - Returns: A list of Ints.
    func getPollingIntervals(
        ldClient: LDClientProtocol?
    ) -> [Int] {
        logger = logger?.setPrefix(LAUNCH_DARKLY_PREFIX)

        let defaultValLdValue = LDValue(dictionaryLiteral: (INTERVALS, []))

        guard let ld = ldClient else {
            logger?.error("Defaulting to 1 second polling intervals. LDClient.get() was called before init()!",
                          error: nil,
                          attributes: nil)

            return []
        }

        let pollingIntervalsAsLdValue = ld.jsonVariationWrapper(forKey: FlagType.isoPollingWaitIntervals.rawValue, defaultValue: defaultValLdValue)
        let pollingIntervals = pollingIntervalsAsLdValue.convertToIntArray()

        logger?.info("Evaluated \(FlagType.isoPollingWaitIntervals) = \(pollingIntervals)",
                     attributes: nil)

        return pollingIntervals
    }

    private func createLDConfig(for environment: Environment) -> LDConfig {
        LDConfig(mobileKey: getLDMobileKey(environment).rawValue)
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
