//
//  File.swift
//  
//
//  Created by Danny Leiser on 3/8/23.
//

import Foundation
import VGSCollectSDK

internal class Collector {
    /**
     VGS VaultId
     */
    private enum VaultId: String {
        case sandbox = "tntagcot4b1"
        case cert = "tntpnht7psv"
        case prod = "tntbcrncmgi"
        case staging = "tnteykuh975"
        case dev = "tntlqkidhc6"
    }
    
    public static func CreateVGS() -> VGSCollect {
        return VGSCollect(id: vaultID(ForageSDK.shared.environment).rawValue, environment: environmentVGS(ForageSDK.shared.environment))
    }
    
    private static func vaultID(_ environment: EnvironmentTarget) -> VaultId {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }
    
    private static func environmentVGS(_ environment: EnvironmentTarget) -> VGSCollectSDK.Environment {
        switch environment {
        case .cert, .sandbox, .staging, .dev: return .sandbox
        case .prod: return .live
        }
    }
}
