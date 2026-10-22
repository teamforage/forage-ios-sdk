//
//  MomentTelemetry.swift
//  ForageSDK
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import Foundation

/// Logs how a moment went, so we can see how long moments take to load and how they end.
///
/// Each step has a readable log and a metric. The Android SDK sends the same `moment_ready` and
/// `moment_outcome` metrics with the same attributes, so one dashboard covers both.
///
/// Never logs the session token or the moment's params.
struct MomentTelemetry {
    /// Moment metric values. Must match the Android SDK.
    enum Metric {
        static let action = "create_moment"
        static let ready = "moment_ready"
        static let outcome = "moment_outcome"
        static let momentName = "moment_name"
        static let reachedReady = "moment_reached_ready"
        static let dismissed = "dismissed"
    }

    private let momentName: String
    private let logger: ForageLogger?
    private let now: () -> Date
    private let openedAt: Date
    private var readyAt: Date?

    /// Starts timing the moment.
    ///
    /// - Parameter now: The clock, so tests can control time.
    init(momentName: String, logger: ForageLogger? = ForageSDK.logger, now: @escaping () -> Date = Date.init) {
        self.momentName = momentName
        self.logger = logger
        self.now = now
        openedAt = now()
    }

    /// Logs that the page sent `input_ready`. Only the first call logs.
    mutating func ready() {
        guard readyAt == nil else { return }
        readyAt = now()
        let elapsed = milliseconds(since: openedAt)

        let logger = logger?.setPrefix("createMoment")
        logger?.notice("Moment \(momentName) is ready after \(Int(elapsed))ms", attributes: nil)
        logger?.info("Reported \(Metric.ready) event", attributes: metricAttributes(event: Metric.ready, elapsed: elapsed))
    }

    /// Logs how the moment ended. Failures are logged as errors, with their code and status.
    func settled(_ result: Result<MomentResult, Error>) {
        let elapsed = milliseconds(since: openedAt)
        var attributes = metricAttributes(event: Metric.outcome, elapsed: elapsed)
        attributes[Metric.reachedReady] = readyAt != nil
        let summary = "\(momentName) after \(Int(elapsed))ms (reached ready: \(readyAt != nil))"
        let logger = logger?.setPrefix("createMoment")

        switch result {
        case .success(.completed):
            attributes[MetricsAttributeName.eventOutcome.rawValue] = EventOutcome.success.rawValue
            logger?.notice("Moment completed: \(summary)", attributes: nil)
        case .success(.dismissed):
            attributes[MetricsAttributeName.eventOutcome.rawValue] = Metric.dismissed
            logger?.notice("Moment dismissed: \(summary)", attributes: nil)
        case let .failure(error):
            let forageError = error as? ForageError
            attributes[MetricsAttributeName.eventOutcome.rawValue] = EventOutcome.failure.rawValue
            // the load timeout is `timeout_error`, so it can be told apart from the page's failures
            attributes[MetricsAttributeName.forageErrorCode.rawValue] = forageError?.code ?? UnknownErrorCode
            if let httpStatusCode = forageError?.httpStatusCode {
                attributes[MetricsAttributeName.httpStatus.rawValue] = httpStatusCode
            }
            logger?.error("Moment failed: \(summary)", error: error, attributes: nil)
        }

        logger?.info("Reported \(Metric.outcome) event", attributes: attributes)
    }

    private func metricAttributes(event: String, elapsed: Double) -> [String: Encodable] {
        [
            MetricsAttributeName.logType.rawValue: ForageLogKind.metric.rawValue,
            MetricsAttributeName.action.rawValue: Metric.action,
            MetricsAttributeName.eventName.rawValue: event,
            MetricsAttributeName.responseTimeMs.rawValue: elapsed,
            Metric.momentName: momentName,
        ]
    }

    private func milliseconds(since start: Date) -> Double {
        (now().timeIntervalSince(start) * 1000).rounded()
    }
}
