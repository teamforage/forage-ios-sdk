//
//  ForageSDK.swift
//  ForageSDK
//
//  Created by Symphony on 18/10/22.
//

import VGSCollectSDK
import Foundation

/**
 Environment base URL
 */
public enum EnvironmentTarget: String {
    case sandbox = "api.sandbox.joinforage.app"
    case cert = "api.cert.joinforage.app"
    case prod = "api.joinforage.app"
}

/**
 VGS VaultId
 */
private enum VaultId: String {
    case sandbox = "tntagcot4b1"
    case cert = "tntpnht7psv"
    case prod = "tntbcrncmgi"
}

public class ForageSDK {
    
    // MARK: Properties
    
    private static var config: Config?
    internal var collector: VGSCollect?
    internal var service: ForageService?
    internal var panNumber: String = ""
    internal var environment: EnvironmentTarget = .sandbox
    
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        
        VGSCollectLogger.shared.disableAllLoggers()
        self.environment = config.environment
        self.collector = VGSCollect(id: vaultID(config.environment).rawValue, environment: environmentVGS(config.environment))
        self.service = LiveForageService(collector)
    }
    
    /**
     ``Config`` struct to set environment(``EnvironmentTarget``) on `ForageSDK` singleton
     
    - Parameters:
       - environment: *EnvironmentTarget* enum to set environment.
    */
    public struct Config {
        let environment: EnvironmentTarget

        public init(environment: EnvironmentTarget = .sandbox) {
            self.environment = environment
        }
    }
    
    /**
     Setup ForageSDK using Config struct.
     
    - Parameters:
     - config: *Config* struct object to set environment.
     
    ````
      ForageSDK.setup(
         ForageSDK.Config(environment: .dev)
      )
    ````
    */
    public class func setup(_ config: Config) {
        ForageSDK.config = config
    }
    
    // MARK: Private Methods
    
    private func vaultID(_ environment: EnvironmentTarget) -> VaultId {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        }
    }
    
    private func environmentVGS(_ environment: EnvironmentTarget) -> VGSCollectSDK.Environment {
        switch environment {
        case .cert, .sandbox: return .sandbox
        case .prod: return .live
        }
    }
}
