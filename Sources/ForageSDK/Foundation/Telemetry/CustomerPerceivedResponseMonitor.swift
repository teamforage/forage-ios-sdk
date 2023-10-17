//
//  CustomerPerceivedResponseMonitor.swift
//  
//
//  Created by Danilo Joksimovic on 2023-10-12.
//

import Foundation

internal let UnknownErrorCode = "unknown"

/*
 CustomerPerceivedResponseMonitor is used to track the response time that a customer
 experiences while executing a balance or capture action. There are multiple chained requests
 that come from the client when executing a balance or capture action.
 
 The timer begins when the first HTTP request is sent from the SDK and ends when the the SDK returns information back to the user. Ex of a balance action:
 
 Timer Begins -> [GET] EncryptionKey -> [GET] PaymentMethod -> [POST] to VGS/BT ->
 [GET] Poll for Response -> [GET] PaymentMethod -> Timer Ends -> Return Balance
 */
internal final class CustomerPerceivedResponseMonitor: ResponseMonitor {
    
    private var vaultType: VaultType
    private var vaultAction: VaultAction
    private var eventOutcome: EventOutcome?
    private var eventName: EventName = .customerPerceivedResponse
    
    internal init(vaultType: VaultType, vaultAction: VaultAction) {
        self.vaultType = vaultType
        self.vaultAction = vaultAction
        super.init()
    }
    
    /// Factory method for creating new CustomerPerceivedResponseMonitor instances
    internal static func newMeasurement(vaultType: VaultType, vaultAction: VaultAction) -> CustomerPerceivedResponseMonitor {
        return CustomerPerceivedResponseMonitor(vaultType: vaultType, vaultAction: vaultAction)
    }
    
    // override to set event_outcome to "failure" if we know the event has a forage_error_code
    @discardableResult
    internal override func setForageErrorCode(_ error: Error) -> CustomerPerceivedResponseMonitor {
        self.setEventOutcome(.failure)
        super.setForageErrorCode(error)
        return self
    }
    
    @discardableResult
    internal func setEventOutcome(_ outcome: EventOutcome) -> CustomerPerceivedResponseMonitor {
        self.eventOutcome = outcome
        return self
    }
    
    internal override func logWithResponseAttributes(
        metricsLogger: ForageLogger?,
        responseAttributes: ResponseAttributes
    ) {
        
        guard
            let responseTimeMs = responseAttributes.responseTimeMs,
            let eventOutcome = self.eventOutcome
        else {
            metricsLogger?.error("Incomplete or missing response attributes. Could not report metric event.", error: nil, attributes: nil)
            return
        }
        
        if (eventOutcome == .failure && responseAttributes.forageErrorCode == nil) {
            metricsLogger?.error("Failure event did not include forage_error_code.", error: nil, attributes: nil)
        }
        
        metricsLogger?.info(
            "Reported customer-perceived response event",
            attributes: mapEnumKeysToStrings(from: [
                .action: self.vaultAction.rawValue,
                .eventName: self.eventName.rawValue,
                .eventOutcome: eventOutcome.rawValue,
                .forageErrorCode: responseAttributes.forageErrorCode,
                .logType: ForageLogKind.metric.rawValue,
                .responseTimeMs: responseTimeMs,
                .vaultType: self.vaultType.rawValue,
            ])
        )
    }
}
