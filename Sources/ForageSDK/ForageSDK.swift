//
//  ForageSDK.swift
//  ForageSDK
//
//  Created by Symphony on 18/10/22.
//

import Foundation
import VGSCollectSDK

/**
 Environment base URL
 */
public enum EnvironmentTarget: String {
    case sandbox = "api.sandbox.joinforage.app"
    case cert = "api.cert.joinforage.app"
    case prod = "api.joinforage.app"
    case staging = "api.staging.joinforage.app"
    case dev = "api.dev.joinforage.app"
}

public class ForageSDK {
    
    // MARK: Properties
    
    private static var config: Config?
    internal var service: ForageService?
    internal var panNumber: String = ""
    internal var environment: EnvironmentTarget = .sandbox
    
    // Don't update! Only updated when releasing.
    public static let version = "3.0.3"
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        self.environment = config.environment
        LDManager.shared.initialize(self.environment)
        // TODO: Maybe move this shared logger call!
        VGSCollectLogger.shared.disableAllLoggers()
        self.service = LiveForageService()
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
         ForageSDK.Config(environment: .sandbox)
      )
    ````
     */
    public class func setup(_ config: Config) {
        ForageSDK.config = config
    }
}
