//
//  File.swift
//
//
//  Created by Danny Leiser on 5/11/23.
//

import Foundation
import LaunchDarkly

internal protocol LDClientProtocol {
    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double
}

extension LDClient: LDClientProtocol {
    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double {
        return self.doubleVariation(forKey: key, defaultValue: defaultValue)
    }
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
}

/**
 Contexts
 */
private enum ContextKey: String {
    case iosSdk = "ios-sdk-service"
}

private enum ContextKind: String {
    case service = "service"
}

internal class LDManager {
    static let shared = LDManager()
    private var logger: ForageLogger?
    
    internal private(set) var vaultType: VaultType?
    
    private init() {}
    
    internal func initialize(
        _ environment: EnvironmentTarget,
        logger: ForageLogger? = nil,
        startLdClient: (LDConfig, LDContext?, (() -> Void)?) -> Void = LDClient.start
    ) {
        self.logger = logger
        
        let ldConfig = createLDConfig(for: environment)
        
        guard let ldContext = createLDContext() else {
            self.logger?.error("Failed to create LaunchDarkly context", error: nil, attributes: nil)
            return
        }
        
        startLdClient(ldConfig, ldContext, { [weak self] in
            self?.logger?.info("Initialized LaunchDarkly client", attributes: nil)
        })
    }
    
    internal func getVaultType(
        ldClient: LDClientProtocol? = getDefaultLDClient(),
        genRandomDouble: () -> Double = generateRandomDouble,
        fromCache: Bool = true
    ) -> VaultType {
        logger = logger?.setPrefix("LaunchDarkly")
        
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

    private func createLDConfig(for environment: EnvironmentTarget) -> LDConfig {
        return LDConfig(mobileKey: getLDMobileKey(environment).rawValue)
    }
    
    private func createLDContext() -> LDContext? {
        var ldContextBuilder = LDContextBuilder(key: ContextKey.iosSdk.rawValue)
        ldContextBuilder.kind(ContextKind.service.rawValue)
        guard case .success(let context) = ldContextBuilder.build() else {
            return nil
        }
        return context
    }
    
    private static func getDefaultLDClient() -> LDClientProtocol? {
        return LDClient.get()
    }
    
    private static func generateRandomDouble() -> Double {
        return Double.random(in: 0...100)
    }
    
    private func logVaultType(_ vaultType: VaultType? = nil) {
        guard let vaultType = vaultType else {
            // this shouldn't happen, but we log here in case something went really wrong
            self.logger?.error("Vault type was not set!", error: nil, attributes: nil)
            return
        }
        
        _ = self.logger?
            .addContext(ForageLogContext(
                vaultType: vaultType
            ))
            .notice("Using \(vaultType.rawValue)", attributes: nil)
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
