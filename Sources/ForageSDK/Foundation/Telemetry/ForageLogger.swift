//
//  File.swift
//
//
//  Created by Danilo Joksimovic on 2023-07-26.
//

import Datadog
import Foundation

// TODO: move this?
protocol ForageLogger {
    func setCustomerID(_ customerID: String)
    func setMerchantAccount(_ merchantAccount: String)
    func initialize(_ environment: EnvironmentTarget)

    func notice(_ message: String, attributes: [String: Encodable]?)
    func info(_ message: String, attributes: [String: Encodable]?)
    func warn(_ message: String, error: Error?, attributes: [String: Encodable]?)
    func error(_ message: String, error: Error?, attributes: [String: Encodable]?)
    func critical(_ message: String, error: Error?, attributes: [String: Encodable]?)
}

public class DatadogLogger: ForageLogger {
    static let shared = DatadogLogger()
    private static let DD_CLIENT_TOKEN: String = "pub1e4572ba0f5e53df108c333d5ec66c02"
    private static var logger: Logger? = nil

    private init() {}

    internal func initialize(_ environment: EnvironmentTarget) {
        if DatadogLogger.logger != nil {
            return
        }

        // TODO: only initialize if not running locally?

        Datadog.initialize(
            appContext: .init(),
            trackingConsent: .granted,
            configuration: Datadog.Configuration
                .builderUsing(clientToken: DatadogLogger.DD_CLIENT_TOKEN, environment: environment.rawValue)
                .set(serviceName: "ios-sdk")
                .set(endpoint: .us1)
                .build()
        )

        Datadog.verbosityLevel = .info

        DatadogLogger.logger = Logger.builder
            .sendNetworkInfo(true)
            // how do we decide whether we're in local dev or not?
            .sendLogsToDatadog(true)
            .printLogsToConsole(true, usingFormat: .shortWith(prefix: "[forage-ios-sdk] "))
            .set(datadogReportingThreshold: .info)
            .set(loggerName: "Forage")
            .build()
    }

    static var sharedLogger: DatadogLogger {
        return shared
    }

    internal func setCustomerID(_ customerID: String) {
        setLogAttribute("customer_id", value: customerID)
    }

    internal func setMerchantAccount(_ merchantAccount: String) {
        setLogAttribute("merchant", value: merchantAccount)
    }
    
    internal func setPaymentRef(_ paymentRef: String) {
        setLogAttribute("payment_ref", value: paymentRef)
    }
    
    internal func setPaymentMethodRef(_ paymentMethodRef: String) {
        setLogAttribute("payment_method_ref", value: paymentMethodRef)
    }

    internal func notice(_ message: String, attributes: [String: Encodable]? = nil) {
        DatadogLogger.logger?.info(message, error: nil, attributes: attributes)
    }

    internal func info(_ message: String, attributes: [String: Encodable]? = nil) {
        DatadogLogger.logger?.info(message, error: nil, attributes: attributes)
    }

    internal func warn(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        DatadogLogger.logger?.warn(message, error: error, attributes: attributes)
    }

    internal func error(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        DatadogLogger.logger?.error(message, error: error, attributes: attributes)
    }

    internal func critical(_ message: String, error: Error? = nil, attributes: [String: Encodable]? = nil) {
        DatadogLogger.logger?.critical(message, error: error, attributes: attributes)
    }
    
    private func setLogAttribute(_ key: String, value: String) {
        DatadogLogger.logger?.addAttribute(forKey: key, value: value)
    }
}
