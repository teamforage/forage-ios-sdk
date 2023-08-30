//
//  ForageSDK.swift
//  ForageSDK
//
//  Created by Symphony on 18/10/22.
//

import Foundation
import VGSCollectSDK

public class ForageSDK {
    
    // MARK: Properties
    
    private static var config: Config?
    internal var service: ForageService?
    internal var panNumber: String = ""
    internal var logger: ForageLogger? = nil
    internal var merchantID: String = ""
    internal var sessionToken: String = ""
    
    public var environment: Environment = .sandbox
    // Don't update! Only updated when releasing.
    public static let version = "3.0.9"
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        self.environment = Environment(sessionToken: config.sessionToken)
        self.merchantID = config.merchantID
        self.sessionToken = config.sessionToken
        
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
     ``Config`` struct to set the merchant ID and session token on the ``ForageSDK`` singleton
     
     - Parameters:
        - merchantID: The unique merchant ID that Forage provides during onboarding preceded by `mid/`, as in `mid/<Merchant ID>`
        - sessionToken: The [session token](https://docs.joinforage.app/docs/authentication#session-tokens) that your backend generates to authenticate your app against the Forage Payments API. The token expires after 15 minutes.
     */
    public struct Config {
        let merchantID: String
        let sessionToken: String

        public init(merchantID: String, sessionToken: String) {
            self.merchantID = merchantID
            self.sessionToken = sessionToken
        }
    }
    
    /**
     Setup ForageSDK using ``Config`` struct.
     
     - Parameters:
       - config: ``Config`` struct object to set merchant ID, and session token
     
    ````
     ForageSDK.setup(
         ForageSDK.Config(
             merchantID: "1234567",
             sessionToken: "sandbox_eyJ0eXAiOiJKV1Qi..."
         )
     )
    ````
     */
    public class func setup(_ config: Config) {
        ForageSDK.config = config
        ForageSDK.shared.environment = Environment(sessionToken: config.sessionToken)
        ForageSDK.shared.merchantID = config.merchantID
        ForageSDK.shared.sessionToken = config.sessionToken
    }
}
