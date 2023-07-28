//
//  File.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-07.
//

import Foundation

internal func calculateTimeDifferenceInMilliseconds(from startTime: DispatchTime, to endTime: DispatchTime) -> Double {
    let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let milliseconds = Double(nanoseconds) / 1_000_000
    return milliseconds
}

internal struct LatencyAttributes {
    let path: String
    let method: HttpMethod
    var httpStatusCode: Int?
    let roundTripMs: Double
    let action: VaultAction
}

internal func logVaultProxyResponseMetrics(vaultType: VaultType, latencyAttributes: LatencyAttributes) {
    let metricsLogger: ForageLogger? = DatadogLogger(
        ForageLoggerConfig(
            prefix: "Metrics"
        )
    )
    let vaultName = vaultType.rawValue
    metricsLogger?.setLogKind(ForageLogKind.metric).info("Received response from \(vaultName) proxy", attributes: [
        "vault_type": vaultName,
        "path": latencyAttributes.path,
        "method": latencyAttributes.method.rawValue,
        "http_status": latencyAttributes.httpStatusCode,
        "roundtrip_ms": latencyAttributes.roundTripMs,
        "action": latencyAttributes.action.rawValue
    ])
}
