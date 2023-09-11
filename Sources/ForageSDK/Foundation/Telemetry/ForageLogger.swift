//
//  ForageLogger.swift
//
//
//  Created by Danilo Joksimovic on 2023-07-26.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

internal struct ForageLogContext {
    var customerID: String? = nil
    var merchantRef: String? = nil
    var paymentRef: String? = nil
    var paymentMethodRef: String? = nil
    var vaultType: VaultType? = nil
    var sdkVersion: String = ForageSDK.version
}

internal enum ForageLogKind: String {
    case metric = "metric" // Used for logging metrics and performance data
    case trace = "trace" // Used for tracing or logging of execution flow.
}

internal struct ForageLoggerConfig {
    var forageEnvironment: Environment?
    var prefix: String?
    var context: ForageLogContext?
    
    init(environment: Environment? = ForageSDK.shared.environment, prefix: String? = nil, context: ForageLogContext? = nil) {
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
    
    /// Set the kind of logging to be performed and return a ForageLogger instance.
    ///
    /// - Parameter logKind: The desired log kind to be used.
    /// - Returns: The instance of the ForageLogger with the log kind applied.
    func setLogKind(_ logKind: ForageLogKind) -> ForageLogger
    
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
    
    /// The ForageSDK object needs a handler to the TraceId in order to pass it along to each endpoint call.
    /// - Returns: The traceID that was generated at the beginning of the app's lifecycle.
    func getTraceID() -> String
}

/// Read this [document](https://docs.google.com/document/d/1BU609qv7qSDN-tdNaJP-sAyrgeM6REe9tvcMk5CxN3c/edit#bookmark=id.w44b8kk07o7o) for to learn more about how DatadogLogger works
internal class DatadogLogger : ForageLogger {
    private static let DD_CLIENT_TOKEN: String = "pub1e4572ba0f5e53df108c333d5ec66c02"
    private static let DD_SERVICE_NAME: String = "ios-sdk"
    private static let DD_SDK_INSTANCE_NAME: String = "forage"
    
    // DO NOT UPDATE! Generate 1 TraceID per living session of the app
    internal static let traceId: String = generateTraceID()

    private var logger: LoggerProtocol? = nil
    private var config: ForageLoggerConfig? = nil

    required internal init(_ config: ForageLoggerConfig? = ForageLoggerConfig()) {
        if isUnitTesting() {
            // avoid emitting logs when running unit tests
            return
        }
        
        self.config = config
        guard let forageEnvironment = config?.forageEnvironment else {
            print("forageEnvironment must be set to initialize the logger")
            return
        }
        
        let datadogInstance = self.initDatadog(forageEnvironment)
        self.logger = Logger.create(
            with: Logger.Configuration(
                service: "ios-sdk",
                networkInfoEnabled: true,
                bundleWithRumEnabled: false,
                bundleWithTraceEnabled: false,
                remoteLogThreshold: .info,
                // we want to always emit to Datadog
                // but we don't want to spam the client's console with our logs.
                consoleLogFormat: nil
            ),
            in: datadogInstance
        )
        
        // Do this explicitly in the constructor so that we confirm each logger that is created
        // has the trace_id field.
        self.logger?.addAttribute(forKey: "trace_id", value: DatadogLogger.traceId)

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
    
    @discardableResult
    internal func addContext(_ newContext: ForageLogContext) -> ForageLogger {
        self.config?.context = newContext
        let attributeMappings: [(key: String, value: Encodable?)] = [
            ("customer_id", newContext.customerID),
            ("merchant_ref", newContext.merchantRef),
            ("payment_method_ref", newContext.paymentMethodRef),
            ("payment_ref", newContext.paymentRef),
            ("vault_type", newContext.vaultType?.rawValue),
            ("sdk_version", newContext.sdkVersion)
        ]
        
        for (key, value) in attributeMappings {
            if let attributeValue = value {
                self.logger?.addAttribute(forKey: key, value: attributeValue)
            }
        }
        return self
    }
    
    @discardableResult
    internal func setLogKind(_ logKind: ForageLogKind) -> ForageLogger {
        self.logger?.addTag(withKey: "log_kind", value: logKind.rawValue)
        return self
    }
    
    @discardableResult
    internal func setPrefix(_ newPrefix: String) -> ForageLogger {
        self.config?.prefix = newPrefix
        return self
    }
    
    internal func getTraceID() -> String {
        return DatadogLogger.traceId
    }
    
    /// Initializes and returns a Datadog instance for the given environment. If an instance with the specified name already exists,
    /// it returns the existing instance.
    private func initDatadog(_ environment: Environment) -> DatadogCoreProtocol {
        let instanceName = DatadogLogger.DD_SDK_INSTANCE_NAME
        
        if Datadog.isInitialized(instanceName: instanceName) {
            return Datadog.sdkInstance(named: instanceName)
        }
        
        let datadogInstance = Datadog.initialize(
            with: Datadog.Configuration(
                clientToken: DatadogLogger.DD_CLIENT_TOKEN,
                env: String(describing: environment),
                service: DatadogLogger.DD_SERVICE_NAME
            ),
            trackingConsent: .granted,
            instanceName: instanceName
        )
    
        Logs.enable(in: datadogInstance)
        return datadogInstance
    }
    
    private func getMessageWithPrefix(_ message: String) -> String {
        if let prefix = self.config?.prefix {
            return prefix.isEmpty ? message : "[\(prefix)] \(message)"
        }
        return message
    }
    
    private static func generateTraceID() -> String {
        var trace = ""
        for _ in 0..<14 {
            let randomDigit = UInt64(arc4random_uniform(10))
            trace = trace + String(randomDigit)
        }
        return "33" + trace
    }
}
