//
//  VaultProxyResponseMonitor.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-07.
//

import Foundation

internal struct ResponseAttributes {
    var responseTimeMs: Double?
    var path: String?
    var method: HttpMethod?
    var code: Int?
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

/// `VaultProxyResponseMonitor` is a specialized `ResponseMonitor` for handling Vault-related network metrics
internal final class VaultProxyResponseMonitor: ResponseMonitor {
    
    private let vaultAction: VaultAction
    private let vaultType: VaultType
    
    private init(vaultType: VaultType, vaultAction: VaultAction) {
        self.vaultType = vaultType
        self.vaultAction = vaultAction
    }
    
    /// Factory method for creating new VaultProxyResponseMonitor instances
    internal static func newMeasurement(vault: VaultType, action: VaultAction) -> VaultProxyResponseMonitor {
        return VaultProxyResponseMonitor(vaultType: vault, vaultAction: action)
    }
    
    internal override func logWithResponseAttributes(metricsLogger: ForageLogger?, responseAttributes: ResponseAttributes) {
        guard let httpMethod = responseAttributes.method?.rawValue,
              let path = responseAttributes.path,
              let httpStatus = responseAttributes.code,
              let responseTimeMs = responseAttributes.responseTimeMs else {
            metricsLogger?.error("Incomplete or missing response attributes. Could not log metric.", error: nil, attributes: nil)
            return
        }
        
        let vaultName = self.vaultType.rawValue
        let vaultAction = self.vaultAction.rawValue
        
        metricsLogger?.info("Received response from \(vaultName) proxy", attributes: [
            "vault_type": vaultName,
            "action": vaultAction,
            "path": path,
            "method": httpMethod,
            "http_status": httpStatus,
            "response_time_ms": responseTimeMs,
        ])
    }
}
