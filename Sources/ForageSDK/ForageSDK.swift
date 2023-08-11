//
//  ForageSDK.swift
//  ForageSDK
//
//  Created by Symphony on 18/10/22.
//

import Foundation
import VGSCollectSDK
import Sentry
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
        let isUnitTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if !isUnitTesting {
        SentrySDK.start { options in
            options.dsn = "https://8fcdd8dc94aa892ed8fd4cdb20db90ee@o921422.ingest.sentry.io/4505665631813632"
            options.debug = false
            options.environment = String(describing: self.environment)
            options.tracesSampleRate = 1.0
            options.enableTracing = true
        }
        }
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
