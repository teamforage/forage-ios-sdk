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
    internal var logger: ForageLogger? = nil
    internal var merchantAccount: String = ""
    internal var bearerToken: String = ""
    
    // Don't update! Only updated when releasing.
    public static let version = "3.0.8"
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        self.environment = config.environment
        self.merchantAccount = config.merchantAccount
        self.bearerToken = config.bearerToken
        // ForageSDK.shared.environment is not set
        // until the end of this initialization
        // so we have to provide the environment from the config
        let logger = DatadogLogger(
            ForageLoggerConfig(
                environment: self.environment,
                prefix: ""
            )
        )
        self.logger = logger
        LDManager.shared.initialize(self.environment, logger: logger)
    
        VGSCollectLogger.shared.disableAllLoggers()
        let provider = Provider(logger: logger)
        self.service = LiveForageService(provider: provider, logger: logger)
    }
    
    /**
     ``Config`` struct to set environment(``EnvironmentTarget``), merchant ID and session token on the ``ForageSDK`` singleton
     
     - Parameters:
        - environment: *EnvironmentTarget* enum to set environment.
        - merchantAccount: The unique merchant ID that Forage provides during onboarding preceded by `mid/`, as in `mid/<Merchant ID>`
        - bearerToken: The [session token](https://docs.joinforage.app/docs/authentication#session-tokens) that your backend generates to authenticate your app against the Forage Payments API. The token expires after 15 minutes.
     */
    public struct Config {
        let environment: EnvironmentTarget
        let merchantAccount: String
        let bearerToken: String

        public init(environment: EnvironmentTarget = .sandbox, merchantAccount: String, bearerToken: String) {
            self.environment = environment
            self.merchantAccount = merchantAccount
            self.bearerToken = bearerToken
        }
    }
    
    /**
     Setup ForageSDK using Config struct.
     
     - Parameters:
       - config: *Config* struct object to set environment, merchant ID, and session token
     
    ````
     ForageSDK.setup(
         ForageSDK.Config(
             environment: .sandbox,
             merchantAccount: "mid/abcd123",
             bearerToken: "sandbox_eyJ0eXAiOiJKV1Qi..."
         )
     )
    ````
     */
    public class func setup(_ config: Config) {
        ForageSDK.config = config
        ForageSDK.shared.environment = config.environment
        ForageSDK.shared.merchantAccount = config.merchantAccount
        ForageSDK.shared.bearerToken = config.bearerToken
    }
}
