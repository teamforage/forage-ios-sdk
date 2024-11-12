//
//  VaultProxyResponseMonitor.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-07.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

enum EventName: String {
    /// vaultResponse refers to a response from the Vault Proxy submit actions.
    case vaultResponse = "vault_response"
    /**
     customer_perceived_response refers to the response from a balance or capture action. There are
     multiple chained requests that come from the client when executing a balance or capture action.
     Example of a balance action:
     [GET] EncryptionKey -> [GET] PaymentMethod -> [POST] to Rosetta  -> Return Balance
     */
    case customerPerceivedResponse = "customer_perceived_response"
}

/*
 `VaultProxyResponseMonitor` is a specialized `ResponseMonitor` for handling Vault-related network metrics. VaultProxyResponseMonitor is used to track the errors and response times from the Rosetta submit functions. The timer begins when a balance or capture request is submitted to Rosetta and ends when a response is received by the SDK.
 */
final class VaultProxyResponseMonitor: ResponseMonitor {
    private let vaultAction: VaultAction
    private var eventName: EventName = .vaultResponse

    private init(vaultAction: VaultAction) {
        self.vaultAction = vaultAction
    }

    /// Factory method for creating new VaultProxyResponseMonitor instances
    static func newMeasurement(action: VaultAction) -> VaultProxyResponseMonitor {
        VaultProxyResponseMonitor(vaultAction: action)
    }

    override func logWithResponseAttributes(metricsLogger: ForageLogger?, responseAttributes: ResponseAttributes) {
        guard let httpMethod = responseAttributes.method?.rawValue,
              let path = responseAttributes.path,
              let httpStatus = responseAttributes.code,
              let responseTimeMs = responseAttributes.responseTimeMs else {
            metricsLogger?.error("Incomplete or missing response attributes. Could not report metric event.", error: nil, attributes: nil)
            return
        }

        metricsLogger?.info(
            "Received response from Rosetta proxy",
            attributes: mapEnumKeysToStrings(from: [
                .action: vaultAction.rawValue,
                .eventName: eventName.rawValue,
                .httpStatus: httpStatus,
                .logType: ForageLogKind.metric.rawValue,
                .method: httpMethod,
                .path: path,
                .responseTimeMs: responseTimeMs,
                .vaultType: "forage",
            ])
        )
    }
}
