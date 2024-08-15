//
//  ForageSDK.swift
//  ForageSDK
//

import Foundation

public class ForageSDK {
    // MARK: - Static Properties

    // These belong to ForageSDK itself and are shared by all of its instances
    private static var config: Config?
    static var logger: ForageLogger?
    // Don't update version! Only updated when releasing.
    public static let version = "4.4.9"
    public static let shared = ForageSDK()
    
    // MARK: - Singleton Instance Properties

    // Instance properties, only belong to the `shared` singleton instance.
    var service: ForageService?
    
    // Computed instance properties derived from static values
    public var environment: Environment {
        Environment(sessionToken: ForageSDK.config?.sessionToken)
    }
    var merchantID: String {
        ForageSDK.config?.merchantID ?? ""
    }
    var sessionToken: String {
        ForageSDK.config?.sessionToken ?? ""
    }
    var traceId: String {
        ForageSDK.logger?.getTraceID() ?? ""
    }

    // MARK: - Singleton Init

    // This is only called when first accessing `shared`. This class can't be initialized manually, only by referencing `ForageSDK.shared`, which creates the singleton instance and calls this private `init` method. It would only get called again if the singleton instance was removed from memory (force-closing an app, for instance).
    private init() {
        guard ForageSDK.config != nil else {
            assertionFailure("ForageSDK is not initialized - call ForageSDK.setup() before accessing ForageSDK.shared")
            return
        }

        let provider = Provider(logger: ForageSDK.logger)
        service = LiveForageService(
            provider: provider,
            logger: ForageSDK.logger,
            ldManager: LDManager.shared
        )
    }
    
    // MARK: - Public API

    /**
     ``Config`` struct to set the merchant ID and session token on the ``ForageSDK`` singleton

     - Parameters:
        - merchantID: The unique merchant ID that Forage provides during onboarding preceded by `mid/`, as in `mid/<Merchant ID>`
        - sessionToken: The [session token](https://docs.joinforage.app/docs/authentication#session-tokens) that your backend generates to authenticate your app against the Forage Payments API. The token expires after 15 minutes.
     */
    public struct Config {
        var merchantID: String
        var sessionToken: String
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
        let environment = Environment(sessionToken: config.sessionToken)

        updateMerchantID(config.merchantID)
        updateSessionToken(config.sessionToken)

        initializeLogger(environment)
        initializeLaunchDarkly(environment)

        ForageSDK.logger?
            .setPrefix("ForageSDK")
            .notice("Initialized SDK for merchant \(config.merchantID)", attributes: nil)
    }

    /// Updates the merchant ID to use for subsequent API calls.
    /// Use this method to change the active merchant ID if your app supports multiple merchants.
    ///
    /// - Parameter newMerchantID: The new merchant ID to set.
    public static func updateMerchantID(_ newMerchantID: String) {
        guard ForageSDK.config != nil else {
            assertionFailure("ForageSDK must be initialized before setting merchant ID")
            return
        }

        ForageSDK.logger?
            .setPrefix("ForageSDK")
            .addContext(ForageLogContext(merchantRef: newMerchantID))
            .notice("Updated merchantID to \(newMerchantID)", attributes: nil)

        // config is guaranteed to be non-nil because of the guard above.
        ForageSDK.config!.merchantID = newMerchantID
    }

    /// Updates the session token to use for subsequent API calls.
    ///
    /// Session tokens expire after 15 minutes. Use this method to set a new session token
    /// after refreshing it from your backend.
    ///
    /// - Parameter newSessionToken: The new session token to use for subsequent API calls
    public static func updateSessionToken(_ newSessionToken: String) {
        guard ForageSDK.config != nil else {
            assertionFailure("ForageSDK must be initialized before updating the session token")
            return
        }

        ForageSDK.logger?
            .setPrefix("ForageSDK")
            .notice("Called updateSessionToken", attributes: nil)

        // config is guaranteed to be non-nil because of the guard above.
        ForageSDK.config!.sessionToken = newSessionToken
    }

    // MARK: - Internal methods
    
    class func initializeLogger(_ environment: Environment) {
        ForageSDK.logger = DatadogLogger(
            ForageLoggerConfig(
                environment: environment,
                prefix: ""
            )
        )
    }

    class func initializeLaunchDarkly(_ environment: Environment) {
        LDManager.shared.initialize(environment, logger: ForageSDK.logger)
    }
}
