//
//  ForageLogger.swift
//
//
//  Created by Danilo Joksimovic on 2023-07-26.
//  © 2023-2025 Forage Technology Corporation. All rights reserved.
//

import Foundation

struct ForageLogContext {
    var customerID: String?
    var merchantRef: String?
    var paymentRef: String?
    var paymentMethodRef: String?
    var sdkVersion: String = ForageSDK.version
}

enum ForageLogKind: String {
    case metric // Used for logging metrics and performance data
    case trace // Used for tracing or logging of execution flow.
}

struct ForageLoggerConfig {
    var forageEnvironment: Environment?
    var prefix: String?
    var context: ForageLogContext?

    init(environment: Environment? = ForageSDK.shared.environment, prefix: String? = nil, context: ForageLogContext? = nil) {
        forageEnvironment = environment
        self.context = context
        self.prefix = prefix
    }
}

protocol ForageLogger {
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
class DatadogLogger: ForageLogger {
    private static let DD_CLIENT_TOKEN: String = "pub1e4572ba0f5e53df108c333d5ec66c02"
    private static let DD_SERVICE_NAME: String = "ios-sdk"

    // DO NOT UPDATE! Generate 1 TraceID per living session of the app
    static let traceId: String = generateTraceID()

    private var logger: LoggerProtocol?
    private var config: ForageLoggerConfig?

    required init(_ config: ForageLoggerConfig? = ForageLoggerConfig()) {
        if isUnitTesting() {
            // avoid emitting logs when running unit tests
            return
        }

        self.config = config
        guard let forageEnvironment = config?.forageEnvironment else {
            print("forageEnvironment must be set to initialize the logger")
            return
        }

        let datadogInstance = initDatadog(forageEnvironment)
        logger = Logger.create(
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
        logger?.addAttribute(forKey: "trace_id", value: DatadogLogger.traceId)

        _ = addContext(config?.context ?? ForageLogContext())
    }

    func notice(_ message: String, attributes: [String: Encodable]? = nil) {
        logger?.notice(getMessageWithPrefix(message), error: nil, attributes: attributes)
    }

    func info(_ message: String, attributes: [String: Encodable]? = nil) {
        logger?.info(getMessageWithPrefix(message), error: nil, attributes: attributes)
    }

    func warn(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        logger?.warn(getMessageWithPrefix(message), error: error, attributes: attributes)
    }

    func error(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        logger?.error(getMessageWithPrefix(message), error: error, attributes: attributes)
    }

    func critical(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        logger?.critical(getMessageWithPrefix(message), error: error, attributes: attributes)
    }

    @discardableResult
    func addContext(_ newContext: ForageLogContext) -> ForageLogger {
        config?.context = newContext
        let attributeMappings: [(key: String, value: Encodable?)] = [
            ("customer_id", newContext.customerID),
            ("merchant_ref", newContext.merchantRef),
            ("payment_method_ref", newContext.paymentMethodRef),
            ("payment_ref", newContext.paymentRef),
            ("vault_type", "forage"),
            ("sdk_version", newContext.sdkVersion),
        ]

        for (key, value) in attributeMappings {
            if let attributeValue = value {
                logger?.addAttribute(forKey: key, value: attributeValue)
            }
        }
        return self
    }

    @discardableResult
    func setLogKind(_ logKind: ForageLogKind) -> ForageLogger {
        logger?.addTag(withKey: "log_kind", value: logKind.rawValue)
        return self
    }

    @discardableResult
    func setPrefix(_ newPrefix: String) -> ForageLogger {
        config?.prefix = newPrefix
        return self
    }

    func getTraceID() -> String {
        DatadogLogger.traceId
    }

    /// Initializes and returns a Datadog instance for the given environment. If an instance with the specified name already exists,
    /// it returns the existing instance.
    private func initDatadog(_ environment: Environment) -> DatadogCoreProtocol {
        let instanceName = buildInstanceName(environment: environment)

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

    // ensure logger is re-initialized if the environment changes!
    private func buildInstanceName(environment: Environment) -> String {
        "forage-\(environment.rawValue)"
    }

    private func getMessageWithPrefix(_ message: String) -> String {
        if let prefix = config?.prefix {
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
