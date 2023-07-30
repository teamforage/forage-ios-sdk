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
}

internal struct ForageLoggerConfig {
    let environment: EnvironmentTarget
    let context: ForageLogContext?
    
    init(environment: EnvironmentTarget, context: ForageLogContext? = nil) {
        self.environment = environment
        self.context = context
    }
}

protocol ForageLogger {
    init(_ config: ForageLoggerConfig)
    
    func notice(_ message: String, attributes: [String: Encodable]?)
    func info(_ message: String, attributes: [String: Encodable]?)
    func warn(_ message: String, error: Error?, attributes: [String: Encodable]?)
    func error(_ message: String, error: Error?, attributes: [String: Encodable]?)
    func critical(_ message: String, error: Error?, attributes: [String: Encodable]?)
}

internal class DatadogLogger : ForageLogger {
    private static let DD_CLIENT_TOKEN: String = "pub1e4572ba0f5e53df108c333d5ec66c02"
    private var logger: Logger? = nil
    
    required public init(_ config: ForageLoggerConfig) {
        self.initDatadog(config.environment)
        
        let newLogger = Logger.builder
            .sendNetworkInfo(true)
        // we want to always emit to Datadog
        // but we don't want to spam the client's console with our logs.
            .sendLogsToDatadog(true)
            .set(datadogReportingThreshold: .info)
            .set(serviceName: "ios-sdk")
            .build()
        
        if let logCtx = config.context {
            let attributeMappings: [(key: String, value: Encodable?)] = [
                ("customer_id", logCtx.customerID),
                ("merchant_ref", logCtx.merchantRef),
                ("payment_method_ref", logCtx.paymentMethodRef),
                ("payment_ref", logCtx.paymentRef)
            ]
            
            for (key, value) in attributeMappings {
                if let attributeValue = value {
                    newLogger.addAttribute(forKey: key, value: attributeValue)
                }
            }
        }
        self.logger = newLogger
    }
    
    internal func notice(_ message: String, attributes: [String: Encodable]? = nil) {
        self.logger?.notice(message, error: nil, attributes: attributes)
    }
    
    internal func info(_ message: String, attributes: [String: Encodable]? = nil) {
        self.logger?.info(message, error: nil, attributes: attributes)
    }
    
    internal func warn(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        self.logger?.warn(message, error: error, attributes: attributes)
    }
    
    internal func error(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        self.logger?.error(message, error: error, attributes: attributes)
    }
    
    internal func critical(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        self.logger?.critical(message, error: error, attributes: attributes)
    }
    
    private func initDatadog(_ environment: EnvironmentTarget) {
        if Datadog.isInitialized {
            return
        }
        Datadog.initialize(
            appContext: .init(),
            trackingConsent: .granted,
            configuration: Datadog.Configuration
                .builderUsing(clientToken: DatadogLogger.DD_CLIENT_TOKEN, environment: environment.rawValue)
                .set(serviceName: "ios-sdk")
                .set(endpoint: .us1)
                .build()
        )
    }
}
