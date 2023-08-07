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
    internal var merchantID: String = ""
    internal var sessionToken: String = ""
    
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        self.environment = config.environment
        self.merchantID = config.merchantID
        self.sessionToken = config.sessionToken
        
        LDManager.shared.initialize(self.environment)
        // TODO: Maybe move this shared logger call!
        VGSCollectLogger.shared.disableAllLoggers()
        self.service = LiveForageService()
    }
    
    /**
     ``Config`` struct to set environment(``EnvironmentTarget``), merchant ID and session token on the ``ForageSDK`` singleton
     
     - Parameters:
        - environment: *EnvironmentTarget* enum to set environment.
        - merchantID: The unique merchant ID that Forage provides during onboarding preceded by `mid/`, as in `mid/<Merchant ID>`
        - sessionToken: The [session token](https://docs.joinforage.app/docs/authentication#session-tokens) that your backend generates to authenticate your app against the Forage Payments API. The token expires after 15 minutes.
     */
    public struct Config {
        let environment: EnvironmentTarget
        let merchantID: String
        let sessionToken: String

        public init(environment: EnvironmentTarget = .sandbox, merchantID: String, sessionToken: String) {
            self.environment = environment
            self.merchantID = merchantID
            self.sessionToken = sessionToken
        }
    }
    
    /**
     Setup ForageSDK using ``Config`` struct.
     
     - Parameters:
       - config: ``Config`` struct object to set environment, merchant ID, and session token
     
    ````
     ForageSDK.setup(
         ForageSDK.Config(
             environment: .sandbox,
             merchantID: "mid/abcd123",
             sessionToken: "sandbox_eyJ0eXAiOiJKV1Qi..."
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
