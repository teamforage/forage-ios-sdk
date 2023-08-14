//
//  File.swift
//
//
//  Created by Danilo Joksimovic on 2023-07-26.
//

import Datadog
import Foundation

internal struct ForageLogContext {
    var customerID: String? = nil
    var merchantRef: String? = nil
    var paymentRef: String? = nil
    var paymentMethodRef: String? = nil
    var vaultType: VaultType? = nil
}

internal struct ForageLoggerConfig {
    var forageEnvironment: EnvironmentTarget?
    var prefix: String?
    var context: ForageLogContext?
    
    init(environment: EnvironmentTarget? = ForageSDK.shared.environment, prefix: String? = nil, context: ForageLogContext? = nil) {
        self.forageEnvironment = environment
        self.context = context
        self.prefix = prefix
    }
}

internal protocol ForageLogger {
    init(_ config: ForageLoggerConfig?)
    
    /// Adds additional context to the logger, providing useful information for each log message.
    /// - Parameter newContext: The ForageLogContext to be added to the logger.
    /// - Returns: The instance of the ForageLogger with the additional context applied. Useful for method chaining.
    func addContext(_ newContext: ForageLogContext) -> ForageLogger
    
    /// Sets a prefix that will be added to each log message, useful for distinguishing log sources.
    /// - Parameter prefix: The prefix string to be added to log messages.
    /// - Returns: The instance of the ForageLogger with the specified prefix applied. Useful for method chaining.
    func setPrefix(_ prefix: String) -> ForageLogger
    
    /// Logs noteworthy events or significant occurrences in the application.
    /// These messages are more important than general informational messages (e.g., log.info).
    /// They draw attention to important events that may be useful for troubleshooting or monitoring the application's behavior.
    /// - Parameter message: The log message to be logged at the notice level.
    /// - Parameter attributes: An optional dictionary of key-value pairs providing additional context for the log.
    func notice(_ message: String, attributes: [String: Encodable]?)
    
    /// Logs information to help developers understand how the application is functioning at a finer level of detail.
    /// These logs can be helpful for debugging or gaining insights into the application's behavior.
    /// - Parameter message: The log message to be logged at the info level.
    /// - Parameter attributes: An optional dictionary of key-value pairs providing additional context for the log.
    func info(_ message: String, attributes: [String: Encodable]?)
    
    func warn(_ message: String, error: Error?, attributes: [String: Encodable]?)
    
    /// Logs error messages that indicate a problem or failure in the application, but one that might be recoverable.
    /// - Parameter message: The log message to be logged at the error level.
    /// - Parameter error: An optional error object associated with the error log.
    /// - Parameter attributes: An optional dictionary of key-value pairs providing additional context for the log.
    func error(_ message: String, error: Error?, attributes: [String: Encodable]?)
    
    /// Logs severe issues that lead to application failure or data corruption.
    /// - Parameter message: The log message to be logged at the critical level.
    /// - Parameter error: An optional error object associated with the critical log.
    /// - Parameter attributes: An optional dictionary of key-value pairs providing additional context for the log.
    func critical(_ message: String, error: Error?, attributes: [String: Encodable]?)
}

internal class DatadogLogger : ForageLogger {
    private static let DD_CLIENT_TOKEN: String = "pub1e4572ba0f5e53df108c333d5ec66c02"
    private var logger: Logger? = nil
    private var config: ForageLoggerConfig? = nil
        
    required internal init(_ config: ForageLoggerConfig? = ForageLoggerConfig()) {
        self.config = config
        guard let forageEnvironment = config?.forageEnvironment else {
              print("forageEnvironment must be set to initialize the logger")
              return
          }
        self.initDatadog(forageEnvironment)

        let newLogger = Logger.builder
            .sendNetworkInfo(true)
        // we want to always emit to Datadog
        // but we don't want to spam the client's console with our logs.
            .sendLogsToDatadog(true)
            .set(datadogReportingThreshold: .info)
            .set(serviceName: "ios-sdk")
            .build()

        self.logger = newLogger
        _ = self.addContext(config?.context ?? ForageLogContext())
    }
    
    internal func notice(_ message: String, attributes: [String: Encodable]? = nil) {
        self.logger?.notice(self.getMessageWithPrefix(message), error: nil, attributes: attributes)
    }
    
    internal func info(_ message: String, attributes: [String: Encodable]? = nil) {
        self.logger?.info(self.getMessageWithPrefix(message), error: nil, attributes: attributes)
    }
    
    internal func warn(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        self.logger?.warn(self.getMessageWithPrefix(message), error: error, attributes: attributes)
    }
    
    internal func error(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        self.logger?.error(self.getMessageWithPrefix(message), error: error, attributes: attributes)
    }
    
    internal func critical(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        self.logger?.critical(self.getMessageWithPrefix(message), error: error, attributes: attributes)
    }
    
    internal func addContext(_ newContext: ForageLogContext) -> ForageLogger {
        self.config?.context = newContext
        let attributeMappings: [(key: String, value: Encodable?)] = [
            ("customer_id", newContext.customerID),
            ("merchant_ref", newContext.merchantRef),
            ("payment_method_ref", newContext.paymentMethodRef),
            ("payment_ref", newContext.paymentRef),
            ("vault_type", newContext.vaultType?.rawValue)
        ]
        
        for (key, value) in attributeMappings {
            if let attributeValue = value {
                self.logger?.addAttribute(forKey: key, value: attributeValue)
            }
        }
        return self
    }
    
    internal func setPrefix(_ newPrefix: String) -> ForageLogger {
        self.config?.prefix = newPrefix
        return self
    }
    
    private func initDatadog(_ environment: EnvironmentTarget) {
        if Datadog.isInitialized {
            return
        }
        Datadog.initialize(
            appContext: .init(),
            trackingConsent: .granted,
            configuration: Datadog.Configuration
                .builderUsing(clientToken: DatadogLogger.DD_CLIENT_TOKEN, environment: String(describing: environment))
                .set(serviceName: "ios-sdk")
                .set(endpoint: .us1)
                .build()
        )
    }
    
    private func getMessageWithPrefix(_ message: String) -> String {
        if let prefix = self.config?.prefix {
            return prefix.isEmpty ? message : "[\(prefix)] \(message)"
        }
        return message
    }
}
