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
    internal var logger: ForageLogger? = nil
    
    // Don't update! Only updated when releasing.
    public static let version = "3.0.6"
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        self.environment = config.environment
        // ForageSDK.shared.environment is not set
        // until the end of this initialization
        // so we have to provide the environment from the config
        let logger = DatadogLogger(
            ForageLoggerConfig(
                environment: config.environment,
                prefix: ""
            )
        )
        self.logger = logger
        LDManager.shared.initialize(self.environment, logger: logger)
        VGSCollectLogger.shared.disableAllLoggers()
                
        if !isUnitTesting() {
            SentrySDK.start { options in
                options.dsn = "https://8fcdd8dc94aa892ed8fd4cdb20db90ee@o921422.ingest.sentry.io/4505665631813632"
                options.debug = false
                options.environment = String(describing: self.environment)
                let httpStatusCodeRange = HttpStatusCodeRange(min: 400, max: 599)
                options.failedRequestStatusCodes = [ httpStatusCodeRange ]
                options.tracesSampleRate = 1.0
                options.enableTracing = true
            }
        }
        let provider = Provider(logger: logger)
        self.service = LiveForageService(provider: provider, logger: logger)
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
