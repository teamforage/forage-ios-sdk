//
//  File.swift
//  
//
//  Created by Danny Leiser on 5/11/23.
//

import Foundation
import LaunchDarkly

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
    case vgsVaultType = "VGS_VAULT_TYPE"
    case btVaultType = "BT_VAULT_TYPE"
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

public class LDManager {
    static let shared = LDManager()
    private var internalVaultType: VaultType?
    
    private var vaultType: VaultType? {
        set(newValue) {
            if (internalVaultType == nil) {
                internalVaultType = newValue
            } else {
                // Log a warning here when we have logging!
            }
        }
        get {
            return internalVaultType
        }
    }
    
    private init() {}
    
    internal func initialize(_ environment: EnvironmentTarget) {
        let ldConfig = LDConfig(mobileKey: getLDMobileKey(environment).rawValue)
        var ldContextBuilder = LDContextBuilder(key: ContextKey.iosSdk.rawValue)
        ldContextBuilder.kind(ContextKind.service.rawValue)
        guard case .success(let context) = ldContextBuilder.build()
        else { return }
        LDClient.start(config: ldConfig, context: context)
    }
    
    internal func getVaultType() -> VaultType {
        // Once this value is set, we don't want to change it!
        if (vaultType != nil) {
            return vaultType!
        }
        
        let ld = LDClient.get()!
        // Defaulting to VGS for now! Will likely want to change this to BT in the future.
        let vaultPercentage = ld.doubleVariation(forKey: FlagType.vaultPrimaryTrafficPercentage.rawValue, defaultValue: 0.0)
        let randomNum = Double.random(in: 0...100)
        if (randomNum < vaultPercentage) {
            vaultType = VaultType.btVaultType
        } else {
            vaultType = VaultType.vgsVaultType
        }
        
        return vaultType!
    }
    
    private func getLDMobileKey(_ environment: EnvironmentTarget) -> LDMobileKey {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }
}
