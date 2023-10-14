//
//  ResponseMonitor.swift
//  
//
//  Created by Danilo Joksimovic on 2023-10-12.
//

import Foundation

internal enum MetricsAttributeName: String {
    case logType = "log_type"
    case responseTimeMs = "response_time_ms"
    case vaultType = "vault_type"
    case action = "action"
    case path = "path"
    case method = "method"
    case httpStatus = "http_status"
    case eventName = "event_name"
    case eventOutcome = "event_outcome"
    case forageErrorCode = "forage_error_code"
}

internal struct ResponseAttributes {
    var responseTimeMs: Double?
    var path: String?
    var method: HttpMethod?
    var code: Int?
    var forageErrorCode: String?
}

internal enum VaultAction: String {
    case balanceCheck = "balance"
    case capturePayment = "capture"
}

internal enum EventOutcome: String {
    case success = "success"
    case failure = "failure"
}

/// `ResponseMonitor` serves as the base class for monitoring network metrics
internal class ResponseMonitor: NetworkMonitor {
    private var startTime: DispatchTime?
    private var endTime: DispatchTime?
    
    private var responseAttributes: ResponseAttributes = ResponseAttributes()
    private var metricsLogger: ForageLogger?
    
    
    init(
        metricsLogger: ForageLogger? = DatadogLogger(
            ForageLoggerConfig(prefix: "Metrics")
        )
    ) {
        self.metricsLogger = metricsLogger?.setLogKind(ForageLogKind.metric)
    }
    
    internal func start() {
        startTime = DispatchTime.now()
    }
    
    internal func end() {
        endTime = DispatchTime.now()
    }
    
    @discardableResult
    internal func setPath(_ httpPath: String) -> NetworkMonitor {
        self.responseAttributes.path = httpPath
        return self
    }
    
    @discardableResult
    internal func setMethod(_ httpMethod: HttpMethod) -> NetworkMonitor {
        self.responseAttributes.method = httpMethod
        return self
    }
    
    @discardableResult
    internal func setHttpStatusCode(_ httpStatusCode: Int?) -> NetworkMonitor {
        self.responseAttributes.code = httpStatusCode
        return self
    }
    
    @discardableResult
    internal func setForageErrorCode(_ error: Error) -> ResponseMonitor {
        self.responseAttributes.forageErrorCode = (error as? ForageError)?.errors.first?.code ?? UnknownErrorCode
        return self
    }
    
    /// Converts a dictionary with `MetricsAttributeName` enum keys to a dictionary with String keys.
    internal func mapEnumKeysToStrings(from metricsAttributes: [MetricsAttributeName: Encodable]) -> [String: Encodable] {
        var attributes: [String: Encodable] = [:]
        for (key, value) in metricsAttributes {
            attributes[key.rawValue] = value
        }
        return attributes
    }
    
    internal func logResult() {
        guard let startTime = self.startTime, let endTime = self.endTime else {
            metricsLogger?.error("Missing startTime or endTime. Could not log metric.", error: nil, attributes: nil)
            return
        }
        responseAttributes.responseTimeMs = calculateDurationMs(from: startTime, to: endTime)
        
        // handled by subclass
        logWithResponseAttributes(
            metricsLogger: self.metricsLogger,
            responseAttributes: responseAttributes
        )
    }
    
    /// Calculates the time in milliseconds between the start and end time
    private func calculateDurationMs(from startTime: DispatchTime, to endTime: DispatchTime) -> Double {
        let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        return Double(nanoseconds) / 1_000_000
    }
    
    // Do nothing here; meant to be overridden by subclasses
    internal func logWithResponseAttributes(metricsLogger: ForageLogger?, responseAttributes: ResponseAttributes) {}
}
