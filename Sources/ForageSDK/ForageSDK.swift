//
//  ForageSDK.swift
//  ForageSDK
//

import Foundation
import VGSCollectSDK

public class ForageSDK {
    
    // MARK: Properties
    
    private static var config: Config?
    internal var service: ForageService?
    internal var logger: ForageLogger? = nil
    internal var merchantID: String = ""
    internal var sessionToken: String = ""
    internal var traceId: String = ""
    
    public var environment: Environment = .sandbox
    // Don't update! Only updated when releasing.
    public static let version = "3.0.9"
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK unconfigured - call ForageSDK.setup() before accessing ForageSDK.shared")
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
        self.traceId = logger.getTraceId()
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
        var merchantID: String
        var sessionToken: String

        public init(merchantID: String, sessionToken: String) {
            self.merchantID = merchantID
            self.sessionToken = sessionToken
        }
    }
    
    /// Configures the Forage SDK with the given configuration.
    ///
    /// This sets up the merchant ID, session token, and other internal state needed to make API calls.
    /// It must be called before using the SDK.
    ///
    /// - Parameter config: The configuration used to setup the SDK.
    ///
    /// - Use ``updateMerchantID(_:)`` to update the merchant ID after configuring.
    /// - Use ``updateSessionToken(_:)`` to update the session token after it expires.
    public class func setup(_ config: Config) {
        ForageSDK.config = config
    }
    
    /// Updates the merchant ID to use for subsequent API calls.
    /// Use this method to change the active merchant ID if your app supports multiple merchants.
    ///
    /// - Parameter newMerchantID: The new merchant ID to set.
    public static func updateMerchantID(_ newMerchantID: String) {
        guard ForageSDK.config != nil else {
            assertionFailure("ForageSDK must be configured before setting merchant ID")
            return
        }
        // config is guarented to be non-nil because of the guard above.
        ForageSDK.config!.merchantID = newMerchantID
        ForageSDK.shared.merchantID = newMerchantID
    }
    
    /// Updates the session token to use for subsequent API calls.
    ///
    /// Session tokens expire after 15 minutes. Use this method to set a new session token
    /// after refreshing it from your backend.
    ///
    /// - Parameter newSessionToken: The new session token to use for subsequent API calls
    public static func updateSessionToken(_ newSessionToken: String) {
        guard ForageSDK.config != nil else {
            assertionFailure("ForageSDK must be configured before updating the session token")
            return
        }
        // config is guarented to be non-nil because of the guard above.
        ForageSDK.config!.sessionToken = newSessionToken
        ForageSDK.shared.sessionToken = newSessionToken
    }
}
