//
//  ResponseMonitor.swift
//
//
//  Created by Danilo Joksimovic on 2023-10-12.
//

import Foundation

enum MetricsAttributeName: String {
    case logType = "log_type"
    case responseTimeMs = "response_time_ms"
    case vaultType = "vault_type"
    case action
    case path
    case method
    case httpStatus = "http_status"
    case eventName = "event_name"
    case eventOutcome = "event_outcome"
    case forageErrorCode = "forage_error_code"
}

struct ResponseAttributes {
    var responseTimeMs: Double?
    var path: String?
    var method: HttpMethod?
    var code: Int?
    var forageErrorCode: String?
}

enum EventOutcome: String {
    case success
    case failure
}

/// `ResponseMonitor` serves as the base class for monitoring network metrics
class ResponseMonitor: NetworkMonitor {
    private var startTime: DispatchTime?
    private var endTime: DispatchTime?

    private var responseAttributes: ResponseAttributes = .init()
    private var metricsLogger: ForageLogger?

    init(
        metricsLogger: ForageLogger? = DatadogLogger(
            ForageLoggerConfig(prefix: "Metrics")
        )
    ) {
        self.metricsLogger = metricsLogger?.setLogKind(ForageLogKind.metric).setPrefix("Metrics")
    }

    func start() {
        startTime = DispatchTime.now()
    }

    func end() {
        endTime = DispatchTime.now()
    }

    @discardableResult
    func setPath(_ httpPath: String) -> NetworkMonitor {
        responseAttributes.path = httpPath
        return self
    }

    @discardableResult
    func setMethod(_ httpMethod: HttpMethod) -> NetworkMonitor {
        responseAttributes.method = httpMethod
        return self
    }

    @discardableResult
    func setHttpStatusCode(_ httpStatusCode: Int?) -> NetworkMonitor {
        responseAttributes.code = httpStatusCode
        return self
    }

    @discardableResult
    func setForageErrorCode(_ error: Error) -> ResponseMonitor {
        responseAttributes.forageErrorCode = (error as? ForageError)?.errors.first?.code ?? UnknownErrorCode
        return self
    }

    /// Converts a dictionary with `MetricsAttributeName` enum keys to a dictionary with String keys.
    func mapEnumKeysToStrings(from metricsAttributes: [MetricsAttributeName: Encodable]) -> [String: Encodable] {
        var attributes: [String: Encodable] = [:]
        for (key, value) in metricsAttributes {
            attributes[key.rawValue] = value
        }
        return attributes
    }

    func logResult() {
        guard let startTime = startTime, let endTime = endTime else {
            metricsLogger?.error("Missing startTime or endTime. Could not report metric event.", error: nil, attributes: nil)
            return
        }
        responseAttributes.responseTimeMs = calculateDurationMs(from: startTime, to: endTime)

        // handled by subclass
        logWithResponseAttributes(
            metricsLogger: metricsLogger,
            responseAttributes: responseAttributes
        )
    }

    /// Calculates the time in milliseconds between the start and end time
    private func calculateDurationMs(from startTime: DispatchTime, to endTime: DispatchTime) -> Double {
        let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        return Double(nanoseconds) / 1_000_000
    }

    // Do nothing here; meant to be overridden by subclasses
    func logWithResponseAttributes(metricsLogger: ForageLogger?, responseAttributes: ResponseAttributes) {}
}
